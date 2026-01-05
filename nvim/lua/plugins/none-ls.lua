return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        -- lua
        null_ls.builtins.formatting.stylua,

        -- ruby
        -- null_ls.builtins.formatting.erb_format,
        -- null_ls.builtins.diagnostics.erb_lint,
        -- null_ls.builtins.formatting.erb_format,
        -- null_ls.builtins.diagnostics.ruby_lsp,

        -- javascript
        null_ls.builtins.formatting.prettier,
        -- null_ls.builtins.diagnostics.prettier,
        -- null_ls.builtins.diagnostics.eslint_d,

        -- cpp
        null_ls.builtins.formatting.clang_format,

        -- python 
        -- null_ls.builtins.diagnostics.ruff,
        null_ls.builtins.formatting.black,

        -- natural language
        null_ls.builtins.completion.spell,
      },
    })

    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
  end,
}
