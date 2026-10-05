local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local style = require("helpers.style")
local ui = require("helpers.ui")

local battery = sbar.add("item", "widgets.battery", {
	position = "right",
	update_freq = 120,
	padding_right = settings.item_padding,
	padding_left = settings.item_padding,
	popup = { align = "center" },
	label = {
		padding_left = settings.item_padding,
		font = style.font("numbers", "Regular"),
	},
	click_script = ui.menu_extra("Control Center,Battery"),
})

local remaining_time = sbar.add("item", {
	position = "popup." .. battery.name,
	label = {
		font = style.font("numbers", "Regular"),
		string = "??:??h",
		padding_right = settings.item_padding,
		padding_left = settings.item_padding,
	},
})

-- Returns charge (number or nil), whether on AC power, and the "h:mm" remaining (or nil)
local function parse_pmset(info)
	local charge = tonumber(info:match("(%d+)%%"))
	local remaining = info:match(" (%d+:%d+) remaining")
	return charge, info:find("AC Power") ~= nil, remaining
end

local function battery_icon(charge, charging)
	if charging then
		return icons.battery.charging, colors.green
	elseif not charge then
		return icons.battery._0, colors.red
	elseif charge > 80 then
		return icons.battery._100, colors.white
	elseif charge > 60 then
		return icons.battery._75, colors.white
	elseif charge > 40 then
		return icons.battery._50, colors.white
	elseif charge > 20 then
		return icons.battery._25, colors.orange
	end
	return icons.battery._0, colors.red
end

battery:subscribe({ "routine", "forced", "power_source_change", "system_woke" }, function()
	sbar.exec("pmset -g batt", function(info)
		local charge, charging = parse_pmset(info)
		local icon, color = battery_icon(charge, charging)
		battery:set({
			icon = { string = icon, color = color },
			label = charge and string.format("%02d%%", charge) or "?",
		})
	end)
end)

battery:subscribe("mouse.entered", function()
	ui.show_popup(battery)
	sbar.exec("pmset -g batt", function(info)
		local charge, _, remaining = parse_pmset(info)
		local charge_label = charge and charge .. "%" or "Unknown"
		local time_label = remaining and remaining:gsub(":", ".") .. "hrs" or "00:00"
		remaining_time:set({ label = time_label .. " Remaining (" .. charge_label .. ")" })
	end)
end)

battery:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	ui.hide_popup(battery)
end)
