return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		lazy = false,
		config = function()
			require("neo-tree").setup({
				filesystem = {
					filtered_items = {
						visible = true,
						hide_dotfiles = false,
						never_show = { "node_modules", ".git", ".cache" },
					},
				},
			})

			vim.keymap.set("n", "<C-n>", ":Neotree filesystem toggle left<CR>")
		end,
	},
	{
		"romgrk/barbar.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("barbar").setup({
        extensions = {
          "neo-tree",
          "lazy",
          "mason",
        },
				sidebar_filetypes = {
					["neo-tree"] = { event = "BufWipeout" },
				},
			})

			local map = vim.api.nvim_set_keymap
			local opts = { noremap = true, silent = true }

			-- Move to previous/next
			map("n", "<C-,>", "<Cmd>BufferPrevious<CR>", opts)
			map("n", "<C-.>", "<Cmd>BufferNext<CR>", opts)

			map("n", "<leader>w", "<Cmd>BufferClose<CR>", opts)
			map("n", "<leader>W", "<Cmd>BufferCloseAllButCurrent<CR>", opts)
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "catppuccin",
				},
			})
		end,
	},
}
