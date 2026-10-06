local settings = require("settings")
local colors = require("colors")
local style = require("helpers.style")

-- Equivalent to the --default domain
sbar.default({
	updates = "when_shown",
	icon = {
		font = style.font("icons", "Regular"),
		color = colors.white,
		padding_left = settings.default_padding,
		padding_right = settings.default_padding,
		background = { image = { corner_radius = settings.item_corner_radius } },
	},
	label = {
		font = style.font("text", "Bold"),
		color = colors.white,
		padding_left = settings.default_padding,
		padding_right = settings.default_padding,
	},
	background = {
		height = settings.item_height,
		corner_radius = settings.item_corner_radius,
		border_width = 0,
		image = {
			corner_radius = settings.item_corner_radius,
		},
	},
	popup = {
		background = {
			drawing = true,
			corner_radius = settings.popup_border_radius,
			color = colors.popup.bg,
			shadow = { drawing = true },
			image = {
				corner_radius = settings.popup_border_radius,
				padding_left = settings.popup_image_padding,
				padding_right = settings.popup_image_padding,
			},
			border_color = colors.popup.border,
			border_width = settings.popup_border_width,
		},
		blur_radius = settings.popup_blur_radius,
		y_offset = settings.popup_y_offset,
	},
	padding_left = settings.default_padding,
	padding_right = settings.default_padding,
	scroll_texts = true,
})
