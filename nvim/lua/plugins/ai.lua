return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = {
					auto_trigger = true,
					keymap = {
						accept = "<C-l>",
						next = "<C-]>",
						prev = "<C-]>",
						dismiss = "<C-x>",
					},
				},
			})
		end,
	},
	{
		"olimorris/codecompanion.nvim",
		opts = {},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("codecompanion").setup({
				strategies = {
					chat = {
						adapter = "copilot",
						window = {
							position = "right",
						},
					},
					inline = {
						adapter = "copilot",
					},
				},
				display = {
					chat = {
						window = {
							position = "right",
							width = 0.35,
						},
					},
				},
			})

			vim.keymap.set("n", "<leader>com", ":CodeCompanionChat Toggle<CR>", {})
		end,
	},
}
