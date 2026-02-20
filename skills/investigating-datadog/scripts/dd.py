#!/usr/bin/env python3
"""Datadog query utility for investigating issues."""

import argparse
import json
import os
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone

from datadog_api_client import ApiClient, Configuration
from datadog_api_client.v1.api.hosts_api import HostsApi
from datadog_api_client.v1.api.events_api import EventsApi
from datadog_api_client.v1.api.monitors_api import MonitorsApi
from datadog_api_client.v1.api.metrics_api import MetricsApi
from datadog_api_client.v2.api.logs_api import LogsApi
from datadog_api_client.v2.api.spans_api import SpansApi
from datadog_api_client.v2.model.logs_list_request import LogsListRequest
from datadog_api_client.v2.model.logs_list_request_page import LogsListRequestPage
from datadog_api_client.v2.model.logs_query_filter import LogsQueryFilter
from datadog_api_client.v2.model.logs_sort import LogsSort
from datadog_api_client.v2.model.spans_list_request import SpansListRequest
from datadog_api_client.v2.model.spans_list_request_data import SpansListRequestData
from datadog_api_client.v2.model.spans_list_request_attributes import SpansListRequestAttributes
from datadog_api_client.v2.model.spans_list_request_page import SpansListRequestPage
from datadog_api_client.v2.model.spans_query_filter import SpansQueryFilter
from datadog_api_client.v2.model.spans_sort import SpansSort


# ─────────────────────────────────────────────────────────────────────────────
# Formatting utilities
# ─────────────────────────────────────────────────────────────────────────────

def format_table(headers: list, rows: list, max_width: int = 50) -> str:
    """Format data as an ASCII table."""
    if not rows:
        return "(no data)"

    # Truncate cell values
    def truncate(val, width):
        s = str(val) if val is not None else ""
        return s[:width-2] + ".." if len(s) > width else s

    # Calculate column widths
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], min(len(str(cell) if cell else ""), max_width))

    # Build table
    lines = []
    header_line = " │ ".join(h.ljust(widths[i]) for i, h in enumerate(headers))
    separator = "─┼─".join("─" * w for w in widths)
    lines.append(header_line)
    lines.append(separator)

    for row in rows:
        cells = [truncate(cell, widths[i]).ljust(widths[i]) for i, cell in enumerate(row)]
        lines.append(" │ ".join(cells))

    return "\n".join(lines)


def format_histogram(data: dict, width: int = 40, title: str = "") -> str:
    """Format data as an ASCII histogram."""
    if not data:
        return "(no data)"

    max_val = max(data.values())
    lines = []
    if title:
        lines.append(title)
        lines.append("─" * (width + 20))

    for label, value in data.items():
        bar_len = int((value / max_val) * width) if max_val > 0 else 0
        bar = "█" * bar_len
        lines.append(f"{str(label):>12} │ {bar} {value}")

    return "\n".join(lines)


def format_sparkline(values: list, width: int = 20) -> str:
    """Format values as a sparkline."""
    if not values:
        return ""
    chars = " ▁▂▃▄▅▆▇█"
    min_val, max_val = min(values), max(values)
    if max_val == min_val:
        return chars[4] * min(len(values), width)

    result = []
    for v in values[:width]:
        idx = int((v - min_val) / (max_val - min_val) * (len(chars) - 1))
        result.append(chars[idx])
    return "".join(result)


def format_duration(seconds: float) -> str:
    """Format duration in human readable form."""
    if seconds < 60:
        return f"{seconds:.0f}s"
    if seconds < 3600:
        return f"{seconds/60:.0f}m"
    if seconds < 86400:
        return f"{seconds/3600:.1f}h"
    return f"{seconds/86400:.1f}d"


# ─────────────────────────────────────────────────────────────────────────────
# Core utilities
# ─────────────────────────────────────────────────────────────────────────────

