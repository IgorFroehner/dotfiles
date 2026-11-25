local colors = require("colors")
local settings = require("settings")
local style = require("helpers.style")
local ui = require("helpers.ui")

-- AeroSpace workspaces 1-9 (persistent-workspaces in aerospace/aerospace.toml).
-- They're virtual, so these are plain items: each one is moved to the display
-- its workspace is on and highlighted while that workspace is visible there.
local WORKSPACES = 9

local spaces = {}

for i = 1, WORKSPACES do
	local space = sbar.add("item", "space." .. i, {
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
		click_script = "aerospace workspace " .. i,
	})

	-- 2px gap after each space (fixed-width items ignore padding)
	local gap = sbar.add("item", "space.gap." .. i, { width = 2 })

	spaces[tostring(i)] = { item = space, gap = gap }
end

local FORMAT = "%{workspace}|%{monitor-appkit-nsscreen-screens-id}|%{workspace-is-visible}"

-- Asks AeroSpace where every workspace is rather than trusting the event's
-- payload: focusing a workspace on another display moves focus there and
-- leaves the previous workspace visible.
local function update()
	sbar.exec("aerospace list-workspaces --all --format '" .. FORMAT .. "'", function(output)
		for line in output:gmatch("[^\r\n]+") do
			local name, display, visible = line:match("^(.-)|(%d+)|(%a+)$")
			local space = spaces[name]
			if space then
				local selected = visible == "true"
				space.item:set({
					display = tonumber(display),
					label = { highlight = selected },
					background = {
						color = selected and colors.spaces.active or colors.spaces.inactive,
					},
				})
				space.gap:set({ display = tonumber(display) })
			end
		end
	end)
end

-- Hidden item that only listens for events
local watcher = sbar.add("item", "spaces.watcher", { drawing = false, updates = true })
watcher:subscribe({ "forced", "aerospace_workspace_change", "display_change", "system_woke" }, update)

ui.spacer("spaces.spacer")
