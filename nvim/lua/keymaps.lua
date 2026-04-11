vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to down window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to up window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

vim.keymap.set({"n", "v"}, "<leader>y", '"+y', { desc = "Yank to clipboard" })

vim.keymap.set("n", "<leader>yf", function()
	vim.fn.setreg("+", vim.fn.expand("%:t"))
end, { desc = "Copy filename to clipboard" })

-- Reader mode: center cursor with scrolloff=999, toggle off on same keybind or insert/replace modes
local reader_mode = false
local reader_saved_scrolloff = 0

local function disable_reader_mode()
	if not reader_mode then return end
	reader_mode = false
	vim.o.scrolloff = reader_saved_scrolloff
	vim.notify("Reader mode OFF")
end

vim.keymap.set("n", "<leader>zr", function()
	if reader_mode then
		disable_reader_mode()
	else
		reader_saved_scrolloff = vim.o.scrolloff
		reader_mode = true
		vim.o.scrolloff = 999
		vim.notify("Reader mode ON")
	end
end, { desc = "Toggle reader mode" })

vim.api.nvim_create_autocmd("InsertEnter", {
	callback = disable_reader_mode,
})

vim.api.nvim_create_autocmd("CmdlineEnter", {
	callback = disable_reader_mode,
})

vim.api.nvim_create_autocmd("TermEnter", {
	callback = disable_reader_mode,
})
