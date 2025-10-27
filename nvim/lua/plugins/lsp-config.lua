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
      { "ms-jpq/coq_nvim",      branch = "coq" },
      { "ms-jpq/coq.artifacts", branch = "artifacts" },
    },
    lazy = false, -- REQUIRED: tell lazy.nvim to start this plugin at startup
    config = function(_, opts)
      local lspconfig = require("lspconfig")

      -- Lua
      lspconfig.lua_ls.setup({})

      -- type/javascript
      lspconfig.ts_ls.setup({})

      -- c/c++
      lspconfig.clangd.setup({})

      -- rust
      lspconfig.rust_analyzer.setup({})

      -- keybindings
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})

      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})

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
    end,
    init = function()
      vim.g.coq_settings = {
        auto_start = false,
      }
    end,
  },
}
