import AppKit

/// Spotify's now-playing state, read through AppleScript.
/// (MediaRemote stopped returning now-playing info to third-party apps in macOS 15.4.)
class MediaController: ObservableObject {
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var isPlaying: Bool = false
    @Published var artwork: NSImage?

    private var artworkURL = ""
    private var timer: Timer?

    // Prints the player state, track name, artist and artwork URL on separate lines,
    // or nothing when Spotify isn't running or is stopped
    private static let statusScript = """
    if application "Spotify" is not running then return ""
    tell application "Spotify"
        if player state is stopped then return ""
        return (player state as string) & linefeed & (name of current track) & linefeed & (artist of current track) & linefeed & (artwork url of current track)
    end tell
    """

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func togglePlayPause() { send("playpause") }
    func next() { send("next track") }
    func previous() { send("previous track") }

    private func send(_ command: String) {
        runOsascript("tell application \"Spotify\" to \(command)") { [weak self] _ in
            self?.refresh()
        }
    }

    private func refresh() {
        runOsascript(Self.statusScript) { [weak self] output in
            guard let self = self else { return }
            let fields = output.components(separatedBy: "\n")
            guard fields.count >= 3 else {
                self.title = ""
                self.artist = ""
                self.isPlaying = false
                self.setArtwork(url: "")
                return
            }
            self.isPlaying = fields[0] == "playing"
            self.title = fields[1]
            self.artist = fields[2]
            self.setArtwork(url: fields.count > 3 ? fields[3] : "")
        }
    }

    private func setArtwork(url urlString: String) {
        guard urlString != artworkURL else { return }
        artworkURL = urlString
        guard let url = URL(string: urlString), !urlString.isEmpty else {
            artwork = nil
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            let image = data.flatMap { NSImage(data: $0) }
            DispatchQueue.main.async {
                guard let self = self, self.artworkURL == urlString else { return }
                self.artwork = image
            }
        }.resume()
    }
}
