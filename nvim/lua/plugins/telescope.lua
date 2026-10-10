return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({
				defaults = {
					-- configure to use ripgrep
					vimgrep_arguments = {
						"rg",
						"--follow", -- Follow symbolic links
						"--hidden", -- Search for hidden files
						"--no-heading", -- Don't group matches by each file
						"--with-filename", -- Print the file path with the matched lines
						"--line-number", -- Show line numbers
						"--column", -- Show column numbers
						"--smart-case", -- Smart case search

						-- Exclude some patterns from search
						"--glob=!**/.git/*",
						"--glob=!**/.idea/*",
						"--glob=!**/.vscode/*",
						"--glob=!**/build/*",
						"--glob=!**/dist/*",
						"--glob=!**/yarn.lock",
						"--glob=!**/package-lock.json",
					},
				},
				pickers = {
					-- Open buffers, most recently used first: replaces barbar's tab list
					buffers = {
						sort_mru = true,
						ignore_current_buffer = true,
						mappings = {
							i = { ["<C-d>"] = "delete_buffer" },
							n = { ["dd"] = "delete_buffer" },
						},
					},
					oldfiles = {
						only_cwd = true,
					},
					find_files = {
						hidden = true,
						-- needed to exclude some files & dirs from general search
						-- when not included or specified in .gitignore
						find_command = {
							"rg",
							"--files",
							"--hidden",
							"--glob=!**/.git/*",
							"--glob=!**/.idea/*",
							"--glob=!**/.vscode/*",
							"--glob=!**/build/*",
							"--glob=!**/dist/*",
							"--glob=!**/yarn.lock",
							"--glob=!**/package-lock.json",
						},
					},
				},
			})

			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<D-p>", builtin.find_files, {})
			vim.keymap.set("n", "<D-F>", builtin.live_grep, {})
			vim.keymap.set("n", "<D-e>", builtin.buffers, { desc = "Open buffers" })
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Open buffers" })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Open buffers" })
			vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files in project" })
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})

			require("telescope").load_extension("ui-select")
		end,
	},
}
