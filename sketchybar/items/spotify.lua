
local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

local whitelist = { ['Spotify'] = true }

local max_length = 35

local spotify = sbar.add("item", {
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
    string = "spotify",
    color = colors.white,
  },
  position = "e",
  updates = true,
})

spotify:subscribe("mouse.clicked", function(env)
  sbar.exec("osascript -e 'tell application \"Spotify\" to playpause'")
end)

spotify:subscribe("media_change", function(env)
  if whitelist[env.INFO.app] then
    local song_text = env.INFO.title .. " - " .. env.INFO.artist

    if song_text:len() > max_length then
      song_text = string.sub(song_text, 1, max_length - 2) .. ".."
    end

    spotify:set({
      label = {
        string = song_text,
        drawing = true,
      },
      icon = {
        string = (env.INFO.state == "playing" and icons.spotify.play or icons.media.pause),
        drawing = true,
      }
    })
  else
    spotify:set({
      icon = {
        color = colors.gray,
        drawing = true,
		    font = { size = settings.font.sizes.icons },
        string = icons.spotify.pause,
      }
    })
  end
end)

