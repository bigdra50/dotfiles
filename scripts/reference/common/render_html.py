"""Generic searchable HTML renderer for reference pages.

Domain-agnostic: the table columns, chip filters, search fields, badge
colours, and top navigation all come from a PageConfig. Records are embedded
as JSON and the table is built client-side with textContent, so record values
never reach the static HTML as markup.
"""

from __future__ import annotations

import html
import json

from common.page_config import PageConfig


def _embed_json(value: object) -> str:
    """Serialize for safe inlining inside a <script> block."""
    return json.dumps(value, ensure_ascii=False).replace("</", "<\\/")


def _escape(value: str) -> str:
    return html.escape(value, quote=True)


def _derive_filter_values(records: list[dict[str, str]], field: str) -> list[str]:
    values = {record.get(field, "") for record in records}
    values.discard("")
    return sorted(values)


def _config_to_js(
    config: PageConfig, records: list[dict[str, str]]
) -> dict[str, object]:
    filters = []
    for flt in config.filters:
        values = (
            list(flt.values)
            if flt.values is not None
            else _derive_filter_values(records, flt.field)
        )
        filters.append(
            {
                "field": flt.field,
                "label": flt.label,
                "values": values,
                "default": list(flt.default),
            }
        )
    return {
        "columns": [
            {"key": c.key, "label": c.label, "kind": c.kind} for c in config.columns
        ],
        "filters": filters,
        "searchFields": list(config.search_fields),
        "badgeClasses": config.badge_classes,
    }


def _meta_count_items(meta: dict[str, str]) -> str:
    counts_raw = meta.get("counts", "{}")
    try:
        counts_obj = (
            json.loads(counts_raw) if isinstance(counts_raw, str) else counts_raw
        )
    except json.JSONDecodeError:
        counts_obj = {}
    if not isinstance(counts_obj, dict):
        counts_obj = {}
    return "".join(
        f"<span class='meta-count'>{_escape(str(k))}: {_escape(str(v))}</span>"
        for k, v in sorted(counts_obj.items())
    )


def _nav_html(config: PageConfig) -> str:
    if not config.nav:
        return ""
    links = "".join(
        f"<a class='nav-link{' active' if link.active else ''}' "
        f"href='{_escape(link.href)}'>{_escape(link.label)}</a>"
        for link in config.nav
    )
    return f"<nav class='top-nav'>{links}</nav>"


def render_searchable_html(
    records: list[dict[str, str]], config: PageConfig, meta: dict[str, str]
) -> str:
    """Return a self-contained searchable HTML page for the given records."""
    data_json = _embed_json(records)
    config_json = _embed_json(_config_to_js(config, records))
    title = _escape(config.title)
    generated_at = _escape(meta.get("generated_at", ""))
    commit = _escape(meta.get("commit", ""))
    note = _escape(config.note or meta.get("note", ""))
    count_items = _meta_count_items(meta)
    nav = _nav_html(config)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
