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

-- Buffer switching without barbar; with ide_layout barbar's own maps take over these keys
if not vim.g.ide_layout then
	vim.keymap.set("n", "<C-,>", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })
	vim.keymap.set("n", "<C-.>", "<Cmd>bnext<CR>", { desc = "Next buffer" })

	-- Close the buffer but keep its window: show the alternate (or an empty) buffer first
	local function close_buffer()
		local buf = vim.api.nvim_get_current_buf()
		if vim.bo[buf].modified then
			vim.notify("Buffer has unsaved changes", vim.log.levels.WARN)
			return
		end
		local alt = vim.fn.bufnr("#")
		if alt > 0 and alt ~= buf and vim.fn.buflisted(alt) == 1 then
			vim.cmd.buffer(alt)
		else
			vim.cmd.enew()
		end
		if vim.api.nvim_buf_is_valid(buf) then
			vim.cmd.bdelete(buf)
		end
	end

	vim.keymap.set("n", "<leader>w", close_buffer, { desc = "Close buffer" })
	vim.keymap.set("n", "<leader>W", "<Cmd>%bdelete|edit #|bdelete #<CR>", { desc = "Close other buffers" })
end
