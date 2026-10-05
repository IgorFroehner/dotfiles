local settings = require("settings")
local style = require("helpers.style")

local ui = {}

local MENUS_BIN = "$CONFIG_DIR/helpers/menus/bin/menus"
local PANEL_BIN = "$CONFIG_DIR/helpers/panels/bin/sbar_panel"

-- Fixed-width gap between item groups.
function ui.spacer(name, position)
	return sbar.add("item", name, {
		position = position,
		width = settings.item_spacing,
		background = { drawing = false },
	})
end

-- click_script that clicks a macOS menu bar extra, e.g. "Control Center,WiFi".
function ui.menu_extra(alias)
	return MENUS_BIN .. " -s '" .. alias .. "'"
end

-- Open the given Swift panel ("menu" or "date"), or close it if it is already open.
-- The panel closes itself on clicks outside of it and of the item that opened it.
-- The [s] in the pattern and the $P indirection keep pkill from matching the
-- shell running this command.
function ui.toggle_panel(panel)
	-- The calendar panel reads the weather location from WEATHER_CITY
	local city = (settings.weather_city or ""):gsub("'", "'\\''")
	sbar.exec(
		"P="
			.. PANEL_BIN
			.. "; pkill -f '[s]bar_panel app="
			.. panel
			.. "' || WEATHER_CITY='"
			.. city
			.. "' $P app="
			.. panel
			.. " >/dev/null 2>&1 &"
	)
end

-- Hover popups: only one is open at a time, so sweeping the mouse across the
-- widgets doesn't leave a stack of them behind.
local open_popup = nil

-- Opens `item`'s popup and closes any other. Returns false if it was already open.
function ui.show_popup(item)
	if open_popup == item then
		return false
	end
	if open_popup then
		open_popup:set({ popup = { drawing = false } })
	end
	open_popup = item
	item:set({ popup = { drawing = true } })
	return true
end

function ui.hide_popup(item)
	item:set({ popup = { drawing = false } })
	if open_popup == item then
		open_popup = nil
	end
end

-- A "Title:      value" row inside a popup.
function ui.popup_row(parent, title, opts)
	opts = opts or {}
	local width = opts.width or 200
	return sbar.add("item", {
		position = "popup." .. parent,
		padding_left = settings.popup_padding,
		padding_right = settings.popup_padding,
		width = width,
		icon = {
			align = "left",
			string = title,
			width = width / 2,
			font = style.font("icons", "Bold", settings.font.sizes.text),
		},
		label = {
			font = style.font("text", "Regular"),
			max_chars = opts.max_chars,
			string = opts.placeholder or "???",
			width = width / 2,
			align = "right",
		},
	})
end

return ui
