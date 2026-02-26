# Atlassian Document Format (ADF) Reference

Jira uses ADF, not Markdown. When using `--description` with plain text, markdown syntax like `**bold**` will appear as literal characters.

## Using --from-json for Rich Formatting

To get proper formatting (headings, bold, lists), use `--from-json` with an ADF structure:

```bash
# Create with rich formatting
cat > workitem.json << 'EOF'
{
  "projectKey": "PROJ",
  "summary": "Ticket title",
  "type": "Bug",
  "description": {
    "type": "doc",
    "version": 1,
    "content": [
      {
        "type": "heading",
        "attrs": { "level": 2 },
        "content": [{ "type": "text", "text": "Issue Summary" }]
      },
      {
        "type": "paragraph",
        "content": [{ "type": "text", "text": "Description here" }]
      }
    ]
  }
}
EOF
acli jira workitem create --from-json workitem.json
```

## Text Marks

Apply to text nodes:

```json
{ "type": "text", "text": "bold text", "marks": [{ "type": "strong" }] }
{ "type": "text", "text": "italic", "marks": [{ "type": "em" }] }
{ "type": "text", "text": "strikethrough", "marks": [{ "type": "strike" }] }
{ "type": "text", "text": "underline", "marks": [{ "type": "underline" }] }
{ "type": "text", "text": "code", "marks": [{ "type": "code" }] }
{ "type": "text", "text": "link text", "marks": [{ "type": "link", "attrs": { "href": "https://example.com" } }] }
```

## Block Elements

### Heading (levels 1-6)
```json
{
  "type": "heading",
  "attrs": { "level": 2 },
  "content": [{ "type": "text", "text": "Heading Text" }]
}
```

### Paragraph
```json
{
  "type": "paragraph",
  "content": [{ "type": "text", "text": "Paragraph text" }]
}
```

### Bullet List
```json
{
  "type": "bulletList",
  "content": [
    {
      "type": "listItem",
      "content": [
        { "type": "paragraph", "content": [{ "type": "text", "text": "Item 1" }] }
      ]
    },
    {
      "type": "listItem",
      "content": [
        { "type": "paragraph", "content": [{ "type": "text", "text": "Item 2" }] }
      ]
    }
  ]
}
```

### Numbered List
```json
{
  "type": "orderedList",
  "attrs": { "order": 1 },
  "content": [
    {
      "type": "listItem",
      "content": [
        { "type": "paragraph", "content": [{ "type": "text", "text": "Step 1" }] }
      ]
    }
  ]
}
```

### Blockquote
```json
{
  "type": "blockquote",
  "content": [
    { "type": "paragraph", "content": [{ "type": "text", "text": "Quoted text" }] }
  ]
}
```

### Code Block
```json
{
  "type": "codeBlock",
  "attrs": { "language": "python" },
  "content": [{ "type": "text", "text": "print('hello')" }]
}
```

### Horizontal Rule
```json
{ "type": "rule" }
```

### Table
```json
{
  "type": "table",
  "attrs": { "isNumberColumnEnabled": false, "layout": "align-start" },
  "content": [
    {
      "type": "tableRow",
      "content": [
        {
          "type": "tableHeader",
          "attrs": {},
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Header 1" }] }]
        },
        {
          "type": "tableHeader",
          "attrs": {},
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Header 2" }] }]
        }
      ]
    },
    {
      "type": "tableRow",
      "content": [
        {
          "type": "tableCell",
          "attrs": {},
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Cell 1" }] }]
        },
        {
          "type": "tableCell",
          "attrs": {},
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Cell 2" }] }]
        }
      ]
    }
  ]
}
```

## Complete Example: Bug Report Template

```json
{
  "projectKey": "PROJ",
  "summary": "Bug title here",
  "type": "Bug",
  "description": {
    "type": "doc",
    "version": 1,
    "content": [
      {
        "type": "heading",
        "attrs": { "level": 2 },
        "content": [{ "type": "text", "text": "Issue Summary" }]
      },
      {
        "type": "paragraph",
        "content": [{ "type": "text", "text": "Brief description of the issue." }]
      },
      {
        "type": "heading",
        "attrs": { "level": 2 },
        "content": [{ "type": "text", "text": "Impact" }]
      },
      {
        "type": "bulletList",
        "content": [
          {
            "type": "listItem",
            "content": [
              { "type": "paragraph", "content": [{ "type": "text", "text": "Impact item 1" }] }
            ]
          },
          {
            "type": "listItem",
            "content": [
              { "type": "paragraph", "content": [{ "type": "text", "text": "Impact item 2" }] }
            ]
          }
        ]
      },
      {
        "type": "heading",
        "attrs": { "level": 2 },
        "content": [{ "type": "text", "text": "Steps to Reproduce" }]
      },
      {
        "type": "orderedList",
        "attrs": { "order": 1 },
        "content": [
          {
            "type": "listItem",
            "content": [
              { "type": "paragraph", "content": [{ "type": "text", "text": "Step 1" }] }
            ]
          },
          {
            "type": "listItem",
            "content": [
              { "type": "paragraph", "content": [{ "type": "text", "text": "Step 2" }] }
            ]
          }
        ]
      },
      {
        "type": "paragraph",
        "content": [
          { "type": "text", "text": "Reported by: ", "marks": [{ "type": "strong" }] },
          { "type": "text", "text": "username" }
        ]
      }
    ]
  }
}
```

## Editing with ADF

```bash
cat > edit.json << 'EOF'
{
  "issues": ["KEY-123"],
  "description": {
    "type": "doc",
    "version": 1,
    "content": [
      {
        "type": "heading",
        "attrs": { "level": 2 },
        "content": [{ "type": "text", "text": "Updated Summary" }]
      }
    ]
  }
}
EOF
acli jira workitem edit --from-json edit.json --yes
```
