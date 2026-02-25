local function ruby_lsp_cmd()
  local ruby_lsp = vim.fn.exepath("ruby-lsp")
  if ruby_lsp ~= "" then
    return { ruby_lsp }
  end

  local mise = vim.fn.exepath("mise")
  if mise ~= "" then
    return { mise, "x", "--", "ruby-lsp" }
  end

  local asdf_ruby_lsp = vim.fn.expand("~/.asdf/shims/ruby-lsp")
  if vim.fn.executable(asdf_ruby_lsp) == 1 then
    return { asdf_ruby_lsp }
  end

  return { "ruby-lsp" }
end

return {
  cmd = ruby_lsp_cmd(),
}
