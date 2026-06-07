"""Pure renderer for the reference hub landing page.

The hub is the site root: a short overview with one card per domain
(record count + link) and the same top navigation as the domain pages.
"""

from __future__ import annotations

import html

from common.nav import build_nav
from common.page_config import NavLink


def _escape(value: str) -> str:
    return html.escape(value, quote=True)


def _nav_html(links: tuple[NavLink, ...]) -> str:
    return "".join(
        f"<a class='nav-link{' active' if link.active else ''}' "
        f"href='{_escape(link.href)}'>{_escape(link.label)}</a>"
        for link in links
    )


def _card_html(card: dict[str, str]) -> str:
    slug = _escape(card.get("slug", ""))
    label = _escape(card.get("label", ""))
    count = _escape(str(card.get("count", "")))
    note = _escape(card.get("note", ""))
    return (
        f"<a class='card' href='{slug}/'>"
        f"<span class='card-title'>{label}</span>"
        f"<span class='card-count'>{count}</span>"
        f"<span class='card-note'>{note}</span>"
        f"</a>"
    )


def render_hub(cards: list[dict[str, str]], meta: dict[str, str]) -> str:
    """Return the hub landing page HTML."""
    nav = _nav_html(build_nav("home", base="./"))
    generated_at = _escape(meta.get("generated_at", ""))
    commit = _escape(meta.get("commit", ""))
    cards_html = "".join(_card_html(card) for card in cards)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Dotfiles Reference</title>
<style>
:root {{
  color-scheme: light dark;
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  font-size: 14px;
  line-height: 1.4;
}}
* {{ box-sizing: border-box; }}
body {{ margin: 0; padding: 16px 20px; max-width: 900px; }}
.top-nav {{ display: flex; flex-wrap: wrap; gap: 4px 8px; margin-bottom: 16px; }}
.nav-link {{
  text-decoration: none; padding: 2px 10px; border-radius: 4px;
  border: 1px solid #8884; color: inherit; font-size: 12px;
}}
.nav-link.active {{ background: #06c; color: #fff; border-color: #06c; }}
@media (prefers-color-scheme: dark) {{
  .nav-link.active {{ background: #4a9eff; border-color: #4a9eff; }}
}}
h1 {{ margin: 0 0 4px; font-size: 1.5rem; }}
.subtitle {{ color: #666; font-size: 13px; margin-bottom: 20px; }}
@media (prefers-color-scheme: dark) {{ .subtitle {{ color: #aaa; }} }}
.cards {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px; }}
.card {{
  display: flex; flex-direction: column; gap: 4px;
  padding: 14px 16px; border: 1px solid #8884; border-radius: 8px;
  text-decoration: none; color: inherit;
}}
.card:hover {{ border-color: #06c; }}
.card-title {{ font-size: 1.1rem; font-weight: 600; }}
.card-count {{ font-size: 1.6rem; font-weight: 700; }}
.card-note {{ font-size: 12px; color: #666; }}
@media (prefers-color-scheme: dark) {{ .card-note {{ color: #aaa; }} }}
footer {{ margin-top: 24px; color: #666; font-size: 12px; }}
@media (prefers-color-scheme: dark) {{ footer {{ color: #aaa; }} }}
</style>
</head>
<body>
<nav class="top-nav">{nav}</nav>
<h1>Dotfiles Reference</h1>
<div class="subtitle">Searchable references generated from this dotfiles repository.</div>
<div class="cards">{cards_html}</div>
<footer>generated: {generated_at} · commit: {commit}</footer>
</body>
</html>
"""
