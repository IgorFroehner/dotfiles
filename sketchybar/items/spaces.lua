local colors = require("colors")
local settings = require("settings")
local style = require("helpers.style")
local ui = require("helpers.ui")

local function add_space(i)
	local space = sbar.add("space", "space." .. i, {
		space = i,
		width = 30,
		label = {
			string = string.format("%02d", i),
			padding_left = settings.item_padding - 2.0,
			color = colors.quicksilver,
			highlight_color = colors.white,
			font = style.font("numbers", "Semibold", settings.font.sizes.numbers + 1.0),
			align = "center",
		},
		background = {
			color = colors.transparent,
		},
		popup = {
			background = {
				border_width = settings.popup_border_width,
				border_color = colors.popup.border,
				corner_radius = settings.popup_border_radius,
				drawing = true,
			},
		},
	})

	-- 2px gap after each space (fixed-width items ignore padding)
	sbar.add("space", "space.gap." .. i, { space = i, width = 2 })

	-- Middle click shows a preview of the space in a popup
	local preview = sbar.add("item", {
		position = "popup." .. space.name,
		background = {
			padding_left = settings.popup_border_width,
			drawing = true,
			image = {
				corner_radius = settings.bar_corner_radius,
				scale = 0.15,
			},
		},
	})

	space:subscribe("space_change", function(env)
		local selected = env.SELECTED == "true"
		space:set({
			icon = { highlight = selected },
			label = { highlight = selected },
			background = {
				color = selected and colors.spaces.active or colors.spaces.inactive,
			},
		})
	end)

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			preview:set({ background = { image = "space." .. env.SID } })
			space:set({ popup = { drawing = "toggle" } })
		else
			local op = (env.BUTTON == "right") and "--destroy" or "--focus"
			sbar.exec("yabai -m space " .. op .. " " .. env.SID)
		end
	end)
end

for i = 1, 9 do
	add_space(i)
end

ui.spacer("spaces.spacer")
