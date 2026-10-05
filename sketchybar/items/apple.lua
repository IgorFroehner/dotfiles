local icons = require("icons")
local settings = require("settings")
local ui = require("helpers.ui")

local apple = sbar.add("item", "apple.logo", {
	icon = {
		string = icons.apple,
		align = "center",
		padding_left = settings.bar_margin_padding,
		padding_right = settings.item_padding,
	},
	label = { drawing = false },
	align = "center",
})

apple:subscribe("mouse.clicked", function()
	ui.toggle_panel("menu")
end)
