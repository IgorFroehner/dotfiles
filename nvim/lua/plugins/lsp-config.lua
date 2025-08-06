return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"ts_ls",
					"clangd",
					"ruby_lsp",
					"rubocop",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")

			-- Lua
			lspconfig.lua_ls.setup({})

			-- type/javascript
			lspconfig.ts_ls.setup({})

			-- ruby
			lspconfig.rubocop.setup({})
			lspconfig.ruby_lsp.setup({
				mason = false,
				cmd = { vim.fn.expand("~/.asdf/shims/ruby-lsp") },
			})

			-- c/c++
			lspconfig.clangd.setup({})

			-- keybindings
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
  {
    "neovim/nvim-lspconfig", -- REQUIRED: for native Neovim LSP integration
    lazy = false, -- REQUIRED: tell lazy.nvim to start this plugin at startup
    dependencies = {
      -- main one
      { "ms-jpq/coq_nvim", branch = "coq" },
    },
    init = function()
      vim.g.coq_settings = {
          auto_start = true,
      }
    end,
    config = function()
      -- Your LSP settings here
    end,
  }
}
