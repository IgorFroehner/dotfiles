local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local style = require("helpers.style")
local ui = require("helpers.ui")

local POPUP_WIDTH = 200

local wifi = sbar.add("item", "widgets.wifi", {
	position = "right",
	padding_left = settings.item_padding,
	padding_right = settings.item_padding,
	label = { drawing = false },
	click_script = ui.menu_extra("Control Center,WiFi"),
})

local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", { wifi.name }, {
	popup = { align = "center" },
})

local ssid = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	padding_left = settings.popup_padding,
	padding_right = settings.popup_padding,
	width = POPUP_WIDTH,
	icon = {
		string = icons.wifi.router,
		padding_right = 16,
		font = style.font("icons", "Bold", settings.font.sizes.text),
	},
	label = {
		font = style.font("text", "Semibold"),
		max_chars = 25,
		string = "????????????",
	},
})

local hostname = ui.popup_row(wifi_bracket.name, "Hostname:", { width = POPUP_WIDTH, max_chars = 20 })
local ip = ui.popup_row(wifi_bracket.name, "IP:", { width = POPUP_WIDTH })
local router = ui.popup_row(wifi_bracket.name, "Router:", { width = POPUP_WIDTH })

-- macOS redacts the SSID from ipconfig/system_profiler; the SSID helper app reads it with
-- Location Services permission. It's launched through `open` so the permission is its own.
local SSID_CMD = 'F=$(mktemp); open -W -n --stdout "$F" "$CONFIG_DIR/helpers/ssid/bin/SSID.app"; cat "$F"; rm -f "$F"'

-- Each popup row and the command that fills it
local details = {
	{ ssid, SSID_CMD },
	{ hostname, "networksetup -getcomputername" },
	{ ip, "ipconfig getifaddr en0" },
	{ router, "networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'" },
}

wifi:subscribe({ "wifi_change", "system_woke", "forced" }, function()
	sbar.exec("ipconfig getifaddr en0", function(ip_address)
		local connected = ip_address ~= ""
		wifi:set({
			icon = {
				string = connected and icons.wifi.connected or icons.wifi.disconnected,
				color = connected and colors.white or colors.red,
			},
		})
	end)
end)

wifi:subscribe("mouse.entered", function()
	if not ui.show_popup(wifi_bracket) then
		return
	end
	for _, detail in ipairs(details) do
		local item, cmd = detail[1], detail[2]
		sbar.exec(cmd, function(result)
			item:set({ label = (result:gsub("\n$", "")) })
		end)
	end
end)

wifi:subscribe("mouse.exited.global", function()
	ui.hide_popup(wifi_bracket)
end)

-- Click a row to copy its value
for _, detail in ipairs(details) do
	local item = detail[1]
	item:subscribe("mouse.clicked", function()
		local label = item:query().label
		local value, align = label.value, label.align
		sbar.exec("printf %s '" .. value:gsub("'", "'\\''") .. "' | pbcopy")
		item:set({ label = { string = icons.clipboard, align = "center" } })
		sbar.delay(1, function()
			item:set({ label = { string = value, align = align } })
		end)
	end)
end
