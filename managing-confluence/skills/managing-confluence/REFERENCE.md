# Reference

## Storage Format

Confluence uses XHTML-based "storage format" for page content. This is similar to HTML but with Atlassian-specific macros.

### Basic Elements

```html
<!-- Headings -->
<h1>Heading 1</h1>
<h2>Heading 2</h2>
<h3>Heading 3</h3>

<!-- Paragraphs -->
<p>Regular paragraph text.</p>
<p><strong>Bold text</strong> and <em>italic text</em></p>

<!-- Links -->
<a href="https://example.com">External link</a>
<ac:link><ri:page ri:content-title="Page Name" /></ac:link>

<!-- Lists -->
<ul>
  <li>Bullet item</li>
  <li>Another item</li>
</ul>
<ol>
  <li>Numbered item</li>
  <li>Another item</li>
</ol>

<!-- Tables -->
<table>
  <tr>
    <th>Header 1</th>
    <th>Header 2</th>
  </tr>
  <tr>
    <td>Cell 1</td>
    <td>Cell 2</td>
  </tr>
</table>
```

### Code Blocks

```html
<!-- Inline code -->
<code>inline code</code>

<!-- Code block with language -->
<ac:structured-macro ac:name="code">
  <ac:parameter ac:name="language">python</ac:parameter>
  <ac:plain-text-body><![CDATA[
def hello():
    print("Hello, world!")
]]></ac:plain-text-body>
</ac:structured-macro>
```

Supported languages: `python`, `java`, `javascript`, `bash`, `sql`, `json`, `xml`, `yaml`, `go`, `ruby`, `csharp`, `cpp`, `php`, etc.

### Info Panels

```html
<!-- Info panel -->
<ac:structured-macro ac:name="info">
  <ac:rich-text-body>
    <p>This is an info message.</p>
  </ac:rich-text-body>
</ac:structured-macro>

<!-- Warning panel -->
<ac:structured-macro ac:name="warning">
  <ac:rich-text-body>
    <p>This is a warning message.</p>
  </ac:rich-text-body>
</ac:structured-macro>

<!-- Note panel -->
<ac:structured-macro ac:name="note">
  <ac:rich-text-body>
    <p>This is a note.</p>
  </ac:rich-text-body>
</ac:structured-macro>

<!-- Tip panel -->
<ac:structured-macro ac:name="tip">
  <ac:rich-text-body>
    <p>This is a tip.</p>
  </ac:rich-text-body>
</ac:structured-macro>
```

### Table of Contents

```html
<ac:structured-macro ac:name="toc">
  <ac:parameter ac:name="printable">true</ac:parameter>
  <ac:parameter ac:name="style">disc</ac:parameter>
  <ac:parameter ac:name="maxLevel">3</ac:parameter>
</ac:structured-macro>
```

### Expand/Collapse

```html
<ac:structured-macro ac:name="expand">
  <ac:parameter ac:name="title">Click to expand</ac:parameter>
  <ac:rich-text-body>
    <p>Hidden content here.</p>
  </ac:rich-text-body>
</ac:structured-macro>
```

### Status Badges

```html
<ac:structured-macro ac:name="status">
  <ac:parameter ac:name="colour">Green</ac:parameter>
  <ac:parameter ac:name="title">DONE</ac:parameter>
</ac:structured-macro>

<ac:structured-macro ac:name="status">
  <ac:parameter ac:name="colour">Yellow</ac:parameter>
  <ac:parameter ac:name="title">IN PROGRESS</ac:parameter>
</ac:structured-macro>

<ac:structured-macro ac:name="status">
  <ac:parameter ac:name="colour">Red</ac:parameter>
  <ac:parameter ac:name="title">BLOCKED</ac:parameter>
</ac:structured-macro>
```

Colors: `Grey`, `Red`, `Yellow`, `Green`, `Blue`

### Task List

```html
<ac:task-list>
  <ac:task>
    <ac:task-status>incomplete</ac:task-status>
    <ac:task-body>Task to do</ac:task-body>
  </ac:task>
  <ac:task>
    <ac:task-status>complete</ac:task-status>
    <ac:task-body>Completed task</ac:task-body>
  </ac:task>
</ac:task-list>
```

---

## CQL (Confluence Query Language)

CQL is used for searching content. Uses v1 API: `/wiki/rest/api/search?cql=...`

### Basic Syntax

```
field operator value
field operator value AND field operator value
field operator value OR field operator value
```

### Fields

| Field | Description | Example |
|-------|-------------|---------|
| `title` | Page title | `title ~ "meeting"` |
| `text` | Page content | `text ~ "quarterly"` |
| `space` | Space key | `space = MYSPACE` |
| `type` | Content type | `type = page` |
| `label` | Page label | `label = "important"` |
| `creator` | Created by | `creator = currentUser()` |
| `contributor` | Modified by | `contributor = "user@email.com"` |
| `created` | Creation date | `created > "2024-01-01"` |
| `lastModified` | Last modified | `lastModified > now("-7d")` |
| `parent` | Parent page | `parent = "123456"` |
| `ancestor` | Any ancestor | `ancestor = "123456"` |

### Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `=` | Exact match | `space = MYSPACE` |
| `!=` | Not equal | `space != ARCHIVE` |
| `~` | Contains (text search) | `title ~ "meeting"` |
| `!~` | Does not contain | `text !~ "draft"` |
| `>` | Greater than | `created > "2024-01-01"` |
| `>=` | Greater than or equal | `lastModified >= "2024-01-01"` |
| `<` | Less than | `created < "2024-06-01"` |
| `<=` | Less than or equal | `lastModified <= now()` |
| `IN` | In list | `space IN (DOCS, TEAM)` |
| `NOT IN` | Not in list | `space NOT IN (ARCHIVE)` |

### Functions

| Function | Description | Example |
|----------|-------------|---------|
| `currentUser()` | Current user | `creator = currentUser()` |
| `now()` | Current time | `lastModified > now("-1d")` |
| `startOfDay()` | Start of today | `created > startOfDay()` |
| `startOfWeek()` | Start of week | `created > startOfWeek()` |
| `startOfMonth()` | Start of month | `created > startOfMonth()` |
| `startOfYear()` | Start of year | `created > startOfYear()` |

### Date Formats

- Absolute: `"2024-01-15"`, `"2024-01-15 14:30"`
- Relative: `now("-7d")`, `now("-1w")`, `now("-1M")`

### Example Queries

```bash
# Pages I created
confluence_search "creator = currentUser()"

# Pages modified in last week
confluence_search "lastModified > now('-7d')"

# Pages with specific label in a space
confluence_search "space = DOCS AND label = 'api-reference'"

# Pages containing text
confluence_search "text ~ 'quarterly report'"

# Pages by title pattern
confluence_search "title ~ 'Meeting Notes*'"

# Drafts (pages with draft label)
confluence_search "label = 'draft' AND space = MYSPACE"

# Recently modified by anyone in space
confluence_search "space = TEAM AND lastModified > now('-24h')"

# Child pages of a specific parent
confluence_search "parent = '123456'"
```

---

## API Endpoints Reference

Base URL: `https://{domain}/wiki/api/v2`

### Pages

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/pages` | List pages |
| GET | `/pages/{id}` | Get page |
| POST | `/pages` | Create page |
| PUT | `/pages/{id}` | Update page |
| DELETE | `/pages/{id}` | Delete page |
| GET | `/pages/{id}/children` | Get child pages |
| GET | `/pages/{id}/labels` | Get page labels |
| POST | `/pages/{id}/labels` | Add labels |

### Spaces

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/spaces` | List spaces |
| GET | `/spaces/{id}` | Get space |
| GET | `/spaces/{id}/pages` | List pages in space |

### Attachments

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/pages/{id}/attachments` | List attachments |
| POST | `/pages/{id}/attachments` | Upload attachment |
| GET | `/attachments/{id}` | Get attachment info |
| GET | `/attachments/{id}/download` | Download attachment |
| DELETE | `/attachments/{id}` | Delete attachment |

### Search (v1 API)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/search?cql=...` | CQL search |

---

## Common Response Fields

### Page Object

```json
{
  "id": "123456",
  "status": "current",
  "title": "Page Title",
  "spaceId": "789",
  "parentId": "111",
  "parentType": "page",
  "position": 0,
  "authorId": "user123",
  "ownerId": "user123",
  "lastOwnerId": "user123",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "version": {
    "number": 5,
    "message": "Updated content",
    "minorEdit": false,
    "authorId": "user123",
    "createdAt": "2024-02-20T14:00:00.000Z"
  },
  "body": {
    "storage": {
      "representation": "storage",
      "value": "<p>Page content...</p>"
    }
  },
  "_links": {
    "webui": "/wiki/spaces/SPACE/pages/123456/Page+Title",
    "editui": "/wiki/spaces/SPACE/pages/edit-v2/123456",
    "tinyui": "/x/abc123"
  }
}
```

### Space Object

```json
{
  "id": "789",
  "key": "MYSPACE",
  "name": "My Space",
  "type": "global",
  "status": "current",
  "authorId": "user123",
  "createdAt": "2023-01-01T00:00:00.000Z",
  "homepageId": "123456",
  "_links": {
    "webui": "/wiki/spaces/MYSPACE"
  }
}
```

---

## Error Codes

| Code | Meaning |
|------|---------|
| 400 | Bad request (invalid JSON, missing fields) |
| 401 | Unauthorized (invalid credentials) |
| 403 | Forbidden (no permission) |
| 404 | Not found (page/space doesn't exist) |
| 409 | Conflict (version mismatch on update) |
| 429 | Rate limited |

---

## External Documentation

- [Confluence Cloud REST API v2](https://developer.atlassian.com/cloud/confluence/rest/v2/)
- [REST API Examples](https://developer.atlassian.com/cloud/confluence/rest-api-examples/)
- [Storage Format](https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html)
- [CQL Reference](https://developer.atlassian.com/cloud/confluence/advanced-searching-using-cql/)
