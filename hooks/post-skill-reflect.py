#!/usr/bin/env python3
"""
PostToolUse hook that triggers skill reflection after any skill completes.
Outputs context prompting Claude to invoke the reflecting-on-skills skill.
"""
import json
import sys

EXCLUDED_SKILLS = {
    "reflecting-on-skills",
}

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)

tool_name = input_data.get("tool_name", "")
if tool_name != "Skill":
    sys.exit(0)

tool_input = input_data.get("tool_input", {})
skill_name = tool_input.get("skill", "")

# Skip reflection skill to avoid infinite loop
if skill_name in EXCLUDED_SKILLS:
    sys.exit(0)

# Prompt Claude to invoke reflection
output = {
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": f"Skill '{skill_name}' has completed. Invoke the 'reflecting-on-skills' skill to analyze this usage and suggest improvements."
    }
}
print(json.dumps(output))
