local wezterm = require("wezterm")
local act = wezterm.action

-- Helper functions
local function is_windows()
  return wezterm.target_triple == "x86_64-pc-windows-msvc"
end

local function is_mac()
  return wezterm.target_triple == "x86_64-apple-darwin" or
         wezterm.target_triple == "aarch64-apple-darwin"
end

local function is_linux()
  return wezterm.target_triple == "x86_64-unknown-linux-gnu" or
         wezterm.target_triple == "aarch64-unknown-linux-gnu"
end

-- Font setup
local function setup_fonts()
  -- List of fonts in order of preference
  local font_list = {
    "Hack Nerd Font",
    -- OS-specific fallback fonts
    is_windows() and "Consolas" or nil,
    is_mac() and "Menlo" or nil,
    is_linux() and "DejaVu Sans Mono" or nil,
    -- Final fallback
    "monospace"
  }
  
  -- Our first choice font
  local preferred_font = "Hack Nerd Font"
  local used_font = nil
  
  -- Try each font in the list
  for _, font in ipairs(font_list) do
    if font then
      -- Check if font exists
      local success, _ = pcall(function() 
        return wezterm.font(font)
      end)
      
      if success then
        used_font = font
        break
      end
    end
  end
  
  -- Use default if no font was found
  if not used_font then
    used_font = "monospace"
  end
  
  -- Log font fallback information
  if used_font ~= preferred_font then
    wezterm.log_info(string.format("Font '%s' not found, using '%s' instead", preferred_font, used_font))
  else
    wezterm.log_info(string.format("Using preferred font: %s", preferred_font))
  end
  
  return wezterm.font(used_font, {weight="Regular", stretch="Normal", style="Normal"})
end

-- Basic config
local config = {}

