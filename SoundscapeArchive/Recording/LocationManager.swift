import Foundation
import CoreLocation

/// Location manager for GPS coordinate capture
@MainActor
@Observable
final class LocationManager: NSObject {
    // MARK: - State

    private(set) var currentLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var isUpdating = false
    private(set) var error: LocationError?

    // MARK: - Private

    private let manager = CLLocationManager()

    // MARK: - Init

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // Update every 10 meters
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public Methods

    /// Request location permission
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Start updating location
    func startUpdating() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            error = .permissionDenied
            return
        }

        error = nil
        isUpdating = true
        manager.startUpdatingLocation()
    }

    /// Stop updating location
    func stopUpdating() {
        manager.stopUpdatingLocation()
        isUpdating = false
    }

    /// Convert to GeoLocation model
    func toGeoLocation() -> GeoLocation? {
        guard let location = currentLocation else { return nil }
        return GeoLocation.from(location)
    }

    /// Check if location services are enabled
    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }

    /// Check if we have permission
    var hasPermission: Bool {
        authorizationStatus == .authorizedWhenInUse ||
        authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            self.error = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.error = .permissionDenied
                case .locationUnknown:
                    self.error = .locationUnknown
                default:
                    self.error = .unknown(error.localizedDescription)
                }
            } else {
                self.error = .unknown(error.localizedDescription)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus

            // Auto-start if permission granted while waiting
            if self.authorizationStatus == .authorizedWhenInUse ||
               self.authorizationStatus == .authorizedAlways {
                if self.isUpdating {
                    manager.startUpdatingLocation()
                }
            }
        }
    }
}

// MARK: - Location Errors

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationUnknown
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置情報へのアクセスが許可されていません"
        case .locationUnknown:
            return "現在地を取得できませんでした"
        case .unknown(let message):
            return message
        }
    }
}
