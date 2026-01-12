#!/usr/bin/env python3
"""
Claude Code Tool Usage Statistics Aggregator
"""

import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta
from pathlib import Path


def load_records(log_file: Path, period: str) -> list[dict]:
    """指定期間のレコードを読み込む"""
    if not log_file.exists():
        return []

    now = datetime.now()
    if period == "today":
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    elif period == "week":
        start = now - timedelta(days=7)
    elif period == "month":
        start = now - timedelta(days=30)
    else:  # all
        start = datetime.min

    records = []
    with open(log_file, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                ts = datetime.fromisoformat(record.get("timestamp", ""))
                if ts >= start:
                    records.append(record)
            except (json.JSONDecodeError, ValueError):
                continue
    return records


def aggregate_by_tool(records: list[dict]) -> Counter:
    """ツール別の使用回数を集計"""
    return Counter(r.get("tool_name", "unknown") for r in records)


def aggregate_by_skill(records: list[dict]) -> Counter:
    """Skill別の使用回数を集計"""
    skills = []
    for r in records:
        if r.get("tool_name") == "Skill":
            detail = r.get("detail", {})
            skill_name = detail.get("skill_name", "unknown")
            skills.append(skill_name)
    return Counter(skills)


def aggregate_by_subagent(records: list[dict]) -> Counter:
    """サブエージェント(Task)別の使用回数を集計"""
    subagents = []
    for r in records:
        if r.get("tool_name") == "Task":
            detail = r.get("detail", {})
            subagent_type = detail.get("subagent_type", "unknown")
            subagents.append(subagent_type)
    return Counter(subagents)


def aggregate_by_session(records: list[dict]) -> dict:
    """セッション別の統計を集計"""
    sessions = defaultdict(lambda: {"count": 0, "tools": Counter()})
    for r in records:
        sid = r.get("session_id", "unknown")
        sessions[sid]["count"] += 1
        sessions[sid]["tools"][r.get("tool_name", "unknown")] += 1
    return dict(sessions)


def aggregate_by_file(records: list[dict]) -> Counter:
    """編集/読取ファイル別の使用回数を集計"""
    files = []
    for r in records:
        detail = r.get("detail", {})
        if detail.get("type") in ("file_write", "file_read"):
            fp = detail.get("file_path", "")
            if fp:
                files.append(fp)
    return Counter(files)


def aggregate_by_mcp(records: list[dict]) -> Counter:
    """MCPサーバー別の使用回数を集計"""
    mcp_servers = []
    for r in records:
        detail = r.get("detail", {})
        if detail.get("type") == "mcp":
            server = detail.get("server", "unknown")
            mcp_servers.append(server)
    return Counter(mcp_servers)


def format_ranking(counter: Counter, title: str, limit: int = 10) -> str:
    """ランキング形式で出力"""
    if not counter:
        return f"\n### {title}\nNo data\n"

    lines = [f"\n### {title}"]
    total = sum(counter.values())
    for i, (name, count) in enumerate(counter.most_common(limit), 1):
        pct = (count / total) * 100 if total > 0 else 0
        bar = "█" * int(pct / 5)
        lines.append(f"{i:2}. {name}: {count} ({pct:.1f}%) {bar}")
    lines.append(f"\nTotal: {total}")
    return "\n".join(lines)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Tool usage statistics")
    parser.add_argument(
        "--period",
        choices=["today", "week", "month", "all"],
        default="all",
        help="Period to aggregate",
    )
    parser.add_argument(
        "--type",
        choices=["tools", "skills", "subagents", "sessions", "files", "mcp", "summary"],
        default="summary",
        help="Aggregation type",
    )
    parser.add_argument("--limit", type=int, default=10, help="Ranking limit")
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()

    log_file = Path.home() / ".claude" / "logs" / "tool-usage.jsonl"
    records = load_records(log_file, args.period)

    if not records:
        print(f"No records found for period: {args.period}")
        sys.exit(0)

    period_label = {
        "today": "Today",
        "week": "Last 7 days",
        "month": "Last 30 days",
        "all": "All time",
    }[args.period]

    if args.type == "summary":
        print(f"# Tool Usage Statistics ({period_label})")
        print(f"Total records: {len(records)}")
        print(format_ranking(aggregate_by_tool(records), "Tools", args.limit))
        print(format_ranking(aggregate_by_skill(records), "Skills", args.limit))
        print(format_ranking(aggregate_by_subagent(records), "Subagents (Task)", args.limit))
        print(format_ranking(aggregate_by_mcp(records), "MCP Servers", args.limit))
    elif args.type == "tools":
        result = aggregate_by_tool(records)
        if args.json:
            print(json.dumps(dict(result), indent=2))
        else:
            print(f"# Tool Usage ({period_label})")
            print(format_ranking(result, "Tools", args.limit))
    elif args.type == "skills":
        result = aggregate_by_skill(records)
        if args.json:
            print(json.dumps(dict(result), indent=2))
        else:
            print(f"# Skill Usage ({period_label})")
            print(format_ranking(result, "Skills", args.limit))
    elif args.type == "subagents":
        result = aggregate_by_subagent(records)
        if args.json:
            print(json.dumps(dict(result), indent=2))
        else:
            print(f"# Subagent Usage ({period_label})")
            print(format_ranking(result, "Subagents", args.limit))
    elif args.type == "sessions":
        result = aggregate_by_session(records)
        if args.json:
            print(json.dumps(result, indent=2, default=dict))
        else:
            print(f"# Session Statistics ({period_label})")
            print(f"Total sessions: {len(result)}")
            for sid, data in sorted(result.items(), key=lambda x: -x[1]["count"])[:args.limit]:
                print(f"\n**{sid[:8]}...**: {data['count']} calls")
                for tool, cnt in data["tools"].most_common(5):
                    print(f"  - {tool}: {cnt}")
    elif args.type == "files":
        result = aggregate_by_file(records)
        if args.json:
            print(json.dumps(dict(result), indent=2))
        else:
            print(f"# File Access ({period_label})")
            print(format_ranking(result, "Files", args.limit))
    elif args.type == "mcp":
        result = aggregate_by_mcp(records)
        if args.json:
            print(json.dumps(dict(result), indent=2))
        else:
            print(f"# MCP Server Usage ({period_label})")
            print(format_ranking(result, "MCP Servers", args.limit))


if __name__ == "__main__":
    main()
