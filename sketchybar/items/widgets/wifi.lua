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
local download = ui.popup_row(wifi_bracket.name, "Download:", { width = POPUP_WIDTH })
local upload = ui.popup_row(wifi_bracket.name, "Upload:", { width = POPUP_WIDTH })

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

-- Bytes in and out of en0 since boot
local TRAFFIC_CMD = "netstat -ibn -I en0 | awk '/<Link/ {print $7, $10; exit}'"
local TRAFFIC_INTERVAL = 1

local function format_bytes(bytes)
	local units = { "B", "KB", "MB", "GB", "TB" }
	local unit = 1
	while bytes >= 1024 and unit < #units do
		bytes = bytes / 1024
		unit = unit + 1
	end
	if unit == 1 then
		return string.format("%d %s", math.floor(bytes), units[unit])
	end
	return string.format("%.1f %s", bytes, units[unit])
end

-- Samples the counters every TRAFFIC_INTERVAL while the popup is open; speeds are
-- the difference between two samples. Each opening starts a new generation so a
-- loop left over from a quick close and reopen stops instead of running twice.
local traffic_generation = 0

local function poll_traffic(generation, previous_in, previous_out)
	if generation ~= traffic_generation or not ui.is_open(wifi_bracket) then
		return
	end
	sbar.exec(TRAFFIC_CMD, function(result)
		local bytes_in, bytes_out = result:match("(%d+)%s+(%d+)")
		bytes_in, bytes_out = tonumber(bytes_in), tonumber(bytes_out)
		if bytes_in and previous_in then
			download:set({ label = format_bytes(math.max(0, bytes_in - previous_in) / TRAFFIC_INTERVAL) .. "/s" })
			upload:set({ label = format_bytes(math.max(0, bytes_out - previous_out) / TRAFFIC_INTERVAL) .. "/s" })
		end
		sbar.delay(TRAFFIC_INTERVAL, function()
			poll_traffic(generation, bytes_in, bytes_out)
		end)
	end)
end

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

local function show_details()
	if not ui.show_popup(wifi_bracket) then
		return
	end
	for _, detail in ipairs(details) do
		local item, cmd = detail[1], detail[2]
		sbar.exec(cmd, function(result)
			item:set({ label = (result:gsub("\n$", "")) })
		end)
	end
	download:set({ label = "…" })
	upload:set({ label = "…" })
	traffic_generation = traffic_generation + 1
	poll_traffic(traffic_generation)
end

local function hide_details()
	ui.hide_popup(wifi_bracket)
end

ui.hover_popup(wifi_bracket, wifi, show_details, hide_details)
for _, item in ipairs({ download, upload }) do
	ui.hover_keep_open(wifi_bracket, item, hide_details)
end

-- Click a row to copy its value
for _, detail in ipairs(details) do
	local item = detail[1]
	ui.hover_keep_open(wifi_bracket, item, hide_details)
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
