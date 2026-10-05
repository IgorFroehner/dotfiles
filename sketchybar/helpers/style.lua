local settings = require("settings")

local style = {}

-- Build a font table for one of the families in settings.font.
-- `size` defaults to that family's size; pass a number to override it.
function style.font(kind, weight, size)
	return {
		family = settings.font[kind],
		style = weight or "Regular",
		size = size or settings.font.sizes[kind],
	}
end

return style
