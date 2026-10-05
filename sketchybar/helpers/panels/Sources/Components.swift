import AppKit
import SwiftUI

// Ring gauge with an icon and a percentage
struct CircularProgressView: View {
    let progress: Double
    let icon: String
    let color: Color
    var iconSize: CGFloat = 15 // Default icon size
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            .padding(.top, 10)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(color)
                .padding(.bottom, 5)
        }
        .frame(width: 110, height: 110)
        .background(Color(Colors.cardBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(Colors.cardBorder), lineWidth: 1))
    }
}

// Rounded card with an optional background image
struct Card: View {
    let content: AnyView
    let backgroundColor: Color
    let padding: EdgeInsets
    let backgroundImage: NSImage?
    let gradientOpacity: Double  // Added parameter for gradient opacity
    
    init(content: AnyView, backgroundColor: Color, padding: EdgeInsets, backgroundImage: NSImage?, gradientOpacity: Double = 0.8) {
        self.content = content
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.backgroundImage = backgroundImage
        self.gradientOpacity = gradientOpacity
    }
    
    var body: some View {
        ZStack {
            if let image = backgroundImage {
                GeometryReader { geometry in
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width * 1.5, height: geometry.size.height)
                        .position(x: geometry.size.width * 0.25, y: geometry.size.height / 2)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(gradientOpacity),
                                    Color.black.opacity(gradientOpacity * 0.8),
                                    Color.black.opacity(gradientOpacity * 0.6)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }
            }
            
            content
                .padding(padding)
                .frame(maxWidth: .infinity)
        }
        .background(backgroundImage == nil ? backgroundColor : Color.clear)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(Colors.cardBorder), lineWidth: 1))
    }
}

// Square icon button used for the power actions
struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 13))
                .frame(width: 30, height: 30)
                .background(Color(Colors.cardBackground))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(Colors.cardBorder), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// Borderless icon button used for media controls
struct MediaControlButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))  // Reduced from 16 to 12
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension CALayer {
    func animate(keyPath: String, from: CGFloat, to: CGFloat, duration: CGFloat) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        add(animation, forKey: keyPath)
    }
}
