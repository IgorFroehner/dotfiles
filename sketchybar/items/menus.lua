local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local paths = require("helpers.paths")
local style = require("helpers.style")

local MAX_ITEMS = 7
local STAGGER = 0.03

-- Item 1 is the app's Apple menu and gets a chevron, the rest show menu titles
local menu_items = {}
for i = 1, MAX_ITEMS do
	menu_items[i] = sbar.add("item", "menu." .. i, {
		drawing = false,
		padding_right = settings.item_spacing,
		icon = {
			drawing = i == 1,
			string = icons.menu,
			font = style.font("icons", "Semibold", settings.font.sizes.text - 1.0),
		},
		label = {
			font = style.font("text", "Semibold"),
			color = colors.quicksilver,
			padding_right = settings.item_spacing,
		},
		click_script = paths.menus .. " -s " .. i,
	})
end

local menu_padding = sbar.add("item", "menu.padding", { drawing = false, width = 5 })

-- Hidden item that only listens for events
local watcher = sbar.add("item", "menu.watcher", { drawing = false, updates = true })

local visible = false
-- Bumped on every show/hide so stale staggered reveals are dropped
local generation = 0

local function hide_menus()
	generation = generation + 1
	sbar.set("/menu\\..*/", { drawing = false })
end

local function show_menus()
	hide_menus()
	local current = generation

	-- Pin the menus to the focused window's space
	sbar.exec("yabai -m query --windows --window | jq -r '.space'", function(space)
		space = tonumber(space)
		sbar.exec(paths.menus .. " -l", function(menus)
			if current ~= generation then
				return
			end
			menu_padding:set({ drawing = true })

			local i = 0
			for menu in menus:gmatch("[^\r\n]+") do
				i = i + 1
				if i > MAX_ITEMS then
					break
				end
				local item = menu_items[i]
				item:set({ space = space, label = i > 1 and menu or "" })
				sbar.delay((i - 1) * STAGGER, function()
					if current == generation then
						item:set({ drawing = true })
					end
				end)
			end
		end)
	end)
end

watcher:subscribe("swap_menus_and_spaces", function()
	visible = not visible
	if visible then
		show_menus()
	else
		hide_menus()
	end
end)

watcher:subscribe("front_app_switched", function()
	if visible then
		show_menus()
	end
end)
