import SwiftUI

/// The panel opened from the Apple logo: profile and power actions, and a small system
/// monitor with CPU, memory and disk use and the apps using the most memory.
struct SystemPanelView: View {
    @StateObject private var stats = StatsController()

    private static let cardPadding = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    private static let uptimeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Rectangle()
                .fill(Color(Colors.cardBorder))
                .frame(height: 1)

            usageCard
            topAppsCard
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 28)
        .background(Color(Colors.panelBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(Colors.panelBorder), lineWidth: 1)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 3) {
                Text(NSFullUserName())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Text("\(stats.chip) · \(stats.osVersion)")

                HStack(spacing: 4) {
                    if let level = stats.batteryLevel {
                        Image(systemName: batteryIcon(level: level, onACPower: stats.isOnACPower))
                            .foregroundColor(Color(level < 0.2 && !stats.isOnACPower ? Colors.red : Colors.green))
                        Text("\(Int((level * 100).rounded()))% ·")
                    }
                    Text("up \(Self.uptimeFormatter.string(from: stats.uptime) ?? "")")
                }
            }
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.55))
            .lineLimit(1)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                ActionButton(icon: "power", color: Color(Colors.red)) { powerOff() }
                ActionButton(icon: "arrow.counterclockwise", color: Color(Colors.orange)) { restart() }
                ActionButton(icon: "lock.fill", color: Color(Colors.green)) { lock() }
                ActionButton(icon: "rectangle.portrait.and.arrow.right", color: Color(Colors.blue)) { logout() }
            }
        }
    }

    private var avatar: some View {
        Group {
            if let picture = userPicture() {
                Image(nsImage: picture)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(Colors.accent)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white))
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }

    /// The custom account picture, if one is set
    private func userPicture() -> NSImage? {
        let directory = "/Users/\(NSUserName())/Library/UserPictures"
        guard let file = try? FileManager.default.contentsOfDirectory(atPath: directory).first else { return nil }
        return NSImage(contentsOfFile: "\(directory)/\(file)")
    }

    // MARK: - Usage

    private var usageCard: some View {
        let swap = stats.swapUsed > 0 ? " · swap \(formatMemory(stats.swapUsed))" : ""
        let loads = stats.loadAverage.map { String(format: "%.2f", $0) }.joined(separator: " ")
        let diskUsed = stats.diskTotal > 0 ? 1 - Double(stats.diskFree) / Double(stats.diskTotal) : 0

        return Card(
            content: AnyView(
                VStack(spacing: 14) {
                    UsageRow(
                        title: "CPU",
                        detail: "\(stats.cores) cores · load \(loads)",
                        value: stats.cpuUsage,
                        color: Color(Colors.orange)
                    )
                    UsageRow(
                        title: "Memory",
                        detail: "\(formatMemory(stats.memoryUsed)) of \(formatMemory(stats.memoryTotal))\(swap)",
                        value: Double(stats.memoryUsed) / Double(stats.memoryTotal),
                        color: Color(Colors.yellow)
                    )
                    UsageRow(
                        title: "Disk",
                        detail: "\(formatStorage(stats.diskFree)) free of \(formatStorage(stats.diskTotal))",
                        value: diskUsed,
                        color: Color(Colors.blue)
                    )
                    if let temperatures = stats.temperatures {
                        UsageRow(
                            title: "Temperature",
                            detail: temperatureDetail(temperatures),
                            value: temperatures.chip / 100,
                            color: thermalColor(stats.thermalState),
                            valueLabel: formatTemperature(temperatures.chip)
                        )
                    }
                }
            ),
            backgroundColor: Color(Colors.cardBackground),
            padding: Self.cardPadding,
            backgroundImage: nil
        )
    }

    // MARK: - Top apps

    private var topAppsCard: some View {
        Card(
            content: AnyView(
                VStack(alignment: .leading, spacing: 10) {
                    Text("TOP MEMORY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundColor(.white.opacity(0.45))

                    ForEach(stats.topApps) { app in
                        HStack(spacing: 10) {
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 18, height: 18)
                            Text(app.name)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(formatMemory(app.bytes))
                                .font(.system(size: 12).monospacedDigit())
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            ),
            backgroundColor: Color(Colors.cardBackground),
            padding: Self.cardPadding,
            backgroundImage: nil
        )
    }

    // MARK: - Formatting

    private func batteryIcon(level: Double, onACPower: Bool) -> String {
        if onACPower { return "battery.100.bolt" }
        switch level {
        case ..<0.25: return "battery.25"
        case ..<0.5: return "battery.50"
        case ..<0.75: return "battery.75"
        default: return "battery.100"
        }
    }

    private func temperatureDetail(_ temperatures: Temperatures) -> String {
        [
            temperatures.ssd.map { "SSD \(formatTemperature($0))" },
            temperatures.battery.map { "battery \(formatTemperature($0))" },
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }

    /// Colored by macOS's own thermal pressure rather than fixed thresholds, since how hot
    /// is too hot differs between chips
    private func thermalColor(_ state: ProcessInfo.ThermalState) -> Color {
        switch state {
        case .nominal: return Color(Colors.green)
        case .fair: return Color(Colors.yellow)
        case .serious: return Color(Colors.orange)
        default: return Color(Colors.red)
        }
    }

    private func formatTemperature(_ celsius: Double) -> String {
        "\(Int(celsius.rounded()))°C"
    }

    private func formatMemory(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    private func formatStorage(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

/// A labelled usage bar: title, detail and value above, the bar below.
private struct UsageRow: View {
    let title: String
    let detail: String
    /// How full the bar is, from 0 to 1
    let value: Double
    let color: Color
    /// Shown instead of the value as a percentage
    var valueLabel: String? = nil

    var body: some View {
        let fraction = min(max(value, 0), 1)

        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                Spacer(minLength: 8)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                Text(valueLabel ?? "\(Int((fraction * 100).rounded()))%")
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundColor(color)
                    .frame(width: 42, alignment: .trailing)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule().fill(color).frame(width: geometry.size.width * fraction)
                }
            }
            .frame(height: 6)
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
