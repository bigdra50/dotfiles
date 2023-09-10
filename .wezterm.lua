local wezterm = require 'wezterm';

local config = {
  check_for_updates = true,
  font = wezterm.font("Hack Nerd Font", {weight="Regular", stretch="Normal", style="Normal"}),
  font_size = 11.0,
  hide_tab_bar_if_only_one_tab = true,
  window_decorations = "RESIZE",
  window_background_opacity = 0.85,
  launch_menu = {  },
  default_prog = {  },
  leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 2000 },
  keys = {
    { key = '"', mods = 'LEADER', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = '%', mods = 'LEADER', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = "c", mods = "LEADER",       action=wezterm.action{SpawnTab="CurrentPaneDomain"}},
    { key = "m", mods = "LEADER",       action=wezterm.action.ShowLauncher},
    { key = "s", mods = "LEADER",       action=wezterm.action{SplitVertical={domain="CurrentPaneDomain"}}},
    { key = "v", mods = "LEADER",       action=wezterm.action{SplitHorizontal={domain="CurrentPaneDomain"}}},
    { key = "h", mods = "LEADER",       action=wezterm.action{ActivatePaneDirection="Left"}},
    { key = "j", mods = "LEADER",       action=wezterm.action{ActivatePaneDirection="Down"}},
    { key = "k", mods = "LEADER",       action=wezterm.action{ActivatePaneDirection="Up"}},
    { key = "l", mods = "LEADER",       action=wezterm.action{ActivatePaneDirection="Right"}},
    { key = "H", mods = "LEADER|SHIFT", action=wezterm.action{AdjustPaneSize={"Left", 5}}},
    { key = "J", mods = "LEADER|SHIFT", action=wezterm.action{AdjustPaneSize={"Down", 5}}},
    { key = "K", mods = "LEADER|SHIFT", action=wezterm.action{AdjustPaneSize={"Up", 5}}},
    { key = "L", mods = "LEADER|SHIFT", action=wezterm.action{AdjustPaneSize={"Right", 5}}},
    { key = "1", mods = "LEADER",       action=wezterm.action{ActivateTab=0}},
    { key = "2", mods = "LEADER",       action=wezterm.action{ActivateTab=1}},
    { key = "3", mods = "LEADER",       action=wezterm.action{ActivateTab=2}},
    { key = "4", mods = "LEADER",       action=wezterm.action{ActivateTab=3}},
    { key = "5", mods = "LEADER",       action=wezterm.action{ActivateTab=4}},
    { key = "6", mods = "LEADER",       action=wezterm.action{ActivateTab=5}},
    { key = "7", mods = "LEADER",       action=wezterm.action{ActivateTab=6}},
    { key = "8", mods = "LEADER",       action=wezterm.action{ActivateTab=7}},
    { key = "9", mods = "LEADER",       action=wezterm.action{ActivateTab=8}},
    { key = "&", mods = "LEADER|SHIFT", action=wezterm.action{CloseCurrentTab={confirm=true}}},
    { key = "x", mods = "LEADER", action = wezterm.action{CloseCurrentPane={confirm=true}}},
  },
}

local mux = wezterm.mux
wezterm.on("gui-startup", function()
  local tab, pane, window = mux.spawn_window{}
  window:gui_window():maximize()
end)

-- for Windows
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.default_prog = {
    os.getenv("LOCALAPPDATA") ..
    "\\Microsoft\\WindowsApps\\ubuntu.exe"
  };
  config.launch_menu = {
    {
      label = "PowerShell7",
      args = {
        os.getenv("PROGRAMFILES").."\\PowerShell\\7\\pwsh.exe", 
        "-NoLogo"
      }
    }
  }
elseif wezterm.target_triple == "darwin" then
  config.default_prog = {
    "usr/bin/zsh"
  }
end


--    config.term = "" -- Set to empty so FZF works on windows
--    table.insert(config.launch_menu, { label = "PowerShell", args = {"C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo"} })
--
--    -- Find installed visual studio version(s) and add their compilation
--    -- environment command prompts to the menu
--    for _, vsvers in ipairs(wezterm.glob("Microsoft Visual Studio/22*", "C:/Program Files (x86)")) do
--        local year = vsvers:gsub("Microsoft Visual Studio/", "")
--        table.insert(config.launch_menu, {
--            label = "x64 Native Tools VS " .. year,
--            args = {"cmd.exe", "/k", "C:/Program Files (x86)/" .. vsvers .. "/BuildTools/VC/Auxiliary/Build/vcvars64.bat"},
--        })
--    end
--else
--    table.insert(config.launch_menu, { label = "bash", args = {"bash", "-l"} })
--end

return config
