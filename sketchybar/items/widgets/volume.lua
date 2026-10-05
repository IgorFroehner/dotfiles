local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local ui = require("helpers.ui")

local POPUP_WIDTH = 250

local volume = sbar.add("item", "widgets.volume", {
	position = "right",
	padding_right = settings.item_padding - 3.0,
	padding_left = settings.item_padding,
	icon = {
		width = settings.item_height + settings.item_spacing,
		align = "center",
	},
})

local volume_bracket = sbar.add("bracket", "widgets.volume.bracket", { volume.name }, {
	popup = { align = "center" },
})

local slider = sbar.add("slider", "widgets.volume.slider", POPUP_WIDTH, {
	position = "popup." .. volume_bracket.name,
	width = POPUP_WIDTH,
	padding_right = settings.popup_padding,
	padding_left = settings.popup_padding,
	background = {
		height = 80,
		y_offset = 20,
	},
	slider = {
		highlight_color = colors.quicksilver,
		background = {
			height = 6,
			corner_radius = 3,
			color = colors.bg2,
		},
		knob = {
			string = icons.slider_knob,
			drawing = true,
		},
	},
	click_script = 'osascript -e "set volume output volume $PERCENTAGE"',
})

local function volume_icon(level)
	if level > 60 then
		return icons.volume._100, colors.white
	elseif level > 30 then
		return icons.volume._66, colors.white
	elseif level > 10 then
		return icons.volume._33, colors.white
	elseif level > 0 then
		return icons.volume._10, colors.white
	end
	return icons.volume._0, colors.grey
end

volume:subscribe("volume_change", function(env)
	local level = tonumber(env.INFO)
	local icon, color = volume_icon(level)
	volume:set({ icon = { string = icon, color = color } })
	slider:set({ slider = { percentage = level } })
end)

-- Output devices are listed in the popup and rebuilt every time it opens
local device_items = {}
local hide_details

local function clear_devices()
	for _, item in ipairs(device_items) do
		sbar.remove(item.name)
	end
	device_items = {}
end

local function select_device(device, item)
	sbar.exec('SwitchAudioSource -t output -s "' .. device:gsub('"', '\\"') .. '"', function()
		for _, other in ipairs(device_items) do
			other:set({ label = { color = colors.quicksilver } })
		end
		item:set({ label = { color = colors.white } })
	end)
end

local function list_devices()
	clear_devices()
	sbar.exec("SwitchAudioSource -t output -c", function(current)
		current = current:gsub("\n$", "")
		sbar.exec("SwitchAudioSource -a -t output", function(available)
			for device in available:gmatch("[^\r\n]+") do
				local item = sbar.add("item", "volume.device." .. #device_items, {
					position = "popup." .. volume_bracket.name,
					padding_right = settings.popup_padding,
					padding_left = settings.popup_padding,
					y_offset = 8,
					width = POPUP_WIDTH,
					label = {
						string = device,
						color = device == current and colors.white or colors.quicksilver,
					},
				})
				item:subscribe("mouse.clicked", function()
					select_device(device, item)
				end)
				ui.hover_keep_open(volume_bracket, item, hide_details)
				table.insert(device_items, item)
			end
		end)
	end)
end

local function show_details()
	if not ui.show_popup(volume_bracket) then
		return
	end
	list_devices()
end

function hide_details()
	ui.hide_popup(volume_bracket)
	clear_devices()
end

ui.hover_popup(volume_bracket, volume, show_details, hide_details)
ui.hover_keep_open(volume_bracket, slider, hide_details)

volume:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		sbar.exec("open /System/Library/PreferencePanes/Sound.prefPane")
	end
end)

volume:subscribe("mouse.scrolled", function(env)
	sbar.exec(
		'osascript -e "set volume output volume (output volume of (get volume settings) + ' .. env.SCROLL_DELTA .. ')"'
	)
end)
