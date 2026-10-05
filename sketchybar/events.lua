-- Custom events (built-in ones like front_app_switched need no registration)

-- Triggered by the front app item to show the app menus in place of the spaces
sbar.add("event", "swap_menus_and_spaces")

-- Spotify posts this distributed notification whenever playback changes
sbar.add("event", "spotify_change", "com.spotify.client.PlaybackStateChanged")
