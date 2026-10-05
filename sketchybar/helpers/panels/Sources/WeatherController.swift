import Foundation

/// Current weather from Open-Meteo (no API key needed).
///
/// The location comes from `weather_city` in settings.lua (passed in as WEATHER_CITY) via
/// Open-Meteo's geocoding, or from the IP address when it's unset or can't be found.
class WeatherController: ObservableObject {
    @Published var currentTemp: Double?
    @Published var condition: String = ""
    @Published var weatherIcon: String = "cloud.sun.fill"

    private var timer: Timer?
    private let city = ProcessInfo.processInfo.environment["WEATHER_CITY"].flatMap { $0.isEmpty ? nil : $0 }

    init() {
        updateWeather()
        // Update weather every 30 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.updateWeather()
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func updateWeather() {
        resolveLocation { [weak self] location in
            guard let location = location else {
                self?.showUnavailable()
                return
            }
            self?.fetchWeather(at: location)
        }
    }

    // MARK: - Location

    private func resolveLocation(completion: @escaping (Location?) -> Void) {
        guard let city = city,
              let query = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(query)&count=1")
        else {
            locateByIP(completion: completion)
            return
        }
        fetch(GeocodingResponse.self, from: url) { [weak self] response in
            if let place = response?.results?.first {
                completion(Location(name: place.name, latitude: place.latitude, longitude: place.longitude))
            } else {
                self?.locateByIP(completion: completion)
            }
        }
    }

    private func locateByIP(completion: @escaping (Location?) -> Void) {
        fetch(IPLocationResponse.self, from: URL(string: "https://ipwho.is/")!) { response in
            guard let response = response, response.success,
                  let latitude = response.latitude, let longitude = response.longitude
            else {
                completion(nil)
                return
            }
            completion(Location(name: response.city ?? "", latitude: latitude, longitude: longitude))
        }
    }

    // MARK: - Weather

    private func fetchWeather(at location: Location) {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(location.latitude)&longitude=\(location.longitude)&current=temperature_2m,weather_code,is_day")!
        fetch(ForecastResponse.self, from: url) { [weak self] response in
            guard let self = self, let current = response?.current else {
                self?.showUnavailable()
                return
            }
            let (description, icon) = Self.describe(code: current.weather_code, isDay: current.is_day == 1)
            self.currentTemp = current.temperature_2m
            self.weatherIcon = icon
            self.condition = location.name.isEmpty ? description : "\(description) · \(location.name)"
        }
    }

    private func showUnavailable() {
        currentTemp = nil
        condition = "Weather unavailable"
    }

    /// Description and SF Symbol for a WMO weather code (https://open-meteo.com/en/docs).
    private static func describe(code: Int, isDay: Bool) -> (String, String) {
        switch code {
        case 0: return ("Clear", isDay ? "sun.max.fill" : "moon.stars.fill")
        case 1: return ("Mainly clear", isDay ? "sun.max.fill" : "moon.stars.fill")
        case 2: return ("Partly cloudy", isDay ? "cloud.sun.fill" : "cloud.moon.fill")
        case 3: return ("Overcast", "cloud.fill")
        case 45, 48: return ("Fog", "cloud.fog.fill")
        case 51, 53, 55: return ("Drizzle", "cloud.drizzle.fill")
        case 56, 57: return ("Freezing drizzle", "cloud.sleet.fill")
        case 61, 63: return ("Rain", "cloud.rain.fill")
        case 65: return ("Heavy rain", "cloud.heavyrain.fill")
        case 66, 67: return ("Freezing rain", "cloud.sleet.fill")
        case 71, 73, 75, 77: return ("Snow", "cloud.snow.fill")
        case 80, 81: return ("Rain showers", isDay ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill")
        case 82: return ("Heavy showers", "cloud.heavyrain.fill")
        case 85, 86: return ("Snow showers", "cloud.snow.fill")
        case 95: return ("Thunderstorm", "cloud.bolt.rain.fill")
        case 96, 99: return ("Thunderstorm with hail", "cloud.bolt.rain.fill")
        default: return ("Unknown", "cloud.fill")
        }
    }

    // MARK: - Networking

    /// Fetches and decodes JSON, calling back on the main queue with nil on any failure.
    private func fetch<T: Decodable>(_ type: T.Type, from url: URL, completion: @escaping (T?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let value = data.flatMap { try? JSONDecoder().decode(T.self, from: $0) }
            DispatchQueue.main.async { completion(value) }
        }.resume()
    }
}

private struct Location {
    let name: String
    let latitude: Double
    let longitude: Double
}

// Open-Meteo and ipwho.is response structures (only the fields used)
private struct GeocodingResponse: Decodable {
    struct Place: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
    }
    let results: [Place]?
}

private struct IPLocationResponse: Decodable {
    let success: Bool
    let city: String?
    let latitude: Double?
    let longitude: Double?
}

private struct ForecastResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let weather_code: Int
        let is_day: Int
    }
    let current: Current
}
