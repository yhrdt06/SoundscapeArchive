import Foundation
import CoreLocation

/// GPS coordinate with optional metadata
struct GeoLocation: Codable, Equatable, Hashable {
    /// Latitude in degrees (-90 to 90)
    let latitude: Double

    /// Longitude in degrees (-180 to 180)
    let longitude: Double

    /// Altitude in meters
    let altitude: Double?

    /// GPS accuracy in meters
    let accuracy: Double?

    init(
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        accuracy: Double? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
    }

    /// Convert to CLLocationCoordinate2D for MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Create from CLLocation
    static func from(_ location: CLLocation) -> GeoLocation {
        GeoLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            accuracy: location.horizontalAccuracy
        )
    }

    /// Check if coordinate is valid
    var isValid: Bool {
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    }
}
