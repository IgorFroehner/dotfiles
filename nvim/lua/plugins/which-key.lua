-- Leader groups follow KEYMAP.md
return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		spec = {
			{ "<leader>f", group = "find / files" },
			{ "<leader>g", group = "git" },
			{ "<leader>c", group = "code" },
			{ "<leader>a", group = "AI" },
			{ "<leader>t", group = "toggles" },
		},
	},
}
