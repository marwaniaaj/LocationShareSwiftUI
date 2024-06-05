//
//  ShareViewController.swift
//  Extension
//
//  Created by Marwa Abou Niaaj on 31/05/2024.
//

import UIKit
import UniformTypeIdentifiers
import SwiftUI

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            self.dismiss()
            return
        }

        Task {
            await handleAttachments(extensionItem.attachments)
        }
    }

    private func handleAttachments(_ attachments: [NSItemProvider]?) async {
        if let mapKitItem = attachments?.first(where: { $0.hasItemConformingToTypeIdentifier("com.apple.mapkit.map-item") }) {
            hostMapsShareView(itemProvider: mapKitItem, itemType: .appleMaps)
        }
        else
        if let googleMapItem = attachments?.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            let itemType = await ExtensionManager.shared.handleUrlType(for: googleMapItem)
            if itemType == .googleMaps {
                hostMapsShareView(itemProvider: googleMapItem, itemType: .googleMaps)
            } else if itemType == .link {
                // TODO: Handle link url
            } else {
                self.dismiss()
            }
        } else {
            self.dismiss()
        }
    }

    private func hostMapsShareView(itemProvider: NSItemProvider, itemType: ItemType) {
        let hostingView = UIHostingController(rootView: MapsShareView(
                                    itemProvider: itemProvider,
                                    extensionContext: extensionContext,
                                    itemType: itemType
                                ))
        hostingView.view.frame = view.frame
        addChild(hostingView)
        view.addSubview(hostingView.view)

        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        hostingView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        hostingView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
        hostingView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        hostingView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
    }

    func dismiss() {
        self.extensionContext?.completeRequest(returningItems: [])
    }
}

extension NSItemProvider: @unchecked Sendable {}
