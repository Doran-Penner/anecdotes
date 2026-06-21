-- thank you to https://github.com/wez/wezterm/issues/2854
-- see lower note
local extract_tab_bar_colors_from_theme = function(theme_name)
	local wez_theme = wezterm.color.get_builtin_schemes()[theme_name]
	return {
		window_frame_colors = {
			active_titlebar_bg = wez_theme.background,
			inactive_titlebar_bg = wez_theme.background,
		},
		tab_bar = wez_theme.tab_bar	-- hurray catppuccin devs!
	}
end

function get_appearance()
	if wezterm.gui then
		return wezterm.gui.get_appearance()
	end
	return 'Dark'
end

function scheme_for_appearance(appearance)
	if appearance:find 'Light' then
		return 'Catppuccin Frappe'
	else
		return 'Catppuccin Mocha'	-- do I want this?
	end
end

--[[
	A note on themes:
	This simplified config will only work with themes that define tab_bar
	which is true for all Catppuccin themes but not everything!
]]--

local my_theme = scheme_for_appearance(get_appearance())

local tab_bar_theme = extract_tab_bar_colors_from_theme(my_theme)

return {
	color_scheme = my_theme,
	colors = { tab_bar = tab_bar_theme.tab_bar, },
	window_frame = tab_bar_theme.window_frame_colors,
	warn_about_missing_glyphs = false,
}
