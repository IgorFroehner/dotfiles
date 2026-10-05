import CoreLocation
import CoreWLAN

// Prints the current Wi-Fi network name, or nothing when disconnected or not permitted.
// Since macOS 14.4 the SSID is only readable with Location Services access, so the first
// run asks for it (System Settings › Privacy & Security › Location Services › SSID).

final class Delegate: NSObject, CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            report(manager)
        default:
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        report(manager)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        FileHandle.standardError.write("location error: \(error)\n".data(using: .utf8)!)
        report(manager)
    }

    func report(_ manager: CLLocationManager) {
        guard let ssid = CWWiFiClient.shared().interface()?.ssid() else {
            FileHandle.standardError.write("no SSID (location authorization: \(manager.authorizationStatus.rawValue))\n".data(using: .utf8)!)
            exit(1)
        }
        print(ssid)
        exit(0)
    }
}

let manager = CLLocationManager()
let delegate = Delegate()
manager.delegate = delegate

// Don't hang forever if the permission prompt is ignored
DispatchQueue.main.asyncAfter(deadline: .now() + 60) { exit(1) }
RunLoop.main.run()
