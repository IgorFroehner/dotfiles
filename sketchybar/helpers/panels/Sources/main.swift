import AppKit
import SwiftUI

/// Which panel to show, from the `app=<panel>` argument.
enum PanelType: String {
    case menu
    case date
    case media

    /// The sketchybar item that opens this panel.
    var triggerItem: String {
        switch self {
        case .menu: return "apple.logo"
        case .date: return "time"
        case .media: return "spotify"
        }
    }

    /// Width in points. Fixed, since the content is laid out in fixed point sizes and a
    /// share of the screen width squeezes it on smaller displays.
    var width: CGFloat { self == .media ? 420 : 512 }

    /// The media panel opens on hover and closes once the mouse leaves it and its item;
    /// the others are toggled by clicking their item.
    var closesOnMouseExit: Bool { self == .media }

    /// Where the panel slides in from: the menu panel from the left edge, the date
    /// panel from the right. The media panel isn't animated (nil) and shows instantly.
    func slideOffset(width: CGFloat) -> CGFloat? {
        switch self {
        case .menu: return -width
        case .date: return width
        case .media: return nil
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var panel: PanelType = .menu

    /// How long the mouse can be away from a hover panel before it closes.
    private static let hoverGrace: TimeInterval = 0.3
    /// Slide-in and slide-out durations for the menu and date panels.
    private static let openDuration: TimeInterval = 0.08
    private static let closeDuration: TimeInterval = 0.08

    private var barHeight: CGFloat = 25
    /// Horizontal extent of the trigger item; clicks there are left to sketchybar's toggle.
    private var triggerXRange: ClosedRange<CGFloat>?
    /// Bottom edge of the bar, in AppKit coordinates.
    private var barBottom: CGFloat = 0
    private var lastHovered = Date()
    private var hoverTimer: Timer?
    private var isClosing = false
    private var terminationSource: DispatchSourceSignal?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let arg = CommandLine.arguments.dropFirst().first?.replacingOccurrences(of: "app=", with: "")
        panel = arg.flatMap(PanelType.init(rawValue:)) ?? .menu

        guard let window = makeWindow() else {
            NSApp.terminate(nil)
            return
        }
        self.window = window

        let content: AnyView
        switch panel {
        case .menu: content = AnyView(SystemPanelView())
        case .date: content = AnyView(CalendarPanelView())
        case .media: content = AnyView(MediaPanelView())
        }
        let hostingView = NSHostingView(rootView: AnyView(content.frame(width: window.frame.width)))

        // Shrink to the content's height, keeping the top edge just below the bar
        let frame = window.frame
        let height = min(hostingView.fittingSize.height, frame.height)
        window.setFrame(NSRect(x: frame.minX, y: frame.maxY - height, width: frame.width, height: height), display: false)
        window.contentView = hostingView
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = false
        window.level = .floating
        window.hasShadow = false

        let offscreenX = panel.slideOffset(width: window.frame.width)
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true
            contentView.layer?.backgroundColor = NSColor.clear.cgColor
            if let offscreenX = offscreenX {
                contentView.layer?.opacity = 0.0
                contentView.layer?.transform = CATransform3DMakeTranslation(offscreenX, 0, 0)
            }
        }

        window.makeKeyAndOrderFront(nil)

        if let offscreenX = offscreenX {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Self.openDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.contentView?.layer?.animate(keyPath: "transform.translation.x", from: offscreenX, to: 0, duration: context.duration)
                window.contentView?.layer?.animate(keyPath: "opacity", from: 0.0, to: 1.0, duration: context.duration)
            }
        }

