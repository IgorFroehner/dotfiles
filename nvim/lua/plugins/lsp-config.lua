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
					"rust_analyzer",
					"pyright",
				},
				automatic_enable = { false },
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- main one
			{ "ms-jpq/coq_nvim", branch = "coq" },
			{ "ms-jpq/coq.artifacts", branch = "artifacts" },
		},
		lazy = false, -- REQUIRED: tell lazy.nvim to start this plugin at startup
		config = function(_, opts)
      -- local lspconfig = require("lspconfig")
      -- local lspconfig = 

			-- Lua
			vim.lsp.enable('lua_ls')

			-- type/javascript
			vim.lsp.enable('ts_ls')

			-- c/c++
			vim.lsp.enable('clangd')

			-- rust
			vim.lsp.enable('rust_analyzer')

			-- mojo
			vim.lsp.enable("mojo")

			local base_dir = vim.fn.stdpath("config") .. "/lua/config/lsp"
			local files = vim.fn.globpath(base_dir, "*.lua", false, true)

			-- Build capabilities once, enhanced by cmp-nvim-lsp
			local function make_capabilities()
				local caps = vim.lsp.protocol.make_client_capabilities()
				local ok, cmp = pcall(require, "cmp_nvim_lsp")
				if ok then
					caps = cmp.default_capabilities(caps)
				end
				return caps
			end

			-- Base settings injected into every server
			vim.lsp.config("*", {
				on_attach = opts.on_attach,
				capabilities = make_capabilities(),
			})

			for _, file in ipairs(files) do
				local name = vim.fn.fnamemodify(file, ":t:r") -- filename without .lua
				local modname = ("config.lsp.%s"):format(name)
				local ok, mod = pcall(require, modname)
				if not ok then
					vim.notify("LSP config failed: " .. modname .. "\n" .. mod, vim.log.levels.ERROR)
				else
					vim.lsp.config(name, mod)
					vim.lsp.enable(name)
				end
			end

		-- keybindings
		local telescope_builtin = require("telescope.builtin")

		vim.keymap.set("n", "<S-k>", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "LSP Hover" })
		vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, { noremap = true, silent = true, desc = "Go to definition" })
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { noremap = true, silent = true, desc = "Code action" })

		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { noremap = true, silent = true, desc = "Rename" })

		vim.keymap.set("n", "<leader>gr", telescope_builtin.lsp_references, { noremap = true, silent = true, desc = "References" })
		end,
		init = function()
			vim.g.coq_settings = {
				auto_start = false,
			}
		end,
	},
}
