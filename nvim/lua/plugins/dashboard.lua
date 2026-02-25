return {
	"goolord/alpha-nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VimEnter",
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		dashboard.section.buttons.val = {
			dashboard.button("e", "  New file", ":enew<CR>"),
			dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
			dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
			dashboard.button("s", "  Restore session", ":AutoSession restore<CR>"),
			dashboard.button("q", "  Quit", ":qa<CR>"),
		}

		alpha.setup(dashboard.opts)

		-- If auto-session restores a session while alpha is open, close alpha
		vim.api.nvim_create_autocmd("User", {
			pattern = "SessionLoadPost",
			callback = function()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.bo[buf].filetype == "alpha" then
						vim.api.nvim_buf_delete(buf, { force = true })
					end
				end
			end,
		})
	end,
	cond = function()
		-- Only show dashboard when nvim is opened without file arguments
		return vim.fn.argc() == 0
	end,
}
