#!/usr/bin/env bash
set -euo pipefail

# Mermaid diagram preview script
# Usage:
#   preview.sh local <file.mmd|file.md> [--dark]
#   preview.sh gist <file.mmd|file.md>
#   preview.sh list
#   preview.sh cleanup

TRACKING_FILE="${HOME}/.cache/mermaid-preview-gists.txt"
PREVIEW_DIR="${HOME}/.cache/mermaid-preview"

mkdir -p "$(dirname "$TRACKING_FILE")" "$PREVIEW_DIR"

# Extract mermaid from markdown if needed
extract_mermaid() {
    local file="$1"
    if [[ "$file" == *.md ]]; then
        # Extract content between ```mermaid and ```
        sed -n '/^```mermaid$/,/^```$/{ /^```/d; p; }' "$file"
    else
        cat "$file"
    fi
}

# Wrap mermaid in markdown code block if needed
wrap_in_markdown() {
    local file="$1"
    if [[ "$file" == *.mmd ]]; then
        echo '```mermaid'
        cat "$file"
        echo '```'
    else
        cat "$file"
    fi
}

cmd_local() {
    local file="${1:?Usage: preview.sh local <file> [--dark]}"
    local dark=false
    [[ "${2:-}" == "--dark" ]] && dark=true

    # Check for mmdc
    if ! command -v mmdc &>/dev/null && ! npx -y @mermaid-js/mermaid-cli mmdc --version &>/dev/null 2>&1; then
        echo "mermaid-cli not found. Install with:"
        echo "  npm install -g @mermaid-js/mermaid-cli"
        echo "Or it will be auto-installed via npx on first use."
        exit 1
    fi

    local mmd_file="$PREVIEW_DIR/preview.mmd"
    extract_mermaid "$file" > "$mmd_file"

    local output="$PREVIEW_DIR/preview.svg"
    echo "Generating SVG..."

    if command -v mmdc &>/dev/null; then
        local mmdc_cmd="mmdc"
    else
        local mmdc_cmd="npx -y @mermaid-js/mermaid-cli mmdc"
    fi

    if $dark; then
        # Generate with dark background
        local config="$PREVIEW_DIR/dark-config.json"
        cat > "$config" << 'DARKEOF'
{
  "theme": "dark",
  "backgroundColor": "#0d1117"
}
DARKEOF
        $mmdc_cmd -i "$mmd_file" -o "$output" -b "#0d1117" -t dark 2>&1
    else
        $mmdc_cmd -i "$mmd_file" -o "$output" 2>&1
    fi

    if [[ -f "$output" ]]; then
        echo "Generated: $output"
        # Open in default browser
        if command -v open &>/dev/null; then
            open "$output"
        elif command -v xdg-open &>/dev/null; then
            xdg-open "$output"
        else
            echo "Open manually: $output"
        fi
    else
        echo "Error: Failed to generate SVG"
        exit 1
    fi
}

cmd_gist() {
    local file="${1:?Usage: preview.sh gist <file.mmd|file.md>}"

    if ! command -v gh &>/dev/null; then
        echo "Error: gh CLI not found. Install from https://cli.github.com/"
        exit 1
    fi

    local md_file="$PREVIEW_DIR/preview-gist.md"
    wrap_in_markdown "$file" > "$md_file"

    echo "Creating private gist..."
    local gist_url
    gist_url=$(gh gist create "$md_file" --desc "Mermaid diagram preview" 2>&1)

    if [[ "$gist_url" == https://* ]]; then
        # Extract gist ID from URL
        local gist_id="${gist_url##*/}"
        echo "$gist_id $gist_url $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$TRACKING_FILE"
        echo "Gist created: $gist_url"

        if command -v open &>/dev/null; then
            open "$gist_url"
        elif command -v xdg-open &>/dev/null; then
            xdg-open "$gist_url"
        fi
    else
        echo "Error creating gist: $gist_url"
        exit 1
    fi
}

cmd_list() {
    if [[ ! -f "$TRACKING_FILE" ]] || [[ ! -s "$TRACKING_FILE" ]]; then
        echo "No tracked preview gists."
        return
    fi

    echo "Tracked preview gists:"
    echo "---"
    while IFS=' ' read -r gist_id gist_url created_at; do
        echo "  ID: $gist_id"
        echo "  URL: $gist_url"
        echo "  Created: $created_at"
        echo "  ---"
    done < "$TRACKING_FILE"
    echo ""
    echo "Total: $(wc -l < "$TRACKING_FILE" | tr -d ' ') gists"
}

cmd_cleanup() {
    if [[ ! -f "$TRACKING_FILE" ]] || [[ ! -s "$TRACKING_FILE" ]]; then
        echo "No tracked preview gists to clean up."
        return
    fi

    echo "The following preview gists can be deleted:"
    echo ""
    cmd_list
    echo ""
    echo "To delete a gist, run: gh gist delete <GIST_ID>"
    echo "After deletion, remove the line from: $TRACKING_FILE"
    echo ""
    echo "NOTE: Do not delete gists without user confirmation."
}

# Main dispatch
case "${1:-help}" in
    local)   shift; cmd_local "$@" ;;
    gist)    shift; cmd_gist "$@" ;;
    list)    cmd_list ;;
    cleanup) cmd_cleanup ;;
    help|*)
        echo "Mermaid Diagram Preview"
        echo ""
        echo "Usage:"
        echo "  preview.sh local <file.mmd|file.md> [--dark]  - Generate SVG preview"
        echo "  preview.sh gist <file.mmd|file.md>            - Create private gist preview"
        echo "  preview.sh list                                - List tracked gists"
        echo "  preview.sh cleanup                             - Show gists for cleanup"
        ;;
esac
