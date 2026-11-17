import AppKit
import Combine
import Darwin
import IOKit.ps

/// One app's memory use, with its helper processes counted in.
struct AppMemory: Identifiable {
    /// The app bundle or executable path the processes are grouped by
    let id: String
    let name: String
    let icon: NSImage
    let bytes: UInt64
}

/// Machine info and usage stats for the Apple logo panel, polled while it's open.
class StatsController: ObservableObject {
    static let topAppCount = 5

    let chip = sysctlString("machdep.cpu.brand_string") ?? "Mac"
    let osVersion: String = {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let patch = version.patchVersion > 0 ? ".\(version.patchVersion)" : ""
        return "macOS \(version.majorVersion).\(version.minorVersion)\(patch)"
    }()
    let cores = ProcessInfo.processInfo.activeProcessorCount
    let memoryTotal = ProcessInfo.processInfo.physicalMemory

    @Published private(set) var cpuUsage = 0.0
    @Published private(set) var loadAverage: [Double] = [0, 0, 0]
    /// Memory used as Activity Monitor counts it: app memory, wired and compressed
    @Published private(set) var memoryUsed: UInt64 = 0
    @Published private(set) var swapUsed: UInt64 = 0
    @Published private(set) var diskTotal: Int64 = 0
    @Published private(set) var diskFree: Int64 = 0
    @Published private(set) var uptime: TimeInterval = 0
    /// nil on Macs without a battery
    @Published private(set) var batteryLevel: Double?
    @Published private(set) var isOnACPower = false
    @Published private(set) var topApps: [AppMemory] = []

    private let bootTime = StatsController.readBootTime()
    private var timer: Timer?
    private var previousTicks: [Double]?
    private var icons: [String: NSImage] = [:]

    init() {
        // Filled in synchronously, since the panel is sized to its content when it opens.
        // Disk space barely moves while the panel is open, so it's only read here.
        updateDisk()
        update()
        // CPU usage needs a second sample, so take one shortly instead of showing 0% for a tick
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in self?.update() }
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func update() {
        updateCPU()
        updateMemory()
        updateBattery()
        updateTopApps()
        if let bootTime = bootTime {
            uptime = Date().timeIntervalSince(bootTime)
        }
    }

    // MARK: - CPU

    private func updateCPU() {
        var info = host_cpu_load_info()
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        if result == KERN_SUCCESS {
            // user, system, idle, nice
            let ticks = [info.cpu_ticks.0, info.cpu_ticks.1, info.cpu_ticks.2, info.cpu_ticks.3].map(Double.init)
            if let previous = previousTicks {
                let diff = zip(ticks, previous).map { $0 - $1 }
                let total = diff.reduce(0, +)
                cpuUsage = total > 0 ? (total - diff[2]) / total : 0
            }
            previousTicks = ticks
        }

        var loads = [Double](repeating: 0, count: 3)
        if getloadavg(&loads, 3) == 3 {
            loadAverage = loads
        }
    }

    // MARK: - Memory

    private func updateMemory() {
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }
        if result == KERN_SUCCESS {
            let internalPages = UInt64(stats.internal_page_count)
            let purgeablePages = UInt64(stats.purgeable_count)
            let appPages = internalPages > purgeablePages ? internalPages - purgeablePages : 0
            let pages = appPages + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
            memoryUsed = pages * UInt64(vm_kernel_page_size)
        }

        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0) == 0 {
            swapUsed = swap.xsu_used
        }
    }

    // MARK: - Disk and battery

    private func updateDisk() {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys) else { return }
        diskTotal = Int64(values.volumeTotalCapacity ?? 0)
        diskFree = values.volumeAvailableCapacityForImportantUsage ?? 0
    }

    private func updateBattery() {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
            else { continue }
            batteryLevel = (description[kIOPSCurrentCapacityKey] as? Double ?? 0) / 100
            isOnACPower = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
            return
        }
        batteryLevel = nil
    }

    // MARK: - Top apps

    /// Sums each process's memory footprint (the "Memory" column in Activity Monitor) into
    /// the app it belongs to. Only your own processes can be read without root, so system
    /// daemons and WindowServer are left out.
    private func updateTopApps() {
        var footprints: [String: UInt64] = [:]
        for pid in Self.allPIDs() {
            var usage = rusage_info_v4()
            let result = withUnsafeMutablePointer(to: &usage) {
                $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                    proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
                }
            }
            guard result == 0, let path = Self.executablePath(pid) else { continue }
            footprints[Self.owner(ofProcess: pid, at: path), default: 0] += usage.ri_phys_footprint
        }

        topApps = footprints
            .sorted { $0.value > $1.value }
            .prefix(Self.topAppCount)
            .map { path, bytes in
                AppMemory(id: path, name: Self.displayName(for: path), icon: icon(for: path), bytes: bytes)
            }
    }

    private func icon(for path: String) -> NSImage {
        if let icon = icons[path] { return icon }
        let icon = NSWorkspace.shared.icon(forFile: path)
        icons[path] = icon
        return icon
    }

    /// What a process's memory counts toward: the app bundle it lives in, so helpers count
    /// toward their app, or for XPC services outside any app (WebKit pages, Virtualization
    /// VMs), the app responsible for them. Other processes stand on their own.
    private static func owner(ofProcess pid: pid_t, at path: String) -> String {
        if let app = appBundle(containing: path) {
            return app
        }
        if path.contains(".xpc/"),
           let responsible = responsiblePID?(pid), responsible != pid,
           let responsiblePath = executablePath(responsible),
           let app = appBundle(containing: responsiblePath) {
            return app
        }
        return path
    }

    /// The outermost .app bundle in a path
    private static func appBundle(containing path: String) -> String? {
        guard let range = path.range(of: ".app/") else { return nil }
        return String(path[..<range.lowerBound]) + ".app"
    }

    /// The app's name, or the executable's. Versioned binaries such as
    /// ~/.local/share/claude/versions/2.1.3 are named after the tool they belong to.
    private static func displayName(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        if url.pathExtension == "app" {
            return url.deletingPathExtension().lastPathComponent
        }
        return url.pathComponents.reversed().first {
            $0.rangeOfCharacter(from: .letters) != nil && $0 != "versions"
        } ?? url.lastPathComponent
    }

    /// libsystem's private lookup Activity Monitor uses to tie XPC services to the app that
    /// launched them. Optional: without it, those services are listed by their own name.
    private static let responsiblePID: (@convention(c) (pid_t) -> pid_t)? = {
        let defaultHandle = UnsafeMutableRawPointer(bitPattern: -2) // RTLD_DEFAULT
        guard let symbol = dlsym(defaultHandle, "responsibility_get_pid_responsible_for_pid") else { return nil }
        return unsafeBitCast(symbol, to: (@convention(c) (pid_t) -> pid_t).self)
    }()

    private static func allPIDs() -> [pid_t] {
        let estimate = proc_listallpids(nil, 0)
        guard estimate > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(estimate) + 32)
        let count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        return pids.prefix(max(0, Int(count))).filter { $0 > 0 }
    }

    private static func executablePath(_ pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return String(cString: buffer)
    }

    private static func readBootTime() -> Date? {
        var time = timeval()
        var size = MemoryLayout<timeval>.size
        guard sysctlbyname("kern.boottime", &time, &size, nil, 0) == 0 else { return nil }
        return Date(timeIntervalSince1970: Double(time.tv_sec) + Double(time.tv_usec) / 1_000_000)
    }
}

private func sysctlString(_ name: String) -> String? {
    var size = 0
    guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
    var buffer = [CChar](repeating: 0, count: size)
    guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
    return String(cString: buffer)
}
