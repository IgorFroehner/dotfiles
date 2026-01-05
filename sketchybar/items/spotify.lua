local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

local spotify = sbar.add("item", "spotify", {
	icon = {
		font = { size = settings.font.sizes.icons },
		string = icons.spotify.play,
		align = "center",
		color = colors.white,
		drawing = true,
		padding_left = settings.bar_margin_padding,
		padding_right = settings.item_padding,
	},
	label = {
		string = "",
		color = colors.white,
		drawing = false,
	},
	position = "e",
	updates = true,
	update_freq = 30,
})

-- Function to update Spotify status
local function update_spotify()
	sbar.exec(
		'osascript -e \'tell application "System Events" to (name of processes) contains "Spotify"\'',
		function(running)
			if running:match("false") then
				spotify:set({
					label = { drawing = false },
					icon = { string = icons.spotify.play, color = colors.grey },
				})
				return
			end

			sbar.exec("osascript -e 'tell application \"Spotify\" to player state as string'", function(state)
				state = state:gsub("%s+", "")

				if state == "playing" or state == "paused" then
					sbar.exec("osascript -e 'tell application \"Spotify\" to name of current track'", function(title)
						sbar.exec(
							"osascript -e 'tell application \"Spotify\" to artist of current track'",
							function(artist)
								title = title:gsub("\n", "")
								artist = artist:gsub("\n", "")

								local song_text = title .. " - " .. artist
								local max_length = 35

								if song_text:len() > max_length then
									song_text = string.sub(song_text, 1, max_length - 2) .. ".."
								end

								local icon = (state == "playing") and icons.spotify.pause or icons.spotify.play

								spotify:set({
									label = { string = song_text, drawing = true },
									icon = { string = icon, color = colors.white },
								})
							end
						)
					end)
				else
					spotify:set({
						label = { drawing = false },
						icon = { string = icons.spotify.play, color = colors.grey },
					})
				end
			end)
		end
	)
end

-- Subscribe to Spotify's native playback state change event
spotify:subscribe("spotify_change", update_spotify)

-- Also subscribe to routine for periodic updates (in case events are missed)
spotify:subscribe("routine", update_spotify)
spotify:subscribe("forced", update_spotify)

-- Mouse click handler
spotify:subscribe("mouse.clicked", function(_)
	sbar.exec("osascript -e 'tell application \"Spotify\" to playpause'")
	-- Update immediately after click
	sbar.delay(0.5, update_spotify)
end)

-- Initial update
update_spotify()
