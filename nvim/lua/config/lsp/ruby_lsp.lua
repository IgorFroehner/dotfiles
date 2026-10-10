local function get_project_ruby_version(dir)
  local version_file = dir .. "/.ruby-version"
  if vim.fn.filereadable(version_file) == 1 then
    local lines = vim.fn.readfile(version_file)
    if lines[1] then
      return vim.trim(lines[1])
    end
  end
end

local function ruby_lsp_cmd(root_dir)
  local dir = root_dir or vim.fn.getcwd()
  local mise = vim.fn.exepath("mise")

  if mise ~= "" then
    local version = get_project_ruby_version(dir)
    if version then
      -- gem:ruby-lsp overrides the ruby version to wherever it's installed,
      -- so omit it and rely on the project's version having ruby-lsp installed.
      return { mise, "exec", "ruby@" .. version, "--", "ruby-lsp" }
    end
    return { mise, "exec", "gem:ruby-lsp", "--", "ruby-lsp" }
  end

  local ruby_lsp = vim.fn.exepath("ruby-lsp")
  if ruby_lsp ~= "" then
    return { ruby_lsp }
  end

  return { "ruby-lsp" }
end

return {
  -- Resolve the command per root_dir at spawn time; vim.lsp.config has no on_new_config hook.
  cmd = function(dispatchers, config)
    return vim.lsp.rpc.start(ruby_lsp_cmd(config.root_dir), dispatchers, { cwd = config.root_dir })
  end,
}
