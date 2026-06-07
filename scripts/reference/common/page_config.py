"""Configuration types for the generic searchable reference renderer.

A PageConfig fully describes one reference page (keybindings, shortcuts,
tasks, claude): which columns the table shows, which chip filters appear,
which fields the search box matches, and how badge cells are coloured. The
renderer stays domain-agnostic; each domain supplies its own PageConfig.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class Column:
    """One table column.

    kind:
      - "text": single-line cell (default)
      - "wrap": wrapping cell that truncates with ellipsis (descriptions, paths)
      - "badge": rendered as a coloured badge using PageConfig.badge_classes
    """

    key: str
    label: str
    kind: str = "text"


@dataclass(frozen=True)
class Filter:
    """One chip filter group.

    values: explicit chip values in display order, or None to derive the
            sorted unique set from the data at render time.
    default: values selected on first load (empty = all selected / no filter).
    """

    field: str
    label: str
    values: tuple[str, ...] | None = None
    default: tuple[str, ...] = ()


@dataclass(frozen=True)
class NavLink:
    label: str
    href: str
    active: bool = False


@dataclass(frozen=True)
class PageConfig:
    title: str
    columns: tuple[Column, ...]
    filters: tuple[Filter, ...]
    search_fields: tuple[str, ...]
    badge_classes: dict[str, str] = field(default_factory=dict)
    nav: tuple[NavLink, ...] = ()
    note: str = ""
