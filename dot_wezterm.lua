local wezterm = require("wezterm")
local config = {
  check_for_updates = true,
  font = wezterm.font("Hack Nerd Font", {weight="Regular", stretch="Normal", style="Normal"}),
  font_size = 11.0,
  launch_menu = {},
}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    config.term = "" -- Set to empty so FZF works on windows
    table.insert(config.launch_menu, { label = "PowerShell", args = {"C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo"} })

    -- Find installed visual studio version(s) and add their compilation
    -- environment command prompts to the menu
    for _, vsvers in ipairs(wezterm.glob("Microsoft Visual Studio/20*", "C:/Program Files (x86)")) do
        local year = vsvers:gsub("Microsoft Visual Studio/", "")
        table.insert(config.launch_menu, {
            label = "x64 Native Tools VS " .. year,
            args = {"cmd.exe", "/k", "C:/Program Files (x86)/" .. vsvers .. "/BuildTools/VC/Auxiliary/Build/vcvars64.bat"},
        })
    end
else
    table.insert(config.launch_menu, { label = "bash", args = {"bash", "-l"} })
    table.insert(config.launch_menu, { label = "fish", args = {"fish", "-l"} })
end

return config
