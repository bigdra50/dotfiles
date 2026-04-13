local wezterm = require("wezterm")

-- ファイル存在チェック
local function file_exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

-- dotfiles内の画像パス（シンボリックリンク経由でも正しく解決）
local home = os.getenv("HOME") or os.getenv("USERPROFILE")
local dotfiles_dir = home .. "/dev/github.com/bigdra50/dotfiles"
local bg_image = dotfiles_dir .. "/wezterm/images/ztmy.jpg"

-- Claude Code通知: bellイベントでタスク完了をトースト通知
wezterm.on("bell", function(window, pane)
	-- ペインの作業ディレクトリからプロジェクト名を取得（OSC 7未設定ならnil）
	local cwd = pane:get_current_working_dir()
	local project_name = "不明"
	if cwd and cwd.file_path then
		project_name = cwd.file_path:match("([^/]+)/?$") or "不明"
	end
	local time = wezterm.strftime("%H:%M:%S")

	local title = "Claude Code - タスク完了"
	local message = string.format("プロジェクト: %s\n時刻: %s", project_name, time)

	window:toast_notification(title, message, nil, 5000)
end)

local config = {
	check_for_updates = true,
	audible_bell = "SystemBeep", -- システムベル音も鳴らす
	font = wezterm.font_with_fallback({
		"Hack Nerd Font",
		"Hiragino Sans",
		"Hiragino Mincho ProN",
		"Noto Sans CJK JP",
	}),
	font_size = 13.0,
	window_background_opacity = 0.8,
	launch_menu = {},
	--hide_tab_bar_if_onely_one_tab = false,
	leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 },
	keys = {
		{ key = '"', mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "%", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "c", mods = "LEADER", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
		{ key = "s", mods = "LEADER", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
		{ key = "v", mods = "LEADER", action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },
		{ key = "h", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Left" }) },
		{ key = "j", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Down" }) },
		{ key = "k", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Up" }) },
		{ key = "l", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Right" }) },
		{ key = "H", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Left", 5 } }) },
		{ key = "J", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Down", 5 } }) },
		{ key = "K", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Up", 5 } }) },
		{ key = "L", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Right", 5 } }) },
		{ key = "1", mods = "LEADER", action = wezterm.action({ ActivateTab = 0 }) },
		{ key = "2", mods = "LEADER", action = wezterm.action({ ActivateTab = 1 }) },
		{ key = "3", mods = "LEADER", action = wezterm.action({ ActivateTab = 2 }) },
		{ key = "4", mods = "LEADER", action = wezterm.action({ ActivateTab = 3 }) },
		{ key = "5", mods = "LEADER", action = wezterm.action({ ActivateTab = 4 }) },
		{ key = "6", mods = "LEADER", action = wezterm.action({ ActivateTab = 5 }) },
		{ key = "7", mods = "LEADER", action = wezterm.action({ ActivateTab = 6 }) },
		{ key = "8", mods = "LEADER", action = wezterm.action({ ActivateTab = 7 }) },
		{ key = "9", mods = "LEADER", action = wezterm.action({ ActivateTab = 8 }) },
		{ key = "&", mods = "LEADER|SHIFT", action = wezterm.action({ CloseCurrentTab = { confirm = true } }) },
		{ key = "x", mods = "LEADER", action = wezterm.action({ CloseCurrentPane = { confirm = true } }) },
		-- ペイン入れ替え: ラベル選択したペインとスワップ
		{ key = "o", mods = "LEADER", action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }) },
		-- 全ペインを時計回りに回転
		{ key = "r", mods = "LEADER", action = wezterm.action.RotatePanes("Clockwise") },
		-- 現在のペインを新しいタブへ分離（tmux の break-pane 相当）
		{
			key = "!",
			mods = "LEADER|SHIFT",
			action = wezterm.action_callback(function(_, pane)
				pane:move_to_new_tab():activate()
			end),
		},
		-- タブを左右に移動
		{ key = "<", mods = "LEADER|SHIFT", action = wezterm.action.MoveTabRelative(-1) },
		{ key = ">", mods = "LEADER|SHIFT", action = wezterm.action.MoveTabRelative(1) },
	},
}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.term = "" -- Set to empty so FZF works on windows
	table.insert(
		config.launch_menu,
		{ label = "PowerShell", args = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" } }
	)

	-- Find installed visual studio version(s) and add their compilation
	-- environment command prompts to the menu
	for _, vsvers in ipairs(wezterm.glob("Microsoft Visual Studio/20*", "C:/Program Files (x86)")) do
		local year = vsvers:gsub("Microsoft Visual Studio/", "")
		table.insert(config.launch_menu, {
			label = "x64 Native Tools VS " .. year,
			args = {
				"cmd.exe",
				"/k",
				"C:/Program Files (x86)/" .. vsvers .. "/BuildTools/VC/Auxiliary/Build/vcvars64.bat",
			},
		})
	end
else
	table.insert(config.launch_menu, { label = "bash", args = { "bash", "-l" } })
	table.insert(config.launch_menu, { label = "fish", args = { "fish", "-l" } })
end

-- 背景画像設定（画像が存在する場合のみ）
if file_exists(bg_image) then
	config.background = {
		{
			source = { File = bg_image },
			opacity = 0.3,
			hsb = { brightness = 0.1 },
		},
		{
			source = { Color = "#1a1b26" },
			width = "100%",
			height = "100%",
			opacity = 0.85,
		},
	}
end

return config
