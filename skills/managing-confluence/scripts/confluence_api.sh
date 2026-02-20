#!/bin/bash
# Confluence Cloud API Helper Functions
# Source this file: source ~/.claude/skills/managing-confluence/scripts/confluence_api.sh

# Check required environment variables
confluence_check_env() {
    local missing=()
    [[ -z "$CONFLUENCE_EMAIL" ]] && missing+=("CONFLUENCE_EMAIL")
    [[ -z "$CONFLUENCE_API_TOKEN" ]] && missing+=("CONFLUENCE_API_TOKEN")
    [[ -z "$CONFLUENCE_DOMAIN" ]] && missing+=("CONFLUENCE_DOMAIN")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required environment variables: ${missing[*]}" >&2
        echo "See CONFIG.md for setup instructions." >&2
        return 1
    fi
    return 0
}

# Generate authorization header
confluence_auth_header() {
    echo "Basic $(echo -n "$CONFLUENCE_EMAIL:$CONFLUENCE_API_TOKEN" | base64)"
}

# Base API call - GET
confluence_get() {
    local endpoint="$1"
    local api_version="${2:-v2}"  # Default to v2

    confluence_check_env || return 1

    local base_url
    if [[ "$api_version" == "v1" ]]; then
        base_url="https://$CONFLUENCE_DOMAIN/wiki/rest/api"
    else
        base_url="https://$CONFLUENCE_DOMAIN/wiki/api/v2"
    fi

    curl -s "${base_url}${endpoint}" \
        -H "Authorization: $(confluence_auth_header)" \
        -H "Accept: application/json"
}

# Base API call - POST JSON
confluence_post() {
    local endpoint="$1"
    local data="$2"

    confluence_check_env || return 1

    curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2${endpoint}" \
        -X POST \
        -H "Authorization: $(confluence_auth_header)" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$data"
}

# Base API call - PUT JSON
confluence_put() {
    local endpoint="$1"
    local data="$2"

    confluence_check_env || return 1

    curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2${endpoint}" \
        -X PUT \
        -H "Authorization: $(confluence_auth_header)" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$data"
}

# Base API call - DELETE
confluence_delete() {
    local endpoint="$1"

    confluence_check_env || return 1

    curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2${endpoint}" \
        -X DELETE \
        -H "Authorization: $(confluence_auth_header)" \
        -H "Accept: application/json"
}

# ============================================
# SPACE OPERATIONS
# ============================================

# List all spaces
confluence_list_spaces() {
    local limit="${1:-25}"
    confluence_get "/spaces?limit=$limit"
}

# Get space by ID
confluence_get_space() {
    local space_id="$1"
    confluence_get "/spaces/$space_id"
}

# Get space by key (uses search)
confluence_get_space_by_key() {
    local space_key="$1"
    confluence_get "/spaces?keys=$space_key"
}

# ============================================
# PAGE OPERATIONS
# ============================================

# List pages in a space
confluence_list_pages() {
    local space_id="$1"
    local limit="${2:-25}"
    confluence_get "/spaces/$space_id/pages?limit=$limit"
}

# Get page by ID
confluence_get_page() {
    local page_id="$1"
    local body_format="${2:-storage}"  # storage, atlas_doc_format, view
    confluence_get "/pages/$page_id?body-format=$body_format"
}

# Get page children
confluence_get_page_children() {
    local page_id="$1"
    local limit="${2:-25}"
    confluence_get "/pages/$page_id/children?limit=$limit"
}

# Create a page
# Usage: confluence_create_page "SPACE_ID" "Title" "<p>HTML content</p>" [parent_id]
confluence_create_page() {
    local space_id="$1"
    local title="$2"
    local body="$3"
    local parent_id="$4"

    local json
    if [[ -n "$parent_id" ]]; then
        json=$(cat <<EOF
{
    "spaceId": "$space_id",
    "status": "current",
    "title": "$title",
    "parentId": "$parent_id",
    "body": {
        "representation": "storage",
        "value": "$body"
    }
}
EOF
)
    else
        json=$(cat <<EOF
{
    "spaceId": "$space_id",
    "status": "current",
    "title": "$title",
    "body": {
        "representation": "storage",
        "value": "$body"
    }
}
EOF
)
    fi

    confluence_post "/pages" "$json"
}

