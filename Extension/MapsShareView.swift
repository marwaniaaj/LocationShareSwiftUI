//
//  MapsShareView.swift
//  Extension
//
//  Created by Marwa Abou Niaaj on 31/05/2024.
//

import MapKit
import SwiftUI
import UniformTypeIdentifiers

struct MapsShareView: View {
    var itemProvider: NSItemProvider
    var extensionContext: NSExtensionContext?
    var itemType = ItemType.undefined

    @State private var locationItem: LocationItem? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)
                    .padding(16)

                if let locationItem {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(locationItem.locationName)
                            .font(.title3).bold()
                            .foregroundStyle(Color.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            if let address = locationItem.address {
                                HStack(alignment: .firstTextBaseline) {
                                    Image(systemName: "mappin")
                                        .padding(8)
                                        .foregroundStyle(Color.accentColor)
                                    Text(address)
                                }
                            }

                            if let phone = locationItem.phoneNumber {
                                HStack(alignment: .firstTextBaseline) {
                                    Image(systemName: "phone.fill")
                                        .padding(8)
                                        .foregroundStyle(Color.accentColor)
                                    Text(phone)
                                }
                            }

                            if let website = locationItem.website {
                                HStack(alignment: .firstTextBaseline) {
                                    Image(systemName: "safari.fill")
                                        .padding(8)
                                        .foregroundStyle(Color.accentColor)
                                    Text(website)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(10)
            .navigationTitle("Share Map Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel", action: dismiss)
                        .font(.body)
                        .tint(Color.accentColor)
                }
            }
            .onAppear {
                Task {
                    await loadMapsData()
                }
            }
        }
    }

    func dismiss() {
        extensionContext?.completeRequest(returningItems: [])
    }

    func loadMapsData() async {
        do {
            if itemType == .appleMaps && itemProvider.hasItemConformingToTypeIdentifier("com.apple.mapkit.map-item") {
                /// Apple Maps
                let item = try await itemProvider.loadItem(forTypeIdentifier: "com.apple.mapkit.map-item")
                guard let data = item as? Data else { return }
                do {
                    guard let mapItem = try NSKeyedUnarchiver.unarchivedObject(ofClass: MKMapItem.self, from: data as Data) else { return }
                    locationItem = await ExtensionManager.shared.handleAppleMapsItem(mapItem)
                } catch {
                    print("Error unarchiving mapItems. \(error)")
                }
            }
            else if itemType == .googleMaps && itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                /// Google Maps
                let item = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier)
                if let providedURL = item as? URL {
                    print("Provided URL: \(providedURL)")
                    locationItem = await ExtensionManager.shared.handleGoogleUrl(providedURL)
                }
            }
        }
        catch {
            print("Error loading map item: \(error)")
        }
    }
}
