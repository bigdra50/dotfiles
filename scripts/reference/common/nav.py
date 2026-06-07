"""Shared top navigation across the reference hub and its domain pages.

Domain pages live at <domain>/index.html (depth 1); the hub lives at the
site root (depth 0). The nav uses relative hrefs so the same link set works
under any Pages base path: domain pages pass base="../", the hub passes "./".
"""

from __future__ import annotations

from common.page_config import NavLink

DOMAIN_ORDER: tuple[tuple[str, str], ...] = (
    ("keybindings", "Keybindings"),
    ("shortcuts", "Shortcuts"),
    ("tasks", "mise Tasks"),
    ("claude", "Claude"),
)


def build_nav(active: str, base: str = "../") -> tuple[NavLink, ...]:
    """Return nav links for a page. `active` is a domain slug or "home"."""
    links = [NavLink("Overview", base, active == "home")]
    for slug, label in DOMAIN_ORDER:
        links.append(NavLink(label, f"{base}{slug}/", active == slug))
    return tuple(links)