-- Config initialization function
local function initialize_config()
  config = {
    check_for_updates = true,
    font = setup_fonts(),
    font_size = 13.0,
    window_background_opacity = 0.8,
    -- hide_tab_bar_if_only_one_tab = false, -- Commented out setting
    launch_menu = {},
  }
  
  -- Leader key setting
  config.leader = { 
    key = 'a', 
    mods = 'CTRL', 
    timeout_milliseconds = 2000 
  }
  
  -- Key bindings
  config.keys = {
    -- Split operations
    { key = '"', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = '%', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = "s", mods = "LEADER", action = act{SplitVertical={domain="CurrentPaneDomain"}} },
    { key = "v", mods = "LEADER", action = act{SplitHorizontal={domain="CurrentPaneDomain"}} },
    
    -- Tab operations
    { key = "c", mods = "LEADER", action = act{SpawnTab="CurrentPaneDomain"} },
    
    -- Pane navigation
    { key = "h", mods = "LEADER", action = act{ActivatePaneDirection="Left"} },
    { key = "j", mods = "LEADER", action = act{ActivatePaneDirection="Down"} },
    { key = "k", mods = "LEADER", action = act{ActivatePaneDirection="Up"} },
    { key = "l", mods = "LEADER", action = act{ActivatePaneDirection="Right"} },
    
    -- Pane resizing
    { key = "H", mods = "LEADER|SHIFT", action = act{AdjustPaneSize={"Left", 5}} },
    { key = "J", mods = "LEADER|SHIFT", action = act{AdjustPaneSize={"Down", 5}} },
    { key = "K", mods = "LEADER|SHIFT", action = act{AdjustPaneSize={"Up", 5}} },
    { key = "L", mods = "LEADER|SHIFT", action = act{AdjustPaneSize={"Right", 5}} },
    
    -- Tab switching
    { key = "1", mods = "LEADER", action = act{ActivateTab=0} },
    { key = "2", mods = "LEADER", action = act{ActivateTab=1} },
    { key = "3", mods = "LEADER", action = act{ActivateTab=2} },
    { key = "4", mods = "LEADER", action = act{ActivateTab=3} },
    { key = "5", mods = "LEADER", action = act{ActivateTab=4} },
    { key = "6", mods = "LEADER", action = act{ActivateTab=5} },
    { key = "7", mods = "LEADER", action = act{ActivateTab=6} },
    { key = "8", mods = "LEADER", action = act{ActivateTab=7} },
    { key = "9", mods = "LEADER", action = act{ActivateTab=8} },
    
    -- Close operations
    { key = "&", mods = "LEADER|SHIFT", action = act{CloseCurrentTab={confirm=true}} },
    { key = "x", mods = "LEADER", action = act{CloseCurrentPane={confirm=true}} },
    
    -- Show logs shortcut
    { key = "l", mods = "LEADER|ALT", action = act.ShowDebugOverlay },
  }
  
  -- OS-specific settings
  if is_windows() then
    -- Windows settings
    
    -- Set default shell to PowerShell
    config.default_prog = {"pwsh.exe", "-NoLogo"}
    --config.default_domain = 'WSL:Ubuntu'
    
    -- Add PowerShell 7 if available
    table.insert(config.launch_menu, { 
      label = "PowerShell 7", 
      args = {"C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo"} 
    })
  
    -- Add Visual Studio developer environments
    for _, vsvers in ipairs(wezterm.glob("Microsoft Visual Studio/20*", "C:/Program Files (x86)")) do
      local year = vsvers:gsub("Microsoft Visual Studio/", "")
      table.insert(config.launch_menu, {
        label = "x64 Native Tools VS " .. year,
        args = {"cmd.exe", "/k", "C:/Program Files (x86)/" .. vsvers .. "/BuildTools/VC/Auxiliary/Build/vcvars64.bat"},
      })
    end
  elseif is_mac() then
    -- macOS settings
    -- Set default shell to zsh
    config.default_prog = {"zsh", "-l"}
    
    -- Add other shell options
    table.insert(config.launch_menu, { label = "bash", args = {"bash", "-l"} })
    table.insert(config.launch_menu, { label = "fish", args = {"fish", "-l"} })
    table.insert(config.launch_menu, { label = "zsh", args = {"zsh", "-l"} })
  else
    -- Linux (Ubuntu) settings
    -- Set default shell to zsh
    config.default_prog = {"zsh", "-l"}
    
    -- Add other shell options
    table.insert(config.launch_menu, { label = "bash", args = {"bash", "-l"} })
    table.insert(config.launch_menu, { label = "fish", args = {"fish", "-l"} })
  end
  
  -- Add font-related commands to launch menu
  local font_info_command = "echo 'Current font: ' && fc-match monospace"
  if is_windows() then
    font_info_command = "echo Current font configuration"
  elseif is_mac() then
    font_info_command = "echo 'Current system fonts:' && system_profiler SPFontsDataType | grep -i monospace -A 3"
  end
  
  table.insert(config.launch_menu, {
    label = "Show Font Info",
    args = {"bash", "-c", font_info_command}
  })
  
  -- Command to show Hack Nerd Font installation instructions
  local install_font_help = [[
echo 'To install Hack Nerd Font:

On Windows:
- Download from https://github.com/ryanoasis/nerd-fonts/releases
- Extract and install TTF files

On macOS:
- brew tap homebrew/cask-fonts
- brew install --cask font-hack-nerd-font

On Ubuntu:
- sudo apt install fonts-hack-ttf
- Or manual install from GitHub repo
'
]]
  
  table.insert(config.launch_menu, {
    label = "Hack Nerd Font Install Help",
    args = {"bash", "-c", install_font_help}
  })
  
  -- Add keyboard shortcut for log viewer instead of launch menu item
  table.insert(config.keys, {
    key = "D",
    mods = "LEADER|SHIFT",
    action = act.ShowDebugOverlay,
  })
  
  return config
end

-- Initialize and return config
initialize_config()
return config
