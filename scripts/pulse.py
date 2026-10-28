#!/usr/bin/env python3
"""Emit a small, secret-free project-health snapshot for the Plasma widget."""

from __future__ import annotations

import datetime as dt
import json
import os
import re
from pathlib import Path


def ledger_root() -> Path:
    configured = os.environ.get("PROJECT_PULSE_LEDGER")
    if configured:
        return Path(configured).expanduser()
    return Path.home() / "Documents" / "Hermes Ledger"


VAULT = ledger_root()
PROJECTS = VAULT / "Projects"
LEDGER = VAULT / "Ledger"


def frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---", 4)
    if end < 0:
        return {}
    values: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if ":" in line and not line.startswith((" ", "-")):
            key, value = line.split(":", 1)
            values[key.strip()] = value.strip().strip("'\"")
    return values


def title_for(path: Path, text: str) -> str:
    for line in text.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return path.stem


def clean_status(value: str) -> str:
    value = value.lower()
    if value in {"active", "paused", "blocked", "completed", "draft"}:
        return value
    return "active"


def main() -> None:
    today = dt.date.today()
    project_rows = []
    ledger_rows = []
    for path in sorted(LEDGER.glob("*.md")):
        match = re.fullmatch(r"(\d{4}-\d{2}-\d{2})\.md", path.name)
        if not match:
            continue
        try:
            date = dt.date.fromisoformat(match.group(1))
        except ValueError:
            continue
        ledger_rows.append((date, path.read_text(errors="replace")))

    for path in sorted(PROJECTS.glob("*.md")):
        if path.name == "Project Index.md":
            continue
        text = path.read_text(errors="replace")
        meta = frontmatter(text)
        title = title_for(path, text)
        mentions = []
        target = f"[[Projects/{path.stem}"
        for date, ledger_text in ledger_rows:
            if target in ledger_text or path.stem in ledger_text:
                mentions.append(date)
        latest = max(mentions) if mentions else None
        age = (today - latest).days if latest else 999
        status = clean_status(meta.get("status", "active"))
        if status not in {"completed", "paused", "blocked", "draft"} and age > 21:
            status = "stale"
        project_rows.append(
            {
                "title": title.replace(" — Product and Ecosystem Assessment", ""),
                "status": status,
                "last": latest.isoformat() if latest else "no ledger trace",
                "age": age if age < 999 else None,
                "events": len(mentions),
            }
        )

    priority = {"blocked": 0, "stale": 1, "active": 2, "paused": 3, "draft": 4, "completed": 5}
    project_rows.sort(key=lambda row: (priority.get(row["status"], 9), row["age"] if row["age"] is not None else 999, row["title"].lower()))
    counts = {key: sum(row["status"] == key for row in project_rows) for key in ("active", "stale", "paused", "blocked", "completed")}
    recent = [date.isoformat() for date, _ in sorted(ledger_rows, reverse=True)[:5]]
    print(json.dumps({"generated": dt.datetime.now().isoformat(timespec="minutes"), "counts": counts, "recent": recent, "projects": project_rows[:10]}, ensure_ascii=False))


if __name__ == "__main__":
    main()
