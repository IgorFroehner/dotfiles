local settings = require("settings")
local style = require("helpers.style")
local ui = require("helpers.ui")

local time = sbar.add("item", "time", {
	position = "right",
	update_freq = 30,
	icon = { drawing = false },
	label = {
		font = style.font("numbers", "Semibold", settings.font.sizes.numbers + 1.0),
		align = "center",
		padding_left = settings.item_padding,
		padding_right = settings.bar_margin_padding,
	},
})

local date = sbar.add("item", "date", {
	position = "right",
	padding_left = settings.item_padding,
	icon = { drawing = false },
	label = {
		font = style.font("numbers", "Regular", settings.font.sizes.text),
		align = "right",
	},
})

-- time's routine drives both labels
local function update()
	time:set({ label = os.date("%H:%M") })
	date:set({ label = os.date("%a %b %d") })
end

time:subscribe({ "forced", "routine", "system_woke" }, update)

time:subscribe("mouse.clicked", function()
	ui.toggle_panel("date")
end)

date:subscribe("mouse.clicked", function()
	sbar.exec("open -a Calendar")
end)