        // Close on clicks anywhere else (global monitors only see clicks in other apps)
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, !self.isOnTriggerItem(NSEvent.mouseLocation) else { return }
            self.close()
        }

        if panel.closesOnMouseExit {
            trackHover()
        }

        // sketchybar's toggle sends SIGTERM; animate out instead of dying immediately
        signal(SIGTERM, SIG_IGN)
        terminationSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        terminationSource?.setEventHandler { [weak self] in self?.close() }
        terminationSource?.resume()
    }

    /// Builds the window below the bar on the display under the mouse (where the
    /// trigger item was clicked or hovered), or nil if the item isn't on that display.
    private func makeWindow() -> NSWindow? {
        if let height = runJSONCommand(["sketchybar", "--query", "bar"])?["height"] as? Double {
            barHeight = CGFloat(height)
        }
        // window_gap from settings.lua, passed in by ui.lua
        let gapSize = CGFloat(Double(ProcessInfo.processInfo.environment["WINDOW_GAP"] ?? "") ?? 0)

        // sketchybar reports global coordinates with the origin at the primary display's
        // top-left and y pointing down; AppKit's origin is its bottom-left.
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let mouse = NSEvent.mouseLocation

        // The item's rect on the display under the mouse, found by its center point
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }),
              let item = runJSONCommand(["sketchybar", "--query", panel.triggerItem]),
              let boundingRects = item["bounding_rects"] as? [String: Any],
              let itemRect = boundingRects.values.lazy
                  .compactMap({ rect -> ([Double], [Double])? in
                      guard let rect = rect as? [String: Any],
                            let origin = rect["origin"] as? [Double], origin.count == 2,
                            let size = rect["size"] as? [Double], size.count == 2
                      else { return nil }
                      return (origin, size)
                  })
                  .first(where: { origin, size in
                      let center = NSPoint(x: origin[0] + size[0] / 2, y: primaryHeight - (origin[1] + size[1] / 2))
                      return NSMouseInRect(center, screen.frame, false)
                  })
        else { return nil }

        let (origin, size) = itemRect
        let displayX = screen.frame.minX
        let displayWidth = screen.frame.width
        let displayTop = screen.frame.maxY
        let displayBottom = screen.frame.minY
        triggerXRange = origin[0]...(origin[0] + size[0])
        barBottom = displayTop - barHeight

        // Hangs from just below the bar and gap; the height is the most it can get,
        // shrunk to fit its content afterwards.
        let width = panel.width
        let top = displayTop - (barHeight + gapSize)
        let height = top - displayBottom - gapSize
        let x: CGFloat
        switch panel {
        case .menu:
            x = displayX + gapSize - 1
        case .date:
            x = displayX + displayWidth - width - (gapSize - 1)
        case .media:
            // Lined up with the item's left edge, kept on screen
            x = min(max(origin[0], displayX + gapSize), displayX + displayWidth - width - gapSize)
        }

        return NSWindow(
            contentRect: NSRect(x: x, y: top - height + 2, width: width, height: height),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
    }

    private func isOnTriggerItem(_ point: NSPoint) -> Bool {
        guard let range = triggerXRange,
              let screen = NSScreen.screens.first(where: { $0.frame.contains(point) })
        else { return false }
        return screen.frame.maxY - point.y <= barHeight && range.contains(point.x)
    }

    /// Closes the panel once the mouse has been away from it and its item for the grace
    /// period. The gap between the bar and the panel counts as part of the panel, so
    /// moving from the item down into it doesn't close it.
    private func trackHover() {
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let frame = self.window?.frame else { return }
            let mouse = NSEvent.mouseLocation
            let hoverArea = NSRect(x: frame.minX, y: frame.minY, width: frame.width, height: self.barBottom - frame.minY + 1)
            if hoverArea.contains(mouse) || self.isOnTriggerItem(mouse) {
                self.lastHovered = Date()
            } else if Date().timeIntervalSince(self.lastHovered) > Self.hoverGrace {
                self.close()
            }
        }
    }

    func close() {
        guard !isClosing else { return }
        isClosing = true
        animateWindowClose {
            NSApp.terminate(nil)
        }
    }

    private func animateWindowClose(completion: @escaping () -> Void) {
        guard let contentView = window?.contentView,
              let width = window?.frame.width,
              let offscreenX = panel.slideOffset(width: width)
        else {
            completion()
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Self.closeDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            contentView.layer?.animate(
                keyPath: "transform.translation.x",
                from: 0,
                to: offscreenX,
                duration: context.duration
            )
            contentView.layer?.animate(keyPath: "opacity", from: 1.0, to: 0.0, duration: context.duration)
        }, completionHandler: completion)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
