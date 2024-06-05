//
//  LocationItem.swift
//  LocationShare
//
//  Created by Marwa Abou Niaaj on 31/05/2024.
//

//import Foundation
import MapKit

struct LocationItem: Identifiable {
    var id: UUID? { UUID() }
    var name: String?
    var address: String?

    var phoneNumber: String?
    var website: String?

    var placeId: String?

    var latitude: Double
    var longitude: Double

    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    var locationName: String {
        return name ?? "Undefined Location"
    }
}
