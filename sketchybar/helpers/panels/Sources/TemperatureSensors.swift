import Foundation

/// Temperatures in °C
struct Temperatures {
    /// The hottest sensor on the chip's die
    let chip: Double
    let ssd: Double?
    let battery: Double?
}

/// Reads the temperature sensors Apple Silicon exposes through the HID event system, the
/// same source `powermetrics` uses but readable without root, and with no per-chip SMC key
/// tables to keep up. The API is private, so it's looked up at runtime; without it, or on
/// Intel Macs, there are no readings.
final class TemperatureSensors {
    private typealias CreateClient = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
    private typealias SetMatching = @convention(c) (AnyObject, CFDictionary) -> Int32
    private typealias CopyServices = @convention(c) (AnyObject) -> Unmanaged<CFArray>?
    private typealias CopyProperty = @convention(c) (AnyObject, CFString) -> Unmanaged<AnyObject>?
    private typealias CopyEvent = @convention(c) (AnyObject, Int64, Int32, Int64) -> Unmanaged<AnyObject>?
    private typealias GetFloatValue = @convention(c) (AnyObject, Int32) -> Double

    private static let temperatureEvent: Int64 = 15 // kIOHIDEventTypeTemperature
    private static let temperatureField = Int32(temperatureEvent << 16)

    private let copyEvent: CopyEvent
    private let getFloatValue: GetFloatValue
    /// Kept alive alongside its services
    private let client: AnyObject
    private let sensors: [(name: String, service: AnyObject)]

    init?() {
        let handle = UnsafeMutableRawPointer(bitPattern: -2) // RTLD_DEFAULT
        func load<T>(_ name: String, as type: T.Type) -> T? {
            dlsym(handle, name).map { unsafeBitCast($0, to: type) }
        }
        guard let createClient = load("IOHIDEventSystemClientCreate", as: CreateClient.self),
              let setMatching = load("IOHIDEventSystemClientSetMatching", as: SetMatching.self),
              let copyServices = load("IOHIDEventSystemClientCopyServices", as: CopyServices.self),
              let copyProperty = load("IOHIDServiceClientCopyProperty", as: CopyProperty.self),
              let copyEvent = load("IOHIDServiceClientCopyEvent", as: CopyEvent.self),
              let getFloatValue = load("IOHIDEventGetFloatValue", as: GetFloatValue.self),
              let client = createClient(kCFAllocatorDefault)?.takeRetainedValue()
        else { return nil }

        // Apple vendor usage page, temperature sensor usage
        _ = setMatching(client, ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5] as CFDictionary)
        let services = copyServices(client)?.takeRetainedValue() as? [AnyObject] ?? []

        self.copyEvent = copyEvent
        self.getFloatValue = getFloatValue
        self.client = client
        self.sensors = services.compactMap { service in
            guard let name = copyProperty(service, "Product" as CFString)?.takeRetainedValue() as? String
            else { return nil }
            return (name, service)
        }
    }

    /// nil when no die sensor reads, as on Intel Macs
    func read() -> Temperatures? {
        var chip: [Double] = [], ssd: [Double] = [], battery: [Double] = []
        for (name, service) in sensors {
            guard let event = copyEvent(service, Self.temperatureEvent, 0, 0)?.takeRetainedValue() else { continue }
            let value = getFloatValue(event, Self.temperatureField)
            // Some sensors report nonsense (one reads -9201 °C on an M5)
            guard value > 0, value < 150 else { continue }

            // "PMU tdie1" on M2 and later, "pACC MTR Temp Sensor1" and the like on M1
            if name.contains("tdie") || name.contains("ACC MTR") {
                chip.append(value)
            } else if name.hasPrefix("NAND") {
                ssd.append(value)
            } else if name.hasPrefix("gas gauge battery") {
                battery.append(value)
            }
        }
        guard let hottest = chip.max() else { return nil }
        return Temperatures(chip: hottest, ssd: ssd.max(), battery: battery.max())
    }
}
