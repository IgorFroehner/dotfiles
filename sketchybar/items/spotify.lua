local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

local MAX_LENGTH = 35

-- Prints "stopped", or the player state, track name and artist on separate lines
local STATUS_SCRIPT = {
	'if application "Spotify" is not running then return "stopped"',
	'tell application "Spotify"',
	"if player state is stopped then return \"stopped\"",
	"return (player state as string) & linefeed & (name of current track) & linefeed & (artist of current track)",
	"end tell",
}
local STATUS_CMD = "osascript -e '" .. table.concat(STATUS_SCRIPT, "' -e '") .. "'"

local spotify = sbar.add("item", "spotify", {
	position = "e",
	updates = true,
	update_freq = 30,
	icon = {
		string = icons.spotify.play,
		align = "center",
		padding_left = settings.bar_margin_padding,
		padding_right = settings.item_padding,
	},
	label = { drawing = false },
})

-- Truncate on characters, not bytes, so multi-byte titles don't get cut mid-glyph
local function truncate(text)
	if utf8.len(text) <= MAX_LENGTH then
		return text
	end
	return text:sub(1, utf8.offset(text, MAX_LENGTH - 1) - 1) .. ".."
end

local function update()
	sbar.exec(STATUS_CMD, function(output)
		local state, title, artist = output:match("^(%a+)\n?([^\n]*)\n?([^\n]*)")
		if state ~= "playing" and state ~= "paused" then
			spotify:set({
				label = { drawing = false },
				icon = { string = icons.spotify.play, color = colors.grey },
			})
			return
		end

		local text = artist ~= "" and title .. " - " .. artist or title
		spotify:set({
			label = { string = truncate(text), drawing = true },
			icon = {
				string = state == "playing" and icons.spotify.pause or icons.spotify.play,
				color = colors.white,
			},
		})
	end)
end

-- spotify_change is pushed by Spotify itself, routine catches anything missed
spotify:subscribe({ "spotify_change", "routine", "forced" }, update)

spotify:subscribe("mouse.clicked", function()
	sbar.exec("osascript -e 'tell application \"Spotify\" to playpause'", update)
end)
