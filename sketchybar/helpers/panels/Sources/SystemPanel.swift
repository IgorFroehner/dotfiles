import SwiftUI

/// The panel opened from the Apple logo: profile and power actions, Spotify, and system stats.
struct SystemPanelView: View {
    @StateObject private var statsController = StatsController()
    @StateObject private var mediaController = MediaController()
    let username: String = NSFullUserName()

    // Function to load the user profile image
    private func getUserProfileImage() -> NSImage? {
        let username = NSUserName()
        
        // Check for custom profile picture
        if let imagePath = try? FileManager.default.contentsOfDirectory(atPath: "/Users/\(username)/Library/UserPictures").first {
            return NSImage(contentsOfFile: "/Users/\(username)/Library/UserPictures/\(imagePath)")
        }
        
        return nil
    } 

    private var profileSection: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                // Profile image and name
                HStack(spacing: 4) {
                    // Profile Image
                    if let profileImage = getUserProfileImage() {
                        Image(nsImage: profileImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                    } else {
                        // Fallback Circle
                        Circle()
                            .fill(Color(Colors.accent))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                    }
                    
                        // Username with dynamic adjustments
                    Text(username)
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .semibold)) // Adjust font size based on length
                        .multilineTextAlignment(.leading)
                        .lineLimit(2) // Limit to two lines if necessary
                        .frame(maxWidth: .infinity, alignment: .leading) // Allow full width usage
                }
                
                Spacer()

                // Action buttons
                HStack(spacing: 8) {
                    ActionButton(icon: "power", color: Color(Colors.red)) {
                        powerOff()
                    }
                    
                    ActionButton(icon: "arrow.counterclockwise", color: Color(Colors.orange)) {
                        restart()
                    }
                    
                    ActionButton(icon: "lock.fill", color: Color(Colors.green)) {
                        lock()
                    }
                    
                    ActionButton(icon: "rectangle.portrait.and.arrow.right", color: Color(Colors.blue)) {
                        logout()
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .padding(.top, 25)
            
            Rectangle()
                .fill(Color(Colors.cardBorder))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
        }
    }

    private var mediaPlayerSection: some View {
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
                    
                    // Content
                    HStack(spacing: 12) {
                        // Album artwork
                        if let artwork = mediaController.artwork {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 82, height: 82)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Title and artist
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mediaController.title)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                            
                            Text(mediaController.artist)
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        
                        // Spacer()
                        
                        // Media controls
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
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
            backgroundImage: nil
        )
        .padding(.horizontal, 30)
    }


    var body: some View {
        ZStack {
            Color(Colors.panelBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 10) {
                profileSection

                mediaPlayerSection

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 15), // Adjust spacing as needed
                    GridItem(.flexible(), spacing: 15)
                ], spacing: 20) { // Adjust vertical spacing as needed
                    CircularProgressView(
                        progress: statsController.batteryLevel,
                        icon: batteryIcon(level: statsController.batteryLevel, isCharging: statsController.isCharging),
                        color: Color(Colors.green)
                    )
                    CircularProgressView(
                        progress: statsController.volumeLevel,
                        icon: volumeIcon(level: statsController.volumeLevel, isMuted: statsController.isMuted),
                        color: Color(Colors.blue)
                    )
                    CircularProgressView(
                        progress: statsController.memoryUsage,
                        icon: "memorychip",
                        color: Color(Colors.yellow)
                    )

                    CircularProgressView(
                        progress: statsController.cpuUsage,
                        icon: "cpu",
                        color: Color(Colors.orange)
                    )
                    // CircularProgressView(
                    //     progress: statsController.diskUsage,
                    //     icon: "internaldrive",
                    //     color: Color(Colors.red)
                    // )
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
            .padding(.bottom, 25)
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(Colors.panelBorder), lineWidth: 1)
        )
    }
    
    private func volumeIcon(level: Double, isMuted: Bool) -> String {
        if isMuted {
            return "speaker.slash.fill"
        }
        
        let percentage = level * 100
        switch percentage {
        case 0:
            return "speaker.fill"
        case 0.1...33:
            return "speaker.wave.1.fill"
        case 33.1...66:
            return "speaker.wave.2.fill"
        default:
            return "speaker.wave.3.fill"
        }
    }

    private func batteryIcon(level: Double, isCharging: Bool) -> String {
        if isCharging {
            return "battery.100.bolt"
        } else {
            switch level {
            case 0..<0.25:
                return "battery.25"
            case 0.25..<0.5:
                return "battery.50"
            case 0.5..<0.75:
                return "battery.75"
            default:
                return "battery.100"
            }
        }
    }
}

// System actions, run through System Events
func powerOff() {
    runOsascript("tell application \"System Events\" to shut down")
}

func restart() {
    runOsascript("tell application \"System Events\" to restart")
}

func lock() {
    runOsascript("tell application \"System Events\" to keystroke \"q\" using {command down, control down}")
}

func logout() {
    runOsascript("tell application \"System Events\" to log out")
}