# Update a page
# Usage: confluence_update_page "PAGE_ID" "New Title" "<p>Updated content</p>" VERSION_NUMBER
confluence_update_page() {
    local page_id="$1"
    local title="$2"
    local body="$3"
    local version="$4"

    local json=$(cat <<EOF
{
    "id": "$page_id",
    "status": "current",
    "title": "$title",
    "body": {
        "representation": "storage",
        "value": "$body"
    },
    "version": {
        "number": $version
    }
}
EOF
)

    confluence_put "/pages/$page_id" "$json"
}

# Delete a page
confluence_delete_page() {
    local page_id="$1"
    confluence_delete "/pages/$page_id"
}

# ============================================
# ATTACHMENT OPERATIONS
# ============================================

# List attachments on a page
confluence_list_attachments() {
    local page_id="$1"
    local limit="${2:-25}"
    confluence_get "/pages/$page_id/attachments?limit=$limit"
}

# Upload attachment to a page
# Usage: confluence_upload_attachment "PAGE_ID" "/path/to/file.pdf"
confluence_upload_attachment() {
    local page_id="$1"
    local file_path="$2"

    confluence_check_env || return 1

    if [[ ! -f "$file_path" ]]; then
        echo "Error: File not found: $file_path" >&2
        return 1
    fi

    curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/pages/$page_id/attachments" \
        -X POST \
        -H "Authorization: $(confluence_auth_header)" \
        -H "X-Atlassian-Token: nocheck" \
        -F "file=@$file_path"
}

# Download attachment
# Usage: confluence_download_attachment "ATTACHMENT_ID" "/path/to/output/file"
confluence_download_attachment() {
    local attachment_id="$1"
    local output_path="$2"

    confluence_check_env || return 1

    curl -s "https://$CONFLUENCE_DOMAIN/wiki/api/v2/attachments/$attachment_id/download" \
        -H "Authorization: $(confluence_auth_header)" \
        -o "$output_path"

    echo "Downloaded to: $output_path"
}

# Delete attachment
confluence_delete_attachment() {
    local attachment_id="$1"
    confluence_delete "/attachments/$attachment_id"
}

# ============================================
# SEARCH OPERATIONS
# ============================================

# Search using CQL (Confluence Query Language)
# Uses v1 API as CQL search is more mature there
# Usage: confluence_search "space = MYSPACE AND title ~ 'meeting'"
confluence_search() {
    local cql="$1"
    local limit="${2:-25}"
    local encoded_cql
    encoded_cql=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$cql'''))")
    confluence_get "/search?cql=$encoded_cql&limit=$limit" "v1"
}

# Search pages by title
confluence_search_by_title() {
    local title="$1"
    local space_key="$2"
    local cql="title ~ \"$title\""
    [[ -n "$space_key" ]] && cql="$cql AND space = $space_key"
    confluence_search "$cql"
}

# ============================================
# LABEL OPERATIONS
# ============================================

# Get labels on a page
confluence_get_labels() {
    local page_id="$1"
    confluence_get "/pages/$page_id/labels"
}

# Add label to a page
confluence_add_label() {
    local page_id="$1"
    local label="$2"

    local json=$(cat <<EOF
[{"prefix": "global", "name": "$label"}]
EOF
)

    confluence_post "/pages/$page_id/labels" "$json"
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Test authentication
confluence_test_auth() {
    echo "Testing Confluence authentication..."
    local result
    result=$(confluence_list_spaces 1)

    if echo "$result" | grep -q '"results"'; then
        echo "Authentication successful!"
        echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"Found {len(d.get('results',[]))} space(s)\")" 2>/dev/null || echo "$result"
        return 0
    else
        echo "Authentication failed!"
        echo "$result"
        return 1
    fi
}

# Pretty print JSON response
confluence_pretty() {
    python3 -m json.tool 2>/dev/null || cat
}

# Extract page URL from response
confluence_page_url() {
    local page_id="$1"
    echo "https://$CONFLUENCE_DOMAIN/wiki/spaces/~/pages/$page_id"
}

echo "Confluence API helpers loaded. Run 'confluence_test_auth' to verify setup."
