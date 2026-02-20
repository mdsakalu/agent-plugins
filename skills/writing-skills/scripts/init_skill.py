#!/usr/bin/env python3
"""
Skill Initializer - Creates a new skill from template

Usage:
    python init_skill.py <skill-name> [--path <path>]

Examples:
    python init_skill.py my-new-skill
    python init_skill.py my-api-helper --path ~/.claude/skills
    python init_skill.py project-skill --path .claude/skills
"""

import sys
from pathlib import Path


SKILL_TEMPLATE = """---
name: {skill_name}
description: "[TODO: What this skill does and when to use it. Include trigger words. Write in third person.]"
allowed-tools: "[TODO: List tools this skill needs, e.g., Bash, Read, Edit]"
# Optional fields (uncomment as needed):
# license: MIT
# metadata:
#   author: Your Name
#   version: 1.0.0
#   updated: YYYY-MM-DD
# compatibility: |
#   Platform requirements and limitations (max 500 chars)
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## Quick Start

[TODO: Minimal working example - the simplest use case]

## Instructions

[TODO: Clear, step-by-step guidance using imperative language.
Use action verbs: "Run", "Create", "Verify", "Check".

Choose structure based on skill type:

**Workflow-Based** - For sequential processes:
1. Do X
2. Do Y
3. Do Z

**Task-Based** - For tool collections:
- Task A: How to do A
- Task B: How to do B

**Reference-Based** - For standards/specs:
- Guidelines
- Specifications
- Examples

Delete this TODO block when done.]

## Refusal and Escalation

[TODO: Define when to refuse or escalate. Delete if not applicable.]

**Refuse**: [conditions when skill should not proceed]

**Escalate**: [conditions when skill should ask user first]

## Evaluation Checklist

[TODO: Quality criteria for outputs. Delete if not applicable.]

- [ ] [Quality criterion 1]
- [ ] [Quality criterion 2]

## Resources

[TODO: If you have scripts, references, or assets, document them here.
Use {{baseDir}} for portable paths:

- **scripts/**: Executable code (use `{{baseDir}}/scripts/` for paths)
- **references/**: Documentation loaded into context as needed
- **assets/**: Templates, images used in output (not loaded into context)

Delete unused directories and this TODO block when done.]
"""

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""
Example script for {skill_name}

Replace with actual implementation or delete if not needed.
"""

def main():
    print("Example script for {skill_name}")
    # TODO: Add actual logic

if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = """# Reference for {skill_title}

[TODO: Add detailed documentation here. This file is loaded into context only when needed.]

## Contents

- Section 1
- Section 2
- Section 3

## Section 1

[Details...]
"""


def title_case(skill_name: str) -> str:
    """Convert hyphenated name to Title Case."""
    return ' '.join(word.capitalize() for word in skill_name.split('-'))


def init_skill(skill_name: str, base_path: str) -> Path | None:
    """Initialize a new skill directory with template files."""
    skill_dir = Path(base_path).expanduser().resolve() / skill_name

    if skill_dir.exists():
        print(f"Error: Directory already exists: {skill_dir}")
        return None

    try:
        skill_dir.mkdir(parents=True)
        print(f"Created: {skill_dir}")
    except Exception as e:
        print(f"Error creating directory: {e}")
        return None

    skill_title = title_case(skill_name)

    # Create SKILL.md
    skill_md = skill_dir / 'SKILL.md'
    skill_md.write_text(SKILL_TEMPLATE.format(
        skill_name=skill_name,
        skill_title=skill_title
    ))
    print("Created: SKILL.md")

    # Create scripts/ with example
    scripts_dir = skill_dir / 'scripts'
    scripts_dir.mkdir()
    example_script = scripts_dir / 'example.py'
    example_script.write_text(EXAMPLE_SCRIPT.format(skill_name=skill_name))
    example_script.chmod(0o755)
    print("Created: scripts/example.py")

    # Create references/ with example
    refs_dir = skill_dir / 'references'
    refs_dir.mkdir()
    example_ref = refs_dir / 'reference.md'
    example_ref.write_text(EXAMPLE_REFERENCE.format(skill_title=skill_title))
    print("Created: references/reference.md")

    # Create assets/ (empty, with .gitkeep)
    assets_dir = skill_dir / 'assets'
    assets_dir.mkdir()
    (assets_dir / '.gitkeep').touch()
    print("Created: assets/")

    print(f"\nSkill '{skill_name}' initialized at {skill_dir}")
    print("\nNext steps:")
    print("1. Edit SKILL.md - complete the TODOs")
    print("2. Customize or delete example files in scripts/, references/, assets/")
    print("3. Run quick_validate.py to check your skill")

    return skill_dir


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    skill_name = sys.argv[1]

    # Parse --path argument
    if '--path' in sys.argv:
        path_idx = sys.argv.index('--path')
        if path_idx + 1 < len(sys.argv):
            base_path = sys.argv[path_idx + 1]
        else:
            print("Error: --path requires a value")
            sys.exit(1)
    else:
        base_path = '~/.claude/skills'

    print(f"Initializing skill: {skill_name}")
    print(f"Location: {base_path}\n")

    result = init_skill(skill_name, base_path)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
