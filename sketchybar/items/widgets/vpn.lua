local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local ui = require("helpers.ui")

local POPUP_WIDTH = 220

-- Hidden while no VPN is up; updates = "on" keeps the routine running while hidden
local vpn = sbar.add("item", "widgets.vpn", {
	position = "right",
	drawing = false,
	update_freq = 5,
	updates = "on",
	padding_left = settings.item_padding,
	padding_right = settings.item_padding,
	popup = { align = "center" },
	icon = { string = icons.vpn, color = colors.green },
	label = { drawing = false },
	click_script = "open -a Pritunl",
})

local profile = ui.popup_row(vpn.name, "Profile:", { width = POPUP_WIDTH, max_chars = 18 })
local interface = ui.popup_row(vpn.name, "Interface:", { width = POPUP_WIDTH })
local ip = ui.popup_row(vpn.name, "IP:", { width = POPUP_WIDTH })
local server = ui.popup_row(vpn.name, "Server:", { width = POPUP_WIDTH })
local uptime = ui.popup_row(vpn.name, "Uptime:", { width = POPUP_WIDTH })
local pritunl_rows = { profile, server, uptime }

-- Any VPN client (OpenVPN, WireGuard, ...) brings up a utun interface with an IPv4
-- address; the ones macOS keeps up on its own (iCloud and the like) have none.
-- Prints "utunN address" for each.
local TUNNELS_CMD = [[ifconfig | awk '/^[a-z]/ {iface = ($1 ~ /^utun/) ? $1 : ""} ]]
	.. [[iface && /inet / {sub(":", "", iface); print iface, $2}']]

-- Pritunl's background service answers on a local socket with every profile that is
-- connecting or connected, keyed by profile id (the GUI talks to the same API)
local PRITUNL_CMD = "S=/var/run/pritunl.sock; [ -S $S ] && curl -s --max-time 2 --unix-socket $S "
	.. '-H "Auth-Key: $(cat /var/run/pritunl.auth)" -H "User-Agent: pritunl" http://unix/profile'

local PRITUNL_PROFILES = '"$HOME/Library/Application Support/pritunl/profiles/'

-- Latest state, read by the popup
local tunnel = nil -- { iface = ..., address = ... }
local pritunl = nil -- the Pritunl service's profile entry, plus its id

-- The connected profile, or else one still connecting
local function pick_profile(profiles)
	if type(profiles) ~= "table" then
		return nil
	end
	local picked = nil
	for id, entry in pairs(profiles) do
		if type(entry) == "table" and (entry.status == "connected" or not picked) then
			picked = entry
			picked.id = id
		end
	end
	return picked
end

local function format_uptime(timestamp)
	local seconds = math.max(0, os.time() - timestamp)
	local hours, minutes = seconds // 3600, seconds % 3600 // 60
	if hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	end
	return string.format("%dm", minutes)
end

local function show_details()
	if not ui.show_popup(vpn) then
		return
	end
	interface:set({ label = tunnel and tunnel.iface or "-" })
	ip:set({ label = tunnel and tunnel.address or (pritunl and pritunl.client_addr and pritunl.client_addr:gsub("/%d+$", "")) or "-" })

	for _, row in ipairs(pritunl_rows) do
		row:set({ drawing = pritunl ~= nil })
	end
	if not pritunl then
		return
	end
	server:set({ label = (pritunl.server_addr or "") ~= "" and pritunl.server_addr or "-" })
	uptime:set({
		label = pritunl.status == "connected" and pritunl.timestamp and format_uptime(pritunl.timestamp)
			or "Connecting…",
	})
	profile:set({ label = "…" })
	-- Profile ids are hex; skip anything else rather than splice it into a command
	if pritunl.id:match("^[%w-]+$") then
		sbar.exec(
			"grep -o '\"name\": *\"[^\"]*\"' " .. PRITUNL_PROFILES .. pritunl.id .. ".conf\" | head -1 | cut -d'\"' -f4",
			function(name)
				name = tostring(name):gsub("\n$", "")
				profile:set({ label = name ~= "" and name or "-" })
			end
		)
	end
end

local function hide_details()
	ui.hide_popup(vpn)
end

local function update()
	sbar.exec(TUNNELS_CMD, function(tunnels)
		local iface, address = tunnels:match("^(%S+) (%S+)")
		tunnel = iface and { iface = iface, address = address } or nil
		sbar.exec(PRITUNL_CMD, function(profiles)
			pritunl = pick_profile(profiles)
			local connected = tunnel ~= nil or (pritunl ~= nil and pritunl.status == "connected")
			local connecting = not connected and pritunl ~= nil
			vpn:set({
				drawing = connected or connecting,
				icon = { color = connected and colors.green or colors.yellow },
			})
			if not (connected or connecting) and ui.is_open(vpn) then
				hide_details()
			end
		end)
	end)
end

vpn:subscribe({ "routine", "forced", "wifi_change", "system_woke" }, update)

ui.hover_popup(vpn, vpn, show_details, hide_details)
for _, row in ipairs({ profile, interface, ip, server, uptime }) do
	ui.hover_keep_open(vpn, row, hide_details)
end
