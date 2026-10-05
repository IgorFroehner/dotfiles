import AppKit
import SwiftUI

/// Which panel to show, from the `app=<panel>` argument.
enum PanelType: String {
    case menu
    case date

    /// The sketchybar item that toggles this panel.
    var triggerItem: String { self == .menu ? "apple.logo" : "time" }

    /// The menu panel slides in from the left edge, the date panel from the right.
    var slidesFromLeft: Bool { self == .menu }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var panel: PanelType = .menu

    private var barHeight: CGFloat = 25
    /// Horizontal extent of the trigger item; clicks there are left to sketchybar's toggle.
    private var triggerXRange: ClosedRange<CGFloat>?
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

        let content = panel == .menu ? AnyView(SystemPanelView()) : AnyView(CalendarPanelView())
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

        let offscreenX = panel.slidesFromLeft ? -window.frame.width : window.frame.width
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true
            contentView.layer?.backgroundColor = NSColor.clear.cgColor
            contentView.layer?.opacity = 0.0
            contentView.layer?.transform = CATransform3DMakeTranslation(offscreenX, 0, 0)
        }

        window.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.contentView?.layer?.animate(keyPath: "transform.translation.x", from: offscreenX, to: 0, duration: context.duration)
            window.contentView?.layer?.animate(keyPath: "opacity", from: 0.0, to: 1.0, duration: context.duration)
        }

        // Close on clicks anywhere else (global monitors only see clicks in other apps)
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, !self.isOnTriggerItem(NSEvent.mouseLocation) else { return }
            self.close()
        }

        // sketchybar's toggle sends SIGTERM; animate out instead of dying immediately
        signal(SIGTERM, SIG_IGN)
        terminationSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        terminationSource?.setEventHandler { [weak self] in self?.close() }
        terminationSource?.resume()
    }

    /// Builds the window below the bar on the focused yabai display, or nil if the
    /// trigger item isn't on that display.
    private func makeWindow() -> NSWindow? {
        if let height = runJSONCommand(["sketchybar", "--query", "bar"])?["height"] as? Double {
            barHeight = CGFloat(height)
        }
        let gapOutput = String(decoding: runCommand(["yabai", "-m", "config", "window_gap"]), as: UTF8.self)
        let gapSize = CGFloat(Int(gapOutput.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)

        guard let display = runJSONCommand(["yabai", "-m", "query", "--displays", "--display"]),
              let displayIndex = display["index"] as? Int,
              let frame = display["frame"] as? [String: Double],
              let item = runJSONCommand(["sketchybar", "--query", panel.triggerItem]),
              let boundingRects = item["bounding_rects"] as? [String: Any],
              let displayRect = boundingRects["display-\(displayIndex)"] as? [String: Any],
              let origin = displayRect["origin"] as? [Double],
              let size = displayRect["size"] as? [Double]
        else { return nil }

        let displayX = CGFloat(frame["x"] ?? 0)
        let displayWidth = CGFloat(frame["w"] ?? 0)
        let displayHeight = CGFloat(frame["h"] ?? 0)
        triggerXRange = (displayX + origin[0])...(displayX + origin[0] + size[0])

        // 20% of the screen wide, hanging from just below the bar and gap. This is the
        // largest the panel can get; it's shrunk to fit its content afterwards.
        let width = displayWidth * 0.20
        let top = displayHeight - (barHeight + gapSize)
        let height = top - gapSize
        let x = panel.slidesFromLeft
            ? displayX + gapSize - 1
            : displayX + displayWidth - width - (gapSize - 1)

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

    func close() {
        guard !isClosing else { return }
        isClosing = true
        animateWindowClose {
            NSApp.terminate(nil)
        }
    }

    private func animateWindowClose(completion: @escaping () -> Void) {
        guard let contentView = window?.contentView, let width = window?.frame.width else {
            completion()
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            contentView.layer?.animate(
                keyPath: "transform.translation.x",
                from: 0,
                to: panel.slidesFromLeft ? -width : width,
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