def get_config():
    """Get Datadog API configuration from environment variables."""
    api_key = os.environ.get("DD_API_KEY")
    app_key = os.environ.get("DD_APP_KEY")
    site = os.environ.get("DD_SITE", "datadoghq.com")

    if not api_key:
        print("Error: DD_API_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)
    if not app_key:
        print("Error: DD_APP_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)

    config = Configuration()
    config.api_key["apiKeyAuth"] = api_key
    config.api_key["appKeyAuth"] = app_key
    config.server_variables["site"] = site
    return config


def parse_time(time_str, default_hours_ago=1) -> datetime:
    """Parse time string to datetime. Supports relative (1h, 30m) or ISO format."""
    if time_str is None:
        return datetime.now(timezone.utc) - timedelta(hours=default_hours_ago)

    time_str = time_str.strip()

    # Relative time: 1h, 30m, 2d
    if time_str.endswith("h"):
        hours = int(time_str[:-1])
        return datetime.now(timezone.utc) - timedelta(hours=hours)
    if time_str.endswith("m"):
        minutes = int(time_str[:-1])
        return datetime.now(timezone.utc) - timedelta(minutes=minutes)
    if time_str.endswith("d"):
        days = int(time_str[:-1])
        return datetime.now(timezone.utc) - timedelta(days=days)

    # ISO format
    try:
        dt = datetime.fromisoformat(time_str.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except ValueError:
        print(f"Error: Invalid time format '{time_str}'. Use relative (1h, 30m, 2d) or ISO format.", file=sys.stderr)
        sys.exit(1)


def to_json(obj):
    """Convert API response to JSON string."""
    if hasattr(obj, "to_dict"):
        return json.dumps(obj.to_dict(), indent=2, default=str)
    return json.dumps(obj, indent=2, default=str)


def parse_timestamp(ts) -> datetime:
    """Parse timestamp from API response - handles both datetime objects and strings."""
    if isinstance(ts, datetime):
        return ts
    if isinstance(ts, str):
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    raise ValueError(f"Cannot parse timestamp: {ts}")


# ─────────────────────────────────────────────────────────────────────────────
# Log search with pagination
# ─────────────────────────────────────────────────────────────────────────────

def fetch_logs_page(api, query: str, from_dt: datetime, to_dt: datetime,
                    limit: int = 1000, cursor: str = None, sort_asc: bool = False):
    """Fetch a single page of logs."""
    page_kwargs = {"limit": min(limit, 1000)}
    if cursor:
        page_kwargs["cursor"] = cursor

    body = LogsListRequest(
        filter=LogsQueryFilter(
            query=query,
            _from=from_dt.isoformat(),
            to=to_dt.isoformat(),
        ),
        sort=LogsSort.TIMESTAMP_ASCENDING if sort_asc else LogsSort.TIMESTAMP_DESCENDING,
        page=LogsListRequestPage(**page_kwargs),
    )
    return api.list_logs(body=body)


def fetch_all_logs(api, query: str, from_dt: datetime, to_dt: datetime, max_logs: int = 10000):
    """Fetch logs with pagination up to max_logs."""
    all_logs = []
    cursor = None

    while len(all_logs) < max_logs:
        response = fetch_logs_page(api, query, from_dt, to_dt,
                                   limit=min(1000, max_logs - len(all_logs)),
                                   cursor=cursor)
        logs = response.data or []
        all_logs.extend(logs)

        if not logs or len(logs) < 1000:
            break

        # Get next cursor
        if response.meta and response.meta.page and response.meta.page.after:
            cursor = response.meta.page.after
        else:
            break

    return all_logs


def find_first_occurrence(api, query: str, from_dt: datetime, to_dt: datetime) -> datetime | None:
    """Find first occurrence of a log pattern in the given range."""
    response = fetch_logs_page(api, query, from_dt, to_dt, limit=1, sort_asc=True)
    if not response.data:
        return None
    return parse_timestamp(response.data[0].attributes.timestamp)


def find_last_occurrence(api, query: str, from_dt: datetime, to_dt: datetime) -> datetime | None:
    """Find last occurrence of a log pattern."""
    response = fetch_logs_page(api, query, from_dt, to_dt, limit=1, sort_asc=False)
    if not response.data:
        return None
    return parse_timestamp(response.data[0].attributes.timestamp)


def count_logs_by_period(api, query: str, from_dt: datetime, to_dt: datetime,
                         periods: int = 10) -> dict:
    """Count logs in time periods for histogram."""
    duration = (to_dt - from_dt).total_seconds()
    period_seconds = duration / periods

    counts = {}
    for i in range(periods):
        period_start = from_dt + timedelta(seconds=i * period_seconds)
        period_end = from_dt + timedelta(seconds=(i + 1) * period_seconds)

        response = fetch_logs_page(api, query, period_start, period_end, limit=1)
        # We can't get exact count without pagination, so we estimate
        # For now, just mark if there are logs in this period
        if response.data:
            # Fetch up to 1000 to get a count
            response = fetch_logs_page(api, query, period_start, period_end, limit=1000)
            counts[period_start.strftime("%H:%M")] = len(response.data or [])
        else:
            counts[period_start.strftime("%H:%M")] = 0

    return counts


# ─────────────────────────────────────────────────────────────────────────────
# Commands
# ─────────────────────────────────────────────────────────────────────────────

def cmd_logs(args):
    """Search logs."""
    config = get_config()
    from_dt = parse_time(args.from_time, default_hours_ago=1)
    to_dt = parse_time(args.to_time, default_hours_ago=0) if args.to_time else datetime.now(timezone.utc)

    with ApiClient(config) as client:
        api = LogsApi(client)

        if args.json:
            response = fetch_logs_page(api, args.query, from_dt, to_dt, limit=args.limit)
            print(to_json(response))
            return

        logs = fetch_all_logs(api, args.query, from_dt, to_dt, max_logs=args.limit)

        if not logs:
            print("No logs found.")
            return

        # Build table
        rows = []
        for log in logs[:100]:  # Show first 100 in table
            attrs = log.attributes
            ts = attrs.timestamp
            if isinstance(ts, str):
                ts = ts[11:19]  # Extract time portion
            msg = attrs.message or ""
            msg = msg[:80] + ".." if len(msg) > 80 else msg
            rows.append([ts, attrs.status or "", attrs.service or "", msg])

        print(f"Found {len(logs)} logs (showing first {len(rows)})\n")
        print(format_table(["Time", "Status", "Service", "Message"], rows))


def cmd_metrics(args):
    """Query metrics."""
    config = get_config()
    from_dt = parse_time(args.from_time, default_hours_ago=1)
    to_dt = parse_time(args.to_time, default_hours_ago=0) if args.to_time else datetime.now(timezone.utc)

    with ApiClient(config) as client:
        api = MetricsApi(client)
        response = api.query_metrics(
            _from=int(from_dt.timestamp()),
            to=int(to_dt.timestamp()),
            query=args.query,
        )

        if args.json:
            print(to_json(response))
            return

        if not response.series:
            print("No metrics data found.")
            return

        for series in response.series:
            name = series.display_name or series.metric
            points = series.pointlist or []

            if not points:
                print(f"{name}: no data")
                continue

            values = [p[1] for p in points if p[1] is not None]
            if not values:
                print(f"{name}: no values")
                continue

            avg = sum(values) / len(values)
            min_val, max_val = min(values), max(values)
            sparkline = format_sparkline(values)

            print(f"{name}")
            print(f"  {sparkline}  min={min_val:.2f} avg={avg:.2f} max={max_val:.2f}")
            print()


def cmd_monitors(args):
    """List monitors."""
    config = get_config()

    with ApiClient(config) as client:
        api = MonitorsApi(client)

        kwargs = {}
        if args.tag:
            kwargs["monitor_tags"] = args.tag

        monitors = api.list_monitors(**kwargs)

        # Filter by status if specified
        if args.status:
            status_lower = args.status.lower()
            monitors = [m for m in monitors if m.overall_state and m.overall_state.value.lower() == status_lower]

        if args.json:
            output = []
            for m in monitors:
                output.append({
                    "id": m.id,
                    "name": m.name,
                    "type": m.type.value if m.type else None,
                    "status": m.overall_state.value if m.overall_state else None,
                    "query": m.query,
                })
            print(json.dumps(output, indent=2))
            return

        if not monitors:
            print("No monitors found.")
            return

        # Status emoji
        status_icons = {"Alert": "🔴", "Warn": "🟡", "OK": "🟢", "No Data": "⚪"}

        rows = []
        for m in monitors:
            status = m.overall_state.value if m.overall_state else "Unknown"
            icon = status_icons.get(status, "❓")
            name = m.name[:50] + ".." if len(m.name) > 50 else m.name
            rows.append([icon, status, str(m.id), name])

        print(f"Found {len(monitors)} monitors\n")
        print(format_table(["", "Status", "ID", "Name"], rows))


def cmd_hosts(args):
    """List hosts."""
    config = get_config()

    with ApiClient(config) as client:
        api = HostsApi(client)

        kwargs = {}
        if args.filter:
            kwargs["filter"] = args.filter

        response = api.list_hosts(**kwargs)

        if args.json:
            output = {
                "total_matching": response.total_matching,
                "total_returned": response.total_returned,
                "hosts": []
            }
            if response.host_list:
                for h in response.host_list:
                    output["hosts"].append({
                        "name": h.name,
                        "id": h.id,
                        "apps": h.apps if h.apps else [],
                    })
            print(json.dumps(output, indent=2))
            return

        if not response.host_list:
            print("No hosts found.")
            return

        rows = []
        for h in response.host_list:
            apps = ", ".join(h.apps[:3]) if h.apps else ""
            if h.apps and len(h.apps) > 3:
                apps += f" +{len(h.apps)-3}"
            platform = h.meta.platform if h.meta else ""
            rows.append([h.name, platform, apps])

        print(f"Found {response.total_matching} hosts (showing {len(rows)})\n")
        print(format_table(["Name", "Platform", "Apps"], rows))


def cmd_events(args):
    """List events."""
    config = get_config()
    from_dt = parse_time(args.from_time, default_hours_ago=24)
    to_dt = parse_time(args.to_time, default_hours_ago=0) if args.to_time else datetime.now(timezone.utc)

    with ApiClient(config) as client:
        api = EventsApi(client)
        response = api.list_events(
            start=int(from_dt.timestamp()),
            end=int(to_dt.timestamp()),
        )

        if args.json:
            output = []
            if response.events:
                for e in response.events:
                    output.append({
                        "id": e.id,
                        "title": e.title,
                        "date_happened": datetime.fromtimestamp(e.date_happened).isoformat() if e.date_happened else None,
                        "alert_type": e.alert_type.value if e.alert_type else None,
                        "source": e.source,
                    })
            print(json.dumps(output, indent=2))
            return

        if not response.events:
            print("No events found.")
            return

        alert_icons = {"error": "🔴", "warning": "🟡", "info": "🔵", "success": "🟢"}

        rows = []
        for e in response.events:
            ts = datetime.fromtimestamp(e.date_happened).strftime("%m-%d %H:%M") if e.date_happened else ""
            alert = e.alert_type.value if e.alert_type else ""
            icon = alert_icons.get(alert, "")
            title = e.title[:60] + ".." if e.title and len(e.title) > 60 else (e.title or "")
            rows.append([ts, icon, e.source or "", title])

        print(f"Found {len(response.events)} events\n")
        print(format_table(["Time", "", "Source", "Title"], rows))


def cmd_traces(args):
    """Search APM traces/spans."""
    config = get_config()
    from_dt = parse_time(args.from_time, default_hours_ago=1)
    to_dt = parse_time(args.to_time, default_hours_ago=0) if args.to_time else datetime.now(timezone.utc)

    with ApiClient(config) as client:
        api = SpansApi(client)

        body = SpansListRequest(
            data=SpansListRequestData(
                attributes=SpansListRequestAttributes(
                    filter=SpansQueryFilter(
                        query=args.query,
                        _from=from_dt.isoformat(),
                        to=to_dt.isoformat(),
                    ),
                    sort=SpansSort.TIMESTAMP_DESCENDING,
                    page=SpansListRequestPage(limit=args.limit),
                ),
                type="search_request",
            ),
        )

        response = api.list_spans(body=body)

        if args.json:
            print(to_json(response))
            return

        spans = response.data or []
        if not spans:
            print("No traces found.")
            return

        rows = []
        for span in spans[:50]:
            attrs = span.attributes.attributes
            ts = span.attributes.timestamp
            if isinstance(ts, str):
                ts = ts[11:19]
            service = attrs.get("service", "") if attrs else ""
            resource = attrs.get("resource_name", "") if attrs else ""
            resource = resource[:40] + ".." if len(resource) > 40 else resource
            duration = attrs.get("duration", 0) if attrs else 0
            duration_str = f"{duration/1e6:.0f}ms" if duration else ""
            rows.append([ts, service, resource, duration_str])

        print(f"Found {len(spans)} spans (showing first {len(rows)})\n")
        print(format_table(["Time", "Service", "Resource", "Duration"], rows))


def cmd_monitor(args):
    """Get single monitor details."""
    config = get_config()

    with ApiClient(config) as client:
        api = MonitorsApi(client)
        response = api.get_monitor(monitor_id=args.id)

        if args.json:
            print(to_json(response))
            return

        status_icons = {"Alert": "🔴", "Warn": "🟡", "OK": "🟢", "No Data": "⚪"}
        status = response.overall_state.value if response.overall_state else "Unknown"
        icon = status_icons.get(status, "❓")

        print(f"{icon} {response.name}")
        print(f"   ID: {response.id}")
        print(f"   Type: {response.type.value if response.type else 'Unknown'}")
        print(f"   Status: {status}")
        print(f"   Query: {response.query}")
        if response.message:
            msg = response.message[:200] + "..." if len(response.message) > 200 else response.message
            print(f"   Message: {msg}")


def cmd_investigate(args):
    """Comprehensive investigation of a log pattern."""
    config = get_config()
    from_dt = parse_time(args.from_time, default_hours_ago=24)
    to_dt = parse_time(args.to_time, default_hours_ago=0) if args.to_time else datetime.now(timezone.utc)

    print(f"🔍 Investigating: {args.query}")
    print(f"   Time range: {from_dt.strftime('%Y-%m-%d %H:%M')} to {to_dt.strftime('%Y-%m-%d %H:%M')} UTC")
    print()

    with ApiClient(config) as client:
        api = LogsApi(client)

        # Find first and last occurrence
        print("📅 Finding first/last occurrence...")
        first_ts = find_first_occurrence(api, args.query, from_dt, to_dt)
        last_ts = find_last_occurrence(api, args.query, from_dt, to_dt)

        if not first_ts:
            print("   ✅ No occurrences found in this time range.")
            return

        # Auto-expand: if first occurrence is within 1 hour of search start, search further back
        search_start = from_dt
        expanded = False
        while (first_ts - search_start).total_seconds() < 3600:
            expanded_start = search_start - timedelta(hours=24)
            earlier = find_first_occurrence(api, args.query, expanded_start, search_start)
            if earlier:
                first_ts = earlier
                search_start = expanded_start
                expanded = True
            else:
                break
            # Safety limit: don't search more than 7 days beyond original from_dt
            if (from_dt - expanded_start).days >= 7:
                break

        if expanded:
            print(f"   ⏪ Auto-expanded search to find true start")

        print(f"   First: {first_ts.strftime('%Y-%m-%d %H:%M:%S')} UTC")
        print(f"   Last:  {last_ts.strftime('%Y-%m-%d %H:%M:%S')} UTC")

        duration = (last_ts - first_ts).total_seconds()
        if duration > 0:
            print(f"   Duration: {format_duration(duration)}")

        still_happening = (datetime.now(timezone.utc) - last_ts).total_seconds() < 300
        if still_happening:
            print("   ⚠️  ACTIVE - occurred in last 5 minutes")
        else:
            print(f"   Last occurrence was {format_duration((datetime.now(timezone.utc) - last_ts).total_seconds())} ago")
        print()

        # Count occurrences
        print("📊 Counting occurrences...")
        all_logs = fetch_all_logs(api, args.query, first_ts, to_dt, max_logs=10000)
        total_count = len(all_logs)
        print(f"   Total: {total_count:,} occurrences")

        if total_count > 0 and duration > 0:
            rate = total_count / (duration / 60)
            print(f"   Rate: ~{rate:.1f}/minute")
        print()

        # Distribution by hour
        if total_count > 0:
            print("📈 Distribution over time:")
            hour_counts = Counter()
            for log in all_logs:
                ts = log.attributes.timestamp
                if isinstance(ts, str):
                    ts = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                hour_counts[ts.strftime("%m-%d %H:00")] = hour_counts.get(ts.strftime("%m-%d %H:00"), 0) + 1

            # Show as histogram (last 10 periods)
            sorted_hours = sorted(hour_counts.items())[-10:]
            hist_data = {k: v for k, v in sorted_hours}
            print(format_histogram(hist_data))
            print()

        # Group by source
        if total_count > 0:
            print("🏷️  Top sources:")
            source_counts = Counter()
            for log in all_logs:
                tags = log.attributes.tags or []
                # Look for pod_name or host tag
                for tag in tags:
                    if tag.startswith("pod_name:"):
                        source_counts[tag.split(":")[1]] += 1
                        break
                    if tag.startswith("host:"):
                        source_counts[tag.split(":")[1]] += 1
                        break

            for source, count in source_counts.most_common(10):
                pct = (count / total_count) * 100
                print(f"   {source}: {count:,} ({pct:.0f}%)")
            print()

        # Sample messages
        print("📝 Sample messages (latest 3):")
        for log in all_logs[:3]:
            msg = log.attributes.message or "(no message)"
            msg = msg[:100] + "..." if len(msg) > 100 else msg
            print(f"   • {msg}")


def cmd_timeline(args):
    """Generate hourly timeline chart for a log pattern."""
    config = get_config()
    from_dt = parse_time(args.from_time, default_hours_ago=48)
    to_dt = parse_time(args.to_time, default_hours_ago=0) if args.to_time else datetime.now(timezone.utc)

    with ApiClient(config) as client:
        api = LogsApi(client)

        # Find first and last occurrence
        first_ts = find_first_occurrence(api, args.query, from_dt, to_dt)
        if not first_ts:
            print("No occurrences found in this time range.")
            return

        last_ts = find_last_occurrence(api, args.query, from_dt, to_dt)

        # Auto-expand: if first occurrence is within 1 hour of search start, search further back
        search_start = from_dt
        while (first_ts - search_start).total_seconds() < 3600:
            expanded_start = search_start - timedelta(hours=24)
            earlier = find_first_occurrence(api, args.query, expanded_start, search_start)
            if earlier:
                first_ts = earlier
                search_start = expanded_start
            else:
                break
            # Safety limit: don't search more than 7 days back
            if (from_dt - expanded_start).days >= 7:
                break

        # Fetch all logs with pagination
        all_logs = []
        cursor = None
        while True:
            page_args = {"limit": 1000}
            if cursor:
                page_args["cursor"] = cursor
            response = fetch_logs_page(api, args.query, first_ts,
                                       last_ts + timedelta(minutes=1),
                                       limit=1000, cursor=cursor, sort_asc=True)
            logs = response.data or []
            all_logs.extend(logs)
            if len(logs) < 1000:
                break
            if response.meta and response.meta.page and response.meta.page.after:
                cursor = response.meta.page.after
            else:
                break

        # Bucket by hour
        from collections import defaultdict
        hourly = defaultdict(int)
        for log in all_logs:
            ts = parse_timestamp(log.attributes.timestamp)
            hourly[ts.strftime("%m-%d %H:00")] += 1

        sorted_hours = sorted(hourly.items())
        max_count = max(hourly.values()) if hourly else 1

        # Determine title from query or use generic
        title = args.title if args.title else args.query[:40]

        # Print header
        fmt = "%Y-%m-%d %H:%M:%S"
        now = datetime.now(timezone.utc)
        resolved = (now - last_ts).total_seconds() > 300

        print()
        print("╔" + "═" * 68 + "╗")
        print(f"║  {title:^64}  ║")
        print("╠" + "═" * 68 + "╣")
        print(f"║  Start: {first_ts.strftime(fmt)} UTC{' ' * 33}║")
        print(f"║  End:   {last_ts.strftime(fmt)} UTC{' ' * 33}║")
        print(f"║  Total: {len(all_logs):,} occurrences{' ' * (42 - len(f'{len(all_logs):,}'))}║")
        print(f"║  Status: {'✅ RESOLVED' if resolved else '🔴 ACTIVE'}{' ' * (46 if resolved else 48)}║")
        print("╚" + "═" * 68 + "╝")
        print()

        # Print chart
        for hour, count in sorted_hours:
            bar_len = int((count / max_count) * 40) if max_count > 0 else 0
            bar = "█" * bar_len
            if count > 300:
                ind = "🔴"
            elif count > 150:
                ind = "🟠"
            elif count > 50:
                ind = "🟡"
            else:
                ind = "🟢"
            print(f"  {hour}  {ind} {count:>4} │{bar}")

        # Show current hour if resolved and not in data
        cur_hour = now.strftime("%m-%d %H:00")
        if resolved and cur_hour not in hourly:
            print(f"  {cur_hour}  ✅    0 │ (resolved)")

        # Summary stats
        print()
        dur = (last_ts - first_ts).total_seconds() / 3600
        if dur > 0:
            avg_rate = len(all_logs) / dur
            if resolved:
                fixed_ago = (now - last_ts).total_seconds() / 60
                print(f"📊 Duration: {dur:.1f}h | Avg: {avg_rate:.0f}/hr | Peak: {max_count}/hr | Fixed: {fixed_ago:.0f}m ago")
            else:
                print(f"📊 Duration: {dur:.1f}h | Avg: {avg_rate:.0f}/hr | Peak: {max_count}/hr | Status: ONGOING")
        else:
            print(f"📊 Total: {len(all_logs)} occurrences")


def main():
    parser = argparse.ArgumentParser(
        description="Datadog query utility for investigating issues",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  dd.py logs "service:web status:error"
  dd.py logs "host:prod-*" --from 2h --limit 50
  dd.py metrics "avg:system.cpu.user{*}"
  dd.py monitors --status alert
  dd.py investigate "error message" --from 7d
  dd.py timeline "error" --title "Error Timeline"
  dd.py hosts --filter "aws"
  dd.py events --from 24h
  dd.py traces "service:api @http.status_code:500"
        """,
    )
    parser.add_argument("--json", action="store_true", help="Output raw JSON")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # logs
    p_logs = subparsers.add_parser("logs", help="Search logs")
    p_logs.add_argument("query", help="Log search query")
    p_logs.add_argument("-f", "--from", dest="from_time", help="Start time (e.g., 1h, 30m, 2d, or ISO)")
    p_logs.add_argument("-t", "--to", dest="to_time", help="End time (default: now)")
    p_logs.add_argument("-n", "--limit", type=int, default=1000, help="Max results (default: 1000)")
    p_logs.add_argument("--json", action="store_true", help="Output raw JSON")
    p_logs.set_defaults(func=cmd_logs)

    # investigate
    p_investigate = subparsers.add_parser("investigate", help="Comprehensive investigation of a log pattern")
    p_investigate.add_argument("query", help="Log search query")
    p_investigate.add_argument("-f", "--from", dest="from_time", help="Start time (default: 24h)")
    p_investigate.add_argument("-t", "--to", dest="to_time", help="End time (default: now)")
    p_investigate.set_defaults(func=cmd_investigate)

    # timeline
    p_timeline = subparsers.add_parser("timeline", help="Generate hourly timeline chart")
    p_timeline.add_argument("query", help="Log search query")
    p_timeline.add_argument("-f", "--from", dest="from_time", help="Start time (default: 48h)")
    p_timeline.add_argument("-t", "--to", dest="to_time", help="End time (default: now)")
    p_timeline.add_argument("--title", help="Custom title for the chart")
    p_timeline.set_defaults(func=cmd_timeline)

    # metrics
    p_metrics = subparsers.add_parser("metrics", help="Query metrics")
    p_metrics.add_argument("query", help="Metrics query (e.g., avg:system.cpu.user{*})")
    p_metrics.add_argument("-f", "--from", dest="from_time", help="Start time")
    p_metrics.add_argument("-t", "--to", dest="to_time", help="End time")
    p_metrics.add_argument("--json", action="store_true", help="Output raw JSON")
    p_metrics.set_defaults(func=cmd_metrics)

    # monitors
    p_monitors = subparsers.add_parser("monitors", help="List monitors")
    p_monitors.add_argument("--tag", help="Filter by tag")
    p_monitors.add_argument("--status", help="Filter by status (alert, warn, ok, no data)")
    p_monitors.add_argument("--json", action="store_true", help="Output raw JSON")
    p_monitors.set_defaults(func=cmd_monitors)

    # monitor (single)
    p_monitor = subparsers.add_parser("monitor", help="Get monitor details")
    p_monitor.add_argument("id", type=int, help="Monitor ID")
    p_monitor.add_argument("--json", action="store_true", help="Output raw JSON")
    p_monitor.set_defaults(func=cmd_monitor)

    # hosts
    p_hosts = subparsers.add_parser("hosts", help="List hosts")
    p_hosts.add_argument("--filter", help="Filter string")
    p_hosts.add_argument("--json", action="store_true", help="Output raw JSON")
    p_hosts.set_defaults(func=cmd_hosts)

    # events
    p_events = subparsers.add_parser("events", help="List events")
    p_events.add_argument("-f", "--from", dest="from_time", help="Start time (default: 24h)")
    p_events.add_argument("-t", "--to", dest="to_time", help="End time")
    p_events.add_argument("--json", action="store_true", help="Output raw JSON")
    p_events.set_defaults(func=cmd_events)

    # traces
    p_traces = subparsers.add_parser("traces", help="Search APM traces/spans")
    p_traces.add_argument("query", help="Span search query")
    p_traces.add_argument("-f", "--from", dest="from_time", help="Start time")
    p_traces.add_argument("-t", "--to", dest="to_time", help="End time")
    p_traces.add_argument("-n", "--limit", type=int, default=100, help="Max results")
    p_traces.add_argument("--json", action="store_true", help="Output raw JSON")
    p_traces.set_defaults(func=cmd_traces)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
