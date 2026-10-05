import Foundation
import IOKit.ps
import AudioToolbox
import CoreAudio

/// Memory, CPU, battery and volume levels, polled while the panel is open.
class StatsController: ObservableObject {
    @Published private(set) var memoryUsage: Double = 0.0
    @Published private(set) var cpuUsage: Double = 0.0
    @Published private(set) var batteryLevel: Double = 0.0
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var volumeLevel: Double = 0.0
    @Published private(set) var isMuted: Bool = false
    
    private var generalTimer: Timer?
    private var cpuTimer: Timer?
    private var previousTicks: (user: Float, system: Float, idle: Float, nice: Float)?


    init() {
        // General stats updated every second
        generalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateGeneralStats()
        }
        updateGeneralStats()

        // CPU usage updated more frequently
        cpuTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateCPUUsage()
        }
        updateCPUUsage()
    }

    private func updateGeneralStats() {
        updateMemoryUsage()
        updateBatteryStatus()
        updateVolumeLevel()
    }

    private func updateMemoryUsage() {
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { pointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, pointer, &size)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = vm_kernel_page_size // Memory page size in bytes
            let total = Double(stats.active_count + stats.inactive_count + stats.wire_count + stats.free_count) * Double(pageSize)
            let used = Double(stats.active_count + stats.wire_count) * Double(pageSize) // Consider only active and wired memory as "used"
            
            DispatchQueue.main.async {
                self.memoryUsage = used / total // Used as a fraction of total
            }
        } else {
            print("Failed to fetch VM statistics, error code: \(result)")
        }
    } 

    private func updateCPUUsage() {
        var hostInfo = host_cpu_load_info()
        var size = mach_msg_type_number_t(MemoryLayout.size(ofValue: hostInfo) / MemoryLayout<Int32>.size)
        let result = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        
        if result == KERN_SUCCESS {
            let user = Float(hostInfo.cpu_ticks.0)
            let system = Float(hostInfo.cpu_ticks.1)
            let idle = Float(hostInfo.cpu_ticks.2)
            let nice = Float(hostInfo.cpu_ticks.3)
            
            if let previous = previousTicks {
                let userDiff = user - previous.user
                let systemDiff = system - previous.system
                let idleDiff = idle - previous.idle
                let niceDiff = nice - previous.nice
                
                let totalDiff = userDiff + systemDiff + idleDiff + niceDiff
                
                if totalDiff > 0 {
                    let usage = (userDiff + systemDiff + niceDiff) / totalDiff
                    DispatchQueue.main.async {
                        self.cpuUsage = Double(usage)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.cpuUsage = 0.0 // Default value when no usage can be calculated
                    }
                }
            }
            
            // Save the current values for the next calculation
            previousTicks = (user: user, system: system, idle: idle, nice: nice)
        } else {
            print("Failed to fetch CPU statistics: \(result)")
        }
    }

    private func updateBatteryStatus() {
        if let powerSource = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(powerSource)?.takeRetainedValue() as? [CFTypeRef] {
            
            for source in sources {
                if let description = IOPSGetPowerSourceDescription(powerSource, source)?.takeUnretainedValue() as? [String: Any] {
                    DispatchQueue.main.async {
                        self.batteryLevel = (description[kIOPSCurrentCapacityKey] as? Double ?? 0) / 100.0
                        self.isCharging = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
                    }
                }
            }
        }
    }
    
    private func updateVolumeLevel() {
        var deviceSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var defaultOutputDevice = kAudioObjectUnknown
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get default output device
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &deviceSize,
            &defaultOutputDevice
        )
        
        // Get volume
        propertyAddress.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMainVolume
        propertyAddress.mScope = kAudioDevicePropertyScopeOutput
        
        var volume: Float32 = 0.0
        deviceSize = UInt32(MemoryLayout<Float32>.size)
        
        AudioObjectGetPropertyData(
            defaultOutputDevice,
            &propertyAddress,
            0,
            nil,
            &deviceSize,
            &volume
        )
        
        // Get mute status
        propertyAddress.mSelector = kAudioDevicePropertyMute
        
        var isMuted: UInt32 = 0
        deviceSize = UInt32(MemoryLayout<UInt32>.size)
        
        AudioObjectGetPropertyData(
            defaultOutputDevice,
            &propertyAddress,
            0,
            nil,
            &deviceSize,
            &isMuted
        )
        
        DispatchQueue.main.async {
            self.volumeLevel = Double(volume)
            self.isMuted = isMuted == 1
        }
    }
    
    deinit {
        generalTimer?.invalidate()
        cpuTimer?.invalidate()
    }
}