:root {{
  color-scheme: light dark;
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  font-size: 13px;
  line-height: 1.35;
}}
* {{ box-sizing: border-box; }}
body {{ margin: 0; padding: 12px 16px; }}
header {{ margin-bottom: 12px; }}
h1 {{ margin: 0 0 8px; font-size: 1.25rem; }}
.top-nav {{ display: flex; flex-wrap: wrap; gap: 4px 8px; margin-bottom: 8px; }}
.nav-link {{
  text-decoration: none; padding: 2px 10px; border-radius: 4px;
  border: 1px solid #8884; color: inherit; font-size: 12px;
}}
.nav-link.active {{ background: #06c; color: #fff; border-color: #06c; }}
@media (prefers-color-scheme: dark) {{
  .nav-link.active {{ background: #4a9eff; border-color: #4a9eff; }}
}}
.meta {{ display: flex; flex-wrap: wrap; gap: 8px 16px; color: #666; font-size: 12px; }}
@media (prefers-color-scheme: dark) {{ .meta {{ color: #aaa; }} }}
.meta-count {{ white-space: nowrap; }}
.controls {{ display: flex; flex-wrap: wrap; gap: 12px; align-items: flex-start; margin-bottom: 10px; }}
.filter-group {{ display: flex; flex-direction: column; gap: 4px; }}
.filter-group > label {{ font-weight: 600; font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; }}
.chips {{ display: flex; flex-wrap: wrap; gap: 4px; }}
.chip {{
  border: 1px solid #8884; border-radius: 4px; padding: 2px 8px;
  cursor: pointer; user-select: none; font-size: 12px; background: transparent; color: inherit;
}}
.chip.active {{ background: #06c; color: #fff; border-color: #06c; }}
@media (prefers-color-scheme: dark) {{
  .chip.active {{ background: #4a9eff; border-color: #4a9eff; }}
}}
.search-box input {{
  width: 240px; padding: 4px 8px; font: inherit;
  border: 1px solid #8884; border-radius: 4px; background: transparent; color: inherit;
}}
.count-display {{ font-size: 12px; color: #666; align-self: center; }}
@media (prefers-color-scheme: dark) {{ .count-display {{ color: #aaa; }} }}
.table-wrap {{ overflow: auto; max-height: calc(100vh - 190px); border: 1px solid #8884; border-radius: 4px; }}
table {{ width: 100%; border-collapse: collapse; }}
th, td {{ padding: 3px 8px; text-align: left; border-bottom: 1px solid #8882; white-space: nowrap; }}
th {{ position: sticky; top: 0; background: Canvas; z-index: 1; font-size: 11px; text-transform: uppercase; }}
td.col-wrap {{ white-space: normal; max-width: 320px; overflow: hidden; text-overflow: ellipsis; }}
.badge {{
  display: inline-block; padding: 1px 6px; border-radius: 3px;
  font-size: 10px; font-weight: 600; text-transform: uppercase;
}}
.badge-green {{ background: #2a7; color: #fff; }}
.badge-orange {{ background: #e80; color: #fff; }}
.badge-gray {{ background: #8884; color: inherit; }}
.badge-blue {{ background: #06c; color: #fff; }}
.badge-purple {{ background: #84c; color: #fff; }}
</style>
</head>
<body>
<header>
  {nav}
  <h1>{title}</h1>
  <div class="meta">
    <span>generated: {generated_at}</span>
    <span>commit: {commit}</span>
    {count_items}
    <span>{note}</span>
  </div>
</header>
<div class="controls" id="controls"></div>
<div class="table-wrap">
  <table>
    <thead><tr id="thead-row"></tr></thead>
    <tbody id="tbody"></tbody>
  </table>
</div>
<script>
const DATA = {data_json};
const CONFIG = {config_json};

let state = {{ filters: {{}}, q: "" }};

function parseHash() {{
  const params = new URLSearchParams(location.hash.slice(1));
  const filters = {{}};
  for (const f of CONFIG.filters) {{
    const vals = params.getAll(f.field);
    filters[f.field] = vals.length > 0 ? vals : [...f.default];
  }}
  return {{ filters, q: params.get("q") || "" }};
}}

function writeHash() {{
  const params = new URLSearchParams();
  for (const f of CONFIG.filters) {{
    for (const v of state.filters[f.field] || []) params.append(f.field, v);
  }}
  if (state.q) params.set("q", state.q);
  const hash = params.toString();
  history.replaceState(null, "", hash ? "#" + hash : location.pathname);
}}

function makeChip(label, active, onToggle) {{
  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "chip" + (active ? " active" : "");
  btn.textContent = label;
  btn.addEventListener("click", onToggle);
  return btn;
}}

function renderControls() {{
  const controls = document.getElementById("controls");
  controls.replaceChildren();

  for (const f of CONFIG.filters) {{
    const group = document.createElement("div");
    group.className = "filter-group";
    const label = document.createElement("label");
    label.textContent = f.label;
    group.appendChild(label);
    const chips = document.createElement("div");
    chips.className = "chips";
    for (const value of f.values) {{
      const selected = (state.filters[f.field] || []).includes(value);
      chips.appendChild(makeChip(value, selected, () => {{
        const cur = state.filters[f.field] || [];
        state.filters[f.field] = cur.includes(value)
          ? cur.filter((v) => v !== value)
          : [...cur, value];
        writeHash();
        renderControls();
        applyFilters();
      }}));
    }}
    group.appendChild(chips);
    controls.appendChild(group);
  }}

  const searchWrap = document.createElement("div");
  searchWrap.className = "search-box";
  const searchLabel = document.createElement("label");
  searchLabel.setAttribute("for", "search-input");
  searchLabel.textContent = "Search";
  const input = document.createElement("input");
  input.type = "search";
  input.id = "search-input";
  input.placeholder = CONFIG.searchFields.join(", ") + "…";
  input.autocomplete = "off";
  input.value = state.q;
  input.addEventListener("input", (e) => {{
    state.q = e.target.value;
    writeHash();
    applyFilters();
  }});
  searchWrap.appendChild(searchLabel);
  searchWrap.appendChild(document.createElement("br"));
  searchWrap.appendChild(input);
  controls.appendChild(searchWrap);

  const counter = document.createElement("div");
  counter.className = "count-display";
  counter.id = "count-display";
  controls.appendChild(counter);
}}

function renderHead() {{
  const row = document.getElementById("thead-row");
  row.replaceChildren();
  for (const col of CONFIG.columns) {{
    const th = document.createElement("th");
    th.textContent = col.label;
    row.appendChild(th);
  }}
}}

function matchesSearch(record, query) {{
  if (!query) return true;
  const hay = CONFIG.searchFields
    .map((f) => record[f] || "")
    .join(" ")
    .toLowerCase();
  return hay.includes(query);
}}

function recordPasses(record) {{
  for (const f of CONFIG.filters) {{
    const sel = state.filters[f.field] || [];
    if (sel.length > 0 && !sel.includes(record[f.field])) return false;
  }}
  return matchesSearch(record, state.q.toLowerCase());
}}

function appendCell(row, col, record) {{
  const td = document.createElement("td");
  const value = record[col.key] || "";
  if (col.kind === "wrap") {{
    td.className = "col-wrap";
    td.textContent = value;
  }} else if (col.kind === "badge") {{
    if (value) {{
      const badge = document.createElement("span");
      const cls = CONFIG.badgeClasses[value] || "badge-gray";
      badge.className = "badge " + cls;
      badge.textContent = value;
      td.appendChild(badge);
    }}
  }} else {{
    td.textContent = value;
  }}
  row.appendChild(td);
}}

function applyFilters() {{
  const tbody = document.getElementById("tbody");
  tbody.replaceChildren();
  let shown = 0;
  for (const record of DATA) {{
    if (!recordPasses(record)) continue;
    shown += 1;
    const row = document.createElement("tr");
    for (const col of CONFIG.columns) appendCell(row, col, record);
    tbody.appendChild(row);
  }}
  document.getElementById("count-display").textContent =
    shown + " / " + DATA.length + " records";
}}

function render() {{
  renderControls();
  renderHead();
  applyFilters();
}}

state = parseHash();
render();
window.addEventListener("hashchange", () => {{ state = parseHash(); render(); }});
</script>
</body>
</html>
"""
