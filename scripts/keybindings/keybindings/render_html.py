"""Pure HTML rendering for searchable keybinding tables."""

from __future__ import annotations

import html
import json


def _embed_records_json(records: list[dict[str, str]]) -> str:
    serialized = json.dumps(records, ensure_ascii=False)
    return serialized.replace("</", "<\\/")


def _escape_meta(value: str) -> str:
    return html.escape(value, quote=True)


def render_searchable_html(records: list[dict[str, str]], meta: dict[str, str]) -> str:
    """Return a self-contained searchable HTML page for keybinding records."""
    data_json = _embed_records_json(records)
    generated_at = _escape_meta(meta.get("generated_at", ""))
    commit = _escape_meta(meta.get("commit", ""))
    note = _escape_meta(meta.get("note", ""))

    counts_raw = meta.get("counts", "{}")
    try:
        counts_obj = (
            json.loads(counts_raw) if isinstance(counts_raw, str) else counts_raw
        )
    except json.JSONDecodeError:
        counts_obj = {}
    if not isinstance(counts_obj, dict):
        counts_obj = {}

    count_items = "".join(
        f"<span class='meta-count'>{_escape_meta(str(tool))}: "
        f"{_escape_meta(str(count))}</span>"
        for tool, count in sorted(counts_obj.items())
    )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Keybindings</title>
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
.meta {{ display: flex; flex-wrap: wrap; gap: 8px 16px; color: #666; font-size: 12px; }}
@media (prefers-color-scheme: dark) {{
  .meta {{ color: #aaa; }}
}}
.meta-count {{ white-space: nowrap; }}
.controls {{ display: flex; flex-wrap: wrap; gap: 12px; align-items: flex-start; margin-bottom: 10px; }}
.filter-group {{ display: flex; flex-direction: column; gap: 4px; }}
.filter-group label {{ font-weight: 600; font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; }}
.chips {{ display: flex; flex-wrap: wrap; gap: 4px; }}
.chip {{
  border: 1px solid #8884;
  border-radius: 4px;
  padding: 2px 8px;
  cursor: pointer;
  user-select: none;
  font-size: 12px;
  background: transparent;
}}
.chip.active {{ background: #06c; color: #fff; border-color: #06c; }}
@media (prefers-color-scheme: dark) {{
  .chip.active {{ background: #4a9eff; border-color: #4a9eff; }}
}}
.search-box input {{
  width: 220px;
  padding: 4px 8px;
  font: inherit;
  border: 1px solid #8884;
  border-radius: 4px;
}}
.count-display {{ font-size: 12px; color: #666; align-self: center; }}
@media (prefers-color-scheme: dark) {{
  .count-display {{ color: #aaa; }}
}}
.table-wrap {{ overflow: auto; max-height: calc(100vh - 180px); border: 1px solid #8884; border-radius: 4px; }}
table {{ width: 100%; border-collapse: collapse; }}
th, td {{ padding: 3px 8px; text-align: left; border-bottom: 1px solid #8882; white-space: nowrap; }}
th {{ position: sticky; top: 0; background: Canvas; z-index: 1; font-size: 11px; text-transform: uppercase; }}
td.desc, td.src {{ white-space: normal; max-width: 280px; overflow: hidden; text-overflow: ellipsis; }}
.badge {{
  display: inline-block;
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
}}
.badge-added {{ background: #2a7; color: #fff; }}
.badge-overridden {{ background: #e80; color: #fff; }}
.badge-unchanged {{ background: #8884; color: inherit; }}
</style>
</head>
<body>
<header>
  <h1>Keybindings</h1>
  <div class="meta">
    <span>generated: {generated_at}</span>
    <span>commit: {commit}</span>
    {count_items}
    <span>{note}</span>
  </div>
</header>
<div class="controls">
  <div class="filter-group" id="tool-filters">
    <label>Tool</label>
    <div class="chips" data-filter="tool"></div>
  </div>
  <div class="filter-group" id="mode-filters">
    <label>Mode</label>
    <div class="chips" data-filter="mode"></div>
  </div>
  <div class="filter-group" id="origin-filters">
    <label>Origin</label>
    <div class="chips" data-filter="origin"></div>
  </div>
  <div class="search-box">
    <label for="search-input">Search</label><br>
    <input type="search" id="search-input" placeholder="key, action, description, source…" autocomplete="off">
  </div>
  <div class="count-display" id="count-display"></div>
</div>
<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Tool</th>
        <th>Mode</th>
        <th>Key</th>
        <th>Action</th>
        <th>Description</th>
        <th>Source</th>
        <th>Change</th>
      </tr>
    </thead>
    <tbody id="tbody"></tbody>
  </table>
</div>
<script>
const DATA = {data_json};
const TOOLS = ["wezterm", "zsh", "skhd", "nvim"];
const ORIGINS = ["custom", "default"];

function uniqueModes(records) {{
  const modes = new Set();
  for (const r of records) modes.add(r.mode);
  return Array.from(modes).sort();
}}

function parseHash() {{
  const params = new URLSearchParams(location.hash.slice(1));
  return {{
    tools: params.getAll("tool"),
    modes: params.getAll("mode"),
    origins: params.getAll("origin"),
    q: params.get("q") || "",
  }};
}}

function writeHash(state) {{
  const params = new URLSearchParams();
  for (const t of state.tools) params.append("tool", t);
  for (const m of state.modes) params.append("mode", m);
  for (const o of state.origins) params.append("origin", o);
  if (state.q) params.set("q", state.q);
  const hash = params.toString();
  location.hash = hash ? "#" + hash : "";
}}

function makeChip(label, group, value, active, onToggle) {{
  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "chip" + (active ? " active" : "");
  btn.textContent = label;
  btn.addEventListener("click", () => onToggle(value));
  return btn;
}}

function defaultState() {{
  return {{ tools: [], modes: [], origins: ["custom"], q: "" }};
}}

let state = defaultState();

function initChips() {{
  const toolContainer = document.querySelector('[data-filter="tool"]');
  const modeContainer = document.querySelector('[data-filter="mode"]');
  const originContainer = document.querySelector('[data-filter="origin"]');

  function renderToolChips() {{
    toolContainer.replaceChildren();
    for (const tool of TOOLS) {{
      const active = state.tools.length === 0 || state.tools.includes(tool);
      const selected = state.tools.includes(tool);
      toolContainer.appendChild(makeChip(tool, "tool", tool, selected || (state.tools.length === 0 && active), (v) => {{
        if (state.tools.length === 0) {{
          state.tools = TOOLS.filter((t) => t !== v);
        }} else if (state.tools.includes(v)) {{
          state.tools = state.tools.filter((t) => t !== v);
          if (state.tools.length === 0) state.tools = [];
        }} else {{
          state.tools = [...state.tools, v];
          if (state.tools.length === TOOLS.length) state.tools = [];
        }}
        writeHash(state);
        renderToolChips();
        applyFilters();
      }}));
    }}
  }}

  function renderModeChips() {{
    modeContainer.replaceChildren();
    const modes = uniqueModes(DATA);
    for (const mode of modes) {{
      const selected = state.modes.includes(mode);
      modeContainer.appendChild(makeChip(mode, "mode", mode, selected, (v) => {{
        if (state.modes.includes(v)) {{
          state.modes = state.modes.filter((m) => m !== v);
        }} else {{
          state.modes = [...state.modes, v];
        }}
        writeHash(state);
        renderModeChips();
        applyFilters();
      }}));
    }}
  }}

  function renderOriginChips() {{
    originContainer.replaceChildren();
    for (const origin of ORIGINS) {{
      const active = state.origins.length === 0 || state.origins.includes(origin);
      const selected = state.origins.includes(origin);
      originContainer.appendChild(makeChip(origin, "origin", origin, selected || (state.origins.length === 0 && active), (v) => {{
        if (state.origins.length === 0) {{
          state.origins = ORIGINS.filter((o) => o !== v);
        }} else if (state.origins.includes(v)) {{
          state.origins = state.origins.filter((o) => o !== v);
          if (state.origins.length === 0) state.origins = [];
        }} else {{
          state.origins = [...state.origins, v];
          if (state.origins.length === ORIGINS.length) state.origins = [];
        }}
        writeHash(state);
        renderOriginChips();
        applyFilters();
      }}));
    }}
  }}

  renderToolChips();
  renderModeChips();
  renderOriginChips();
}}

function matchesSearch(record, query) {{
  if (!query) return true;
  const hay = (record.key + " " + record.action + " " + record.description + " " + record.source).toLowerCase();
  return hay.includes(query);
}}

function recordPasses(record) {{
  if (state.tools.length > 0 && !state.tools.includes(record.tool)) return false;
  if (state.modes.length > 0 && !state.modes.includes(record.mode)) return false;
  if (state.origins.length > 0 && !state.origins.includes(record.origin)) return false;
  if (!matchesSearch(record, state.q.toLowerCase())) return false;
  return true;
}}

function badgeClass(change) {{
  if (change === "added") return "badge-added";
  if (change === "overridden") return "badge-overridden";
  return "badge-unchanged";
}}

function appendCell(row, text, className) {{
  const td = document.createElement("td");
  if (className) td.className = className;
  td.textContent = text;
  row.appendChild(td);
}}

function applyFilters() {{
  const tbody = document.getElementById("tbody");
  tbody.replaceChildren();
  let filtered = 0;
  for (const record of DATA) {{
    if (!recordPasses(record)) continue;
    filtered += 1;
    const row = document.createElement("tr");
    appendCell(row, record.tool);
    appendCell(row, record.mode);
    appendCell(row, record.key);
    appendCell(row, record.action);
    appendCell(row, record.description, "desc");
    appendCell(row, record.source, "src");
    const changeTd = document.createElement("td");
    const badge = document.createElement("span");
    badge.className = "badge " + badgeClass(record.change);
    badge.textContent = record.change;
    changeTd.appendChild(badge);
    row.appendChild(changeTd);
    tbody.appendChild(row);
  }}
  document.getElementById("count-display").textContent =
    filtered + " / " + DATA.length + " records";
}}

function loadFromHash() {{
  const parsed = parseHash();
  state = {{
    tools: parsed.tools,
    modes: parsed.modes,
    origins: parsed.origins.length > 0 ? parsed.origins : ["custom"],
    q: parsed.q,
  }};
  document.getElementById("search-input").value = state.q;
}}

document.getElementById("search-input").addEventListener("input", (e) => {{
  state.q = e.target.value;
  writeHash(state);
  applyFilters();
}});

window.addEventListener("hashchange", () => {{
  loadFromHash();
  initChips();
  applyFilters();
}});

loadFromHash();
initChips();
applyFilters();
</script>
</body>
</html>
"""
