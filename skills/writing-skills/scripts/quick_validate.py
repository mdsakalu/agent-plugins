#!/usr/bin/env python3
"""
Quick validation script for skills

Usage:
    python quick_validate.py <skill_directory>

Examples:
    python quick_validate.py ~/.claude/skills/my-skill
    python quick_validate.py .claude/skills/project-skill
"""

import sys
import re
from pathlib import Path

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


ALLOWED_FRONTMATTER_KEYS = {'name', 'description', 'license', 'allowed-tools', 'metadata', 'compatibility'}
RESERVED_WORDS = {'anthropic', 'claude'}


def parse_frontmatter(content: str) -> tuple[dict | None, str | None]:
    """Extract and parse YAML frontmatter from markdown content."""
    if not content.startswith('---'):
        return None, "No YAML frontmatter found (must start with ---)"

    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return None, "Invalid frontmatter format (missing closing ---)"

    frontmatter_text = match.group(1)

    if HAS_YAML:
        try:
            frontmatter = yaml.safe_load(frontmatter_text)
            if not isinstance(frontmatter, dict):
                return None, "Frontmatter must be a YAML dictionary"
            return frontmatter, None
        except yaml.YAMLError as e:
            return None, f"Invalid YAML: {e}"
    else:
        # Simple parsing without PyYAML
        frontmatter = {}
        for line in frontmatter_text.split('\n'):
            if ':' in line:
                key, value = line.split(':', 1)
                frontmatter[key.strip()] = value.strip()
        return frontmatter, None


def validate_name(name: str) -> list[str]:
    """Validate skill name. Returns list of errors."""
    errors = []

    if not isinstance(name, str):
        return [f"Name must be a string, got {type(name).__name__}"]

    name = name.strip()
    if not name:
        return ["Name cannot be empty"]

    # Check hyphen-case format
    if not re.match(r'^[a-z0-9-]+$', name):
        errors.append(f"Name '{name}' must be hyphen-case (lowercase letters, digits, hyphens only)")

    # Check hyphen placement
    if name.startswith('-') or name.endswith('-'):
        errors.append(f"Name '{name}' cannot start or end with hyphen")
    if '--' in name:
        errors.append(f"Name '{name}' cannot contain consecutive hyphens")

    # Check length
    if len(name) > 64:
        errors.append(f"Name too long ({len(name)} chars). Maximum is 64.")

    # Check reserved words
    for reserved in RESERVED_WORDS:
        if reserved in name.lower():
            errors.append(f"Name cannot contain reserved word '{reserved}'")

    return errors


def validate_description(description: str) -> list[str]:
    """Validate skill description. Returns list of errors."""
    errors = []

    if not isinstance(description, str):
        return [f"Description must be a string, got {type(description).__name__}"]

    description = description.strip()
    if not description:
        return ["Description cannot be empty"]

    # Check for angle brackets
    if '<' in description or '>' in description:
        errors.append("Description cannot contain angle brackets (< or >)")

    # Check length
    if len(description) > 1024:
        errors.append(f"Description too long ({len(description)} chars). Maximum is 1024.")

    # Warn about first-person language
    first_person_patterns = [r'\bI can\b', r'\bI will\b', r'\bYou can\b', r'\bYou should\b']
    for pattern in first_person_patterns:
        if re.search(pattern, description, re.IGNORECASE):
            errors.append("Description should be third person (avoid 'I can', 'You can', etc.)")
            break

    return errors


def validate_license(license_val: str) -> list[str]:
    """Validate license field. Returns list of errors."""
    errors = []

    if not isinstance(license_val, str):
        return [f"License must be a string, got {type(license_val).__name__}"]

    license_val = license_val.strip()
    if len(license_val) > 256:
        errors.append(f"License too long ({len(license_val)} chars). Maximum is 256.")

    return errors


def validate_compatibility(compatibility: str) -> list[str]:
    """Validate compatibility field. Returns list of errors."""
    errors = []

    if not isinstance(compatibility, str):
        return [f"Compatibility must be a string, got {type(compatibility).__name__}"]

    compatibility = compatibility.strip()
    if len(compatibility) > 500:
        errors.append(f"Compatibility too long ({len(compatibility)} chars). Maximum is 500.")

    return errors


def validate_skill(skill_path: str) -> tuple[bool, list[str]]:
    """Validate a skill directory. Returns (is_valid, list of errors/warnings)."""
    skill_path = Path(skill_path).expanduser().resolve()
    errors = []
    warnings = []

    # Check SKILL.md exists
    skill_md = skill_path / 'SKILL.md'
    if not skill_md.exists():
        return False, ["SKILL.md not found"]

    # Read content
    content = skill_md.read_text()

    # Parse frontmatter
    frontmatter, parse_error = parse_frontmatter(content)
    if parse_error:
        return False, [parse_error]

    # Check for unexpected keys
    unexpected = set(frontmatter.keys()) - ALLOWED_FRONTMATTER_KEYS
    if unexpected:
        errors.append(f"Unexpected frontmatter keys: {', '.join(sorted(unexpected))}")
        errors.append(f"Allowed keys: {', '.join(sorted(ALLOWED_FRONTMATTER_KEYS))}")

    # Validate required fields
    if 'name' not in frontmatter:
        errors.append("Missing required field: name")
    else:
        errors.extend(validate_name(frontmatter['name']))

    if 'description' not in frontmatter:
        errors.append("Missing required field: description")
    else:
        errors.extend(validate_description(frontmatter['description']))

    # Validate optional fields if present
    if 'license' in frontmatter:
        errors.extend(validate_license(frontmatter['license']))

    if 'compatibility' in frontmatter:
        errors.extend(validate_compatibility(frontmatter['compatibility']))

    if 'metadata' in frontmatter:
        if not isinstance(frontmatter['metadata'], dict):
            errors.append("metadata must be a YAML map/dictionary")

    # Check SKILL.md line count
    lines = content.split('\n')
    if len(lines) > 500:
        warnings.append(f"SKILL.md has {len(lines)} lines (recommended: under 500)")

    # Check for TODO markers
    if '[TODO' in content:
        warnings.append("SKILL.md contains [TODO] markers")

    # Return results
    all_messages = errors + [f"Warning: {w}" for w in warnings]

    if errors:
        return False, all_messages
    elif warnings:
        return True, all_messages
    else:
        return True, ["Skill is valid!"]


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    skill_path = sys.argv[1]
    valid, messages = validate_skill(skill_path)

    for msg in messages:
        print(msg)

    sys.exit(0 if valid else 1)


if __name__ == "__main__":
    main()
