local colors = require("colors")
local settings = require("settings")
local style = require("helpers.style")
local ui = require("helpers.ui")

local front_app = sbar.add("item", "front_app", {
	label = {
		font = style.font("numbers", "Semibold"),
		padding_right = settings.item_padding - 5,
	},
	icon = {
		background = {
			drawing = true,
			image = {
				scale = 0.6,
				padding_right = settings.item_padding,
			},
		},
	},
})

local function set_hovered(hovered)
	sbar.animate("elastic", 10, function()
		front_app:set({
			background = { color = hovered and colors.spaces.active or colors.transparent },
			icon = {
				background = {
					image = {
						scale = hovered and 0.5 or 0.6,
						padding_left = hovered and 3 or 0,
					},
				},
			},
			label = {
				padding_right = hovered and settings.item_padding or settings.item_padding - 5,
			},
		})
	end)
end

front_app:subscribe("front_app_switched", function(env)
	front_app:set({
		icon = { background = { image = "app." .. env.INFO } },
		label = { string = env.INFO },
	})
end)

front_app:subscribe("mouse.entered", function()
	set_hovered(true)
end)

front_app:subscribe("mouse.exited", function()
	set_hovered(false)
end)

front_app:subscribe("mouse.clicked", function()
	sbar.trigger("swap_menus_and_spaces")
end)

ui.spacer("front_app.spacer")
