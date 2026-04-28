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
    local tool = version and ("ruby@" .. version) or "ruby"
    return { mise, "exec", tool, "--", "ruby-lsp" }
  end

  local ruby_lsp = vim.fn.exepath("ruby-lsp")
  if ruby_lsp ~= "" then
    return { ruby_lsp }
  end

  return { "ruby-lsp" }
end

return {
  cmd = ruby_lsp_cmd(),
  on_new_config = function(config, root_dir)
    config.cmd = ruby_lsp_cmd(root_dir)
  end,
}
