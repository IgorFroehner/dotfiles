return {
	"rmagatti/auto-session",
	lazy = false,
	opts = {
		suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
		-- Close neo-tree before saving so it isn't persisted as a buffer in the session
		pre_save_cmds = { "Neotree close" },
		-- Reopen neo-tree after a session is restored
		post_restore_cmds = { "Neotree filesystem reveal left" },
		-- Don't save sessions when alpha (dashboard) is the active buffer
		bypass_save_file_types = { "alpha" },
		-- Don't auto-restore when nvim is opened without file arguments (let dashboard show)
		auto_restore_enabled = vim.fn.argc() ~= 0,
	},
}
