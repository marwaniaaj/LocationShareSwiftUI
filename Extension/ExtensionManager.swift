//
//  ExtensionManager.swift
//  Extension
//
//  Created by Marwa Abou Niaaj on 31/05/2024.
//

import Foundation
import MapKit
import UniformTypeIdentifiers
//

enum ItemType {
    case googleMaps
    case appleMaps
    case link
    case undefined
}

class ExtensionManager: ObservableObject {

    static let shared = ExtensionManager()
    // TODO: Replace with your API key
    private let apiKey = "<YOUR_API_KEY>"

    func handleUrlType(for itemProvider: NSItemProvider) async -> ItemType {
        do {
            let providedURL = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil)
            guard let providedURL = providedURL as? URL else { return .undefined }

            if let host = providedURL.host(), host.contains("maps.app.goo.gl") {
                return .googleMaps
            }
            return .link
        }
        catch {
            print("Unable to load item. \(error.localizedDescription)")
            return .undefined
        }
    }

    // MARK: - Apple Maps URL
    func handleAppleMapsItem(_ mapItem: MKMapItem) async -> LocationItem? {

        let appleMaps = LocationItem(
            name: mapItem.name,
            address: mapItem.placemark.title ?? "Unidentified",
            phoneNumber: mapItem.phoneNumber,
            website: mapItem.url?.absoluteString,
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude
        )

        return appleMaps
    }

    // MARK: - Google Maps URL
    func handleGoogleUrl(_ shareUrl: URL) async -> LocationItem? {
        guard let fullUrl = await getLongerUrl(for: shareUrl) else { return nil }
        guard let cid = extractCID(from: fullUrl) else { return nil }
        guard let googleMapsData = await fetchGoogleMapsData(cid: cid) else { return nil }
        return googleMapsData
    }

    private func getLongerUrl(for shareUrl: URL) async -> URL? {
        do {
            let session = URLSession(configuration: .default)
            var urlRequest = URLRequest(url: shareUrl)
            urlRequest.httpMethod = "HEAD"

            let (_, response) = try await session.data(for: urlRequest)
            print("Full URL: \(response.url?.absoluteString ?? "No URL found")")

            return response.url
        }
        catch {
            print("Error: \(error)")
            return nil
        }
    }

    private func extractCID(from googleURL: URL) -> String? {
        guard let host = googleURL.host(), host.contains("google") else {
            return nil
        }

        guard let urlComponents = URLComponents(url: googleURL, resolvingAgainstBaseURL: true) else {
            return nil
        }

        let queryItems = urlComponents.queryItems
        if let ftid = queryItems?.first(where: {$0.name == "ftid"})?.value {
            let subString = ftid.components(separatedBy: ":")
            if let cid = subString.last {
                print("CID: \(cid)")
                return cid
            }
        }
        return nil
    }

    private func fetchGoogleMapsData(cid: String) async -> LocationItem? {
        do {
            let placedDetailsURL = "https://maps.googleapis.com/maps/api/place/details/json?cid=\(cid)&key=\(apiKey)"

            guard let url = URL(string: placedDetailsURL) else { return nil }

            let session = URLSession(configuration: .default)
            let (data, _) = try await session.data(for: URLRequest(url: url))

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            guard let result = json["result"] as? [String: AnyObject] else {
                if let status = json["status"] as? String, let errorMessage = json["error_message"] as? String {
                    print("\(status): \(errorMessage)")
                }
                return nil
            }

            guard let result_types = result["types"] as? [String],
                  let place_id = result["place_id"] as? String,
                  let geometry = result["geometry"] as? [String: AnyObject],
                  let location = geometry["location"] as? [String: Double],
                  let latitude = location["lat"], let longitude = location["lng"]
            else {
                return nil
            }

            print("type: \(result_types)")
            let name = result["name"] as? String
            let address = result["formatted_address"] as? String
            let phone_number = result["international_phone_number"] as? String
            let website = result["website"] as? String

            let googleLocationItem = LocationItem(
                name: name, address: address,
                phoneNumber: phone_number, website: website, placeId: place_id,
                latitude: latitude, longitude: longitude
            )
            return googleLocationItem
        }
        catch {
            print("Error: \(error)")
            return nil
        }
    }
}
