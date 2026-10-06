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

			vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>")
		end,
	},
	{
		"romgrk/barbar.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("barbar").setup({})

			-- Offset the tabline by the neo-tree width ourselves. barbar's sidebar_filetypes
			-- drops the offset for good when the neo-tree buffer briefly leaves its window,
			-- e.g. when Telescope opens a file while neo-tree is focused.
			local function update_offset()
				local width = 0
				for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
					local buf = vim.api.nvim_win_get_buf(win)
					if vim.bo[buf].filetype == "neo-tree" and vim.api.nvim_win_get_position(win)[2] == 0 then
						width = vim.api.nvim_win_get_width(win)
					end
				end
				require("barbar.api").set_offset(width)
			end

			vim.api.nvim_create_autocmd({ "BufWinEnter", "WinClosed", "WinResized", "TabEnter", "VimResized" }, {
				group = vim.api.nvim_create_augroup("BarbarNeoTreeOffset", { clear = true }),
				-- Scheduled so WinClosed sees the window already gone
				callback = function()
					vim.schedule(update_offset)
				end,
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
		dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
		config = function()
			require("lualine").setup({
				options = {
					theme = require("catppuccin.utils.lualine"),
				},
			})
		end,
	},
}
