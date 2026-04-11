local function ruby_lsp_cmd(root_dir)
  local dir = root_dir or vim.fn.getcwd()

  -- Prefer bundle exec in bundler projects (most reliable per-project)
  local gemfile = dir .. "/Gemfile"
  if vim.fn.filereadable(gemfile) == 1 then
    local bundle = vim.fn.exepath("bundle")
    if bundle ~= "" then
      return { bundle, "exec", "ruby-lsp" }
    end
  end

  local ruby_lsp = vim.fn.exepath("ruby-lsp")
  if ruby_lsp ~= "" then
    return { ruby_lsp }
  end

  local mise = vim.fn.exepath("mise")
  if mise ~= "" then
    return { mise, "x", "--", "ruby-lsp" }
  end

  return { "ruby-lsp" }
end

return {
  cmd = ruby_lsp_cmd(),
  on_new_config = function(config, root_dir)
    config.cmd = ruby_lsp_cmd(root_dir)
  end,
}
