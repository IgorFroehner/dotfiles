return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({
			auto_install = true,
			highlight = { enable = true },
			indent = { 
				enable = true,
				disable = { "ruby" }, -- Disable treesitter indent for Ruby due to dot de-indent issue
			},
		})
	end,
}
