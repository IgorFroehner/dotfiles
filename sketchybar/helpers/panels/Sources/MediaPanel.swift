import SwiftUI

/// The panel shown while hovering the Spotify item: artwork, track and playback controls.
struct MediaPanelView: View {
    @StateObject private var mediaController = MediaController()

    var body: some View {
        Card(
            content: AnyView(
                ZStack {
                    // Blurred background artwork
                    if let artwork = mediaController.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .blur(radius: 10)
                            .opacity(0.12)
                    }

                    HStack(spacing: 12) {
                        if let artwork = mediaController.artwork {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 82, height: 82)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(mediaController.title)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(2)

                            Text(mediaController.artist)
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 20) {
                            MediaControlButton(systemName: "backward.end.fill") {
                                mediaController.previous()
                            }
                            MediaControlButton(systemName: mediaController.isPlaying ? "pause.fill" : "play.fill") {
                                mediaController.togglePlayPause()
                            }
                            MediaControlButton(systemName: "forward.end.fill") {
                                mediaController.next()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 110)
            ),
            backgroundColor: Color(Colors.cardBackground),
            padding: EdgeInsets(),
            backgroundImage: nil
        )
    }
}
