"""Scan ``.claude/`` and collect skill, agent, command, and rule assets."""

from __future__ import annotations

from pathlib import Path

from claude.frontmatter import parse_frontmatter
from claude.schema import ClaudeAsset, collapse_whitespace, to_record

TYPE_ORDER: dict[str, int] = {
    "agent": 0,
    "command": 1,
    "rule": 2,
    "skill": 3,
}


def first_heading_or_line(body: str) -> str:
    """Return the first markdown heading or first non-empty body line."""
    for line in body.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("#"):
            return stripped.lstrip("#").strip()
        return stripped
    return ""


def extract_body(text: str) -> str:
    """Return markdown body text after an optional frontmatter block."""
    if not text.startswith("---\n"):
        return text

    lines = text.splitlines()
    for index in range(1, len(lines)):
        if lines[index] == "---":
            return "\n".join(lines[index + 1 :])
    return text


def normalize_invocable(raw_value: str) -> str:
    """Normalize ``user-invocable`` frontmatter to ``true``, ``false``, or empty."""
    lowered = raw_value.strip().lower()
    if lowered in {"true", "false"}:
        return lowered
    return ""


def relative_source(file_path: Path, claude_dir: Path, root: Path) -> str:
    """Build a repo-relative POSIX path for an asset file."""
    try:
        return file_path.relative_to(root).as_posix()
    except ValueError:
        relative = file_path.relative_to(claude_dir)
        return (Path(".claude") / relative).as_posix()


def collect_claude_assets(root: Path) -> list[dict[str, str]]:
    """Collect Claude Code assets from ``root / .claude``."""
    claude_dir = root / ".claude"
    if not claude_dir.is_dir():
        return []
    return collect_from_claude_dir(claude_dir, root)


def collect_from_claude_dir(claude_dir: Path, root: Path) -> list[dict[str, str]]:
    """Collect Claude Code assets from a ``.claude`` directory tree."""
    assets: list[ClaudeAsset] = []
    assets.extend(_collect_skills(claude_dir, root))
    assets.extend(_collect_agents(claude_dir, root))
    assets.extend(_collect_commands(claude_dir, root))
    assets.extend(_collect_rules(claude_dir, root))

    records = [to_record(asset) for asset in assets]
    return sorted(
        records,
        key=lambda record: (TYPE_ORDER.get(record["type"], 99), record["source"]),
    )


def _collect_skills(claude_dir: Path, root: Path) -> list[ClaudeAsset]:
    skills_root = claude_dir / "skills"
    if not skills_root.is_dir():
        return []

    assets: list[ClaudeAsset] = []
    for skill_file in sorted(skills_root.glob("*/SKILL.md")):
        text = skill_file.read_text(encoding="utf-8")
        frontmatter = parse_frontmatter(text) or {}
        name = frontmatter.get("name", "").strip() or skill_file.parent.name
        description = frontmatter.get("description", "")
        invocable = normalize_invocable(frontmatter.get("user-invocable", ""))
        assets.append(
            ClaudeAsset(
                type="skill",
                name=name,
                description=description,
                model="",
                invocable=invocable,
                source=relative_source(skill_file, claude_dir, root),
            )
        )
    return assets


def _collect_agents(claude_dir: Path, root: Path) -> list[ClaudeAsset]:
    agents_root = claude_dir / "agents"
    if not agents_root.is_dir():
        return []

    assets: list[ClaudeAsset] = []
    for agent_file in sorted(agents_root.rglob("*.md")):
        text = agent_file.read_text(encoding="utf-8")
        frontmatter = parse_frontmatter(text) or {}
        name = frontmatter.get("name", "").strip() or agent_file.stem
        description = frontmatter.get("description", "")
        model = frontmatter.get("model", "").strip()
        assets.append(
            ClaudeAsset(
                type="agent",
                name=name,
                description=description,
                model=model,
                invocable="",
                source=relative_source(agent_file, claude_dir, root),
            )
        )
    return assets


def _collect_commands(claude_dir: Path, root: Path) -> list[ClaudeAsset]:
    commands_root = claude_dir / "commands"
    if not commands_root.is_dir():
        return []

    assets: list[ClaudeAsset] = []
    for command_file in sorted(commands_root.rglob("*.md")):
        text = command_file.read_text(encoding="utf-8")
        frontmatter = parse_frontmatter(text)
        body = extract_body(text)

        if frontmatter is None:
            name = command_file.stem
            description = first_heading_or_line(body)
        else:
            name = frontmatter.get("name", "").strip() or command_file.stem
            description = frontmatter.get(
                "description", ""
            ).strip() or first_heading_or_line(body)

        assets.append(
            ClaudeAsset(
                type="command",
                name=name,
                description=collapse_whitespace(description),
                model="",
                invocable="",
                source=relative_source(command_file, claude_dir, root),
            )
        )
    return assets


def _collect_rules(claude_dir: Path, root: Path) -> list[ClaudeAsset]:
    rules_root = claude_dir / "rules"
    if not rules_root.is_dir():
        return []

    assets: list[ClaudeAsset] = []
    for rule_file in sorted(rules_root.rglob("*.md")):
        text = rule_file.read_text(encoding="utf-8")
        description = first_heading_or_line(text)
        assets.append(
            ClaudeAsset(
                type="rule",
                name=rule_file.stem,
                description=description,
                model="",
                invocable="",
                source=relative_source(rule_file, claude_dir, root),
            )
        )
    return assets
