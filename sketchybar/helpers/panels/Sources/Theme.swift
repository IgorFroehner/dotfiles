import AppKit

// Nord palette, matching colors.lua
enum Colors {
    static let cardBackground = NSColor(hex: "3B4252")!.withAlphaComponent(0.95) // Nord1

    static let accent = NSColor(hex: "88C0D0")! // Nord8
    static let blue = NSColor(hex: "81A1C1")! // Nord9
    static let green = NSColor(hex: "A3BE8C")! // Nord14
    static let yellow = NSColor(hex: "EBCB8B")! // Nord13
    static let orange = NSColor(hex: "D19A66")! // Nord12
    static let red = NSColor(hex: "BF616A")! // Nord11
}

extension NSColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
