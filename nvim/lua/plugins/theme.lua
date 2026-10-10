-- Which palette to feed catppuccin:
--   "black"             catppuccin_custom accents on pure black surfaces
--   "black_nord"        pure black with muted Nord accents, matching zellij/sketchybar
--   "catppuccin_custom" the previous near-black catppuccin look
local palette = "black"

-- Pure black backgrounds with neutral greys, same values as zellij/sketchybar
local black_surfaces = {
	surface2 = "#444444",
	surface1 = "#303030",
	surface0 = "#1f1f1f",
	base = "#000000",
	mantle = "#000000",
	crust = "#000000",
}

local palettes = {
	catppuccin_custom = {
		rosewater = "#F5B8AB",
		flamingo = "#F29D9D",
		pink = "#AD6FF7",
		mauve = "#FF8F40",
		red = "#E66767",
		maroon = "#EB788B",
		peach = "#FAB770",
		yellow = "#FACA64",
		green = "#70CF67",
		teal = "#4CD4BD",
		sky = "#61BDFF",
		sapphire = "#4BA8FA",
		blue = "#00BFFF",
		lavender = "#00BBCC",
		text = "#C1C9E6",
		subtext1 = "#A3AAC2",
		subtext0 = "#8E94AB",
		overlay2 = "#7D8296",
		overlay1 = "#676B80",
		overlay0 = "#464957",
		surface2 = "#3A3D4A",
		surface1 = "#2F313D",
		surface0 = "#1D1E29",
		base = "#0b0b12",
		mantle = "#11111a",
		crust = "#191926",
	},
	-- Nord accents, same values as sketchybar/colors.lua
	black_nord = {
		rosewater = "#eceff4", -- Nord6
		flamingo = "#d08770", -- Nord12
		pink = "#b48ead", -- Nord15
		mauve = "#81a1c1", -- Nord9, keywords
		red = "#bf616a", -- Nord11
		maroon = "#d08770", -- Nord12, parameters
		peach = "#b48ead", -- Nord15, numbers and constants
		yellow = "#ebcb8b", -- Nord13
		green = "#a3be8c", -- Nord14
		teal = "#8fbcbb", -- Nord7
		sky = "#88c0d0", -- Nord8
		sapphire = "#5e81ac", -- Nord10
		blue = "#88c0d0", -- Nord8, functions
		lavender = "#8fbcbb", -- Nord7, properties
		text = "#d8dee9", -- Nord4
		subtext1 = "#bcbcbc",
		subtext0 = "#a4a4a4",
		overlay2 = "#8a8a8a",
		overlay1 = "#707070",
		overlay0 = "#5a5a5a",
	},
}

palettes.black = vim.tbl_extend("force", palettes.catppuccin_custom, black_surfaces)
palettes.black_nord = vim.tbl_extend("force", palettes.black_nord, black_surfaces)

return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			integrations = {
				barbar = true,
			},
			highlight_overrides = {
				all = function(colors)
					return {
						CurSearch = { bg = colors.sky },
						IncSearch = { bg = colors.sky },
						CursorLineNr = { fg = colors.blue, style = { "bold" } },
						DashboardFooter = { fg = colors.overlay0 },
						TreesitterContextBottom = { style = {} },
						WinSeparator = { fg = colors.overlay0, style = { "bold" } },
						["@markup.italic"] = { fg = colors.blue, style = { "italic" } },
						["@markup.strong"] = { fg = colors.blue, style = { "bold" } },
						Headline = { style = { "bold" } },
						Headline1 = { fg = colors.blue, style = { "bold" } },
						Headline2 = { fg = colors.pink, style = { "bold" } },
						Headline3 = { fg = colors.lavender, style = { "bold" } },
						Headline4 = { fg = colors.green, style = { "bold" } },
						Headline5 = { fg = colors.peach, style = { "bold" } },
						Headline6 = { fg = colors.flamingo, style = { "bold" } },
						rainbow1 = { fg = colors.blue, style = { "bold" } },
						rainbow2 = { fg = colors.pink, style = { "bold" } },
						rainbow3 = { fg = colors.lavender, style = { "bold" } },
						rainbow4 = { fg = colors.green, style = { "bold" } },
						rainbow5 = { fg = colors.peach, style = { "bold" } },
						rainbow6 = { fg = colors.flamingo, style = { "bold" } },
					}
				end,
			},
			color_overrides = {
				all = palettes[palette],
			},
		})

		vim.cmd.colorscheme("catppuccin-mocha")
	end,
}
