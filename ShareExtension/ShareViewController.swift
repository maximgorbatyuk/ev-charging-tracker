//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import UIKit
import SwiftUI
import os

class ShareViewController: UIViewController {

    private let logger = Logger(subsystem: "ShareExtension", category: "ShareViewController")
    private let inputParser = InputParser()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Gate: ensure migration has completed before accessing shared DB
        guard DatabaseMigrationHelper.isMigrationCompleted() else {
            logger.warning("Migration not yet completed — showing blocking message")
            presentMigrationRequiredView()
            return
        }

        parseAndPresent()
    }

    private func parseAndPresent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            logger.error("No extension items found")
            cancelRequest(error: nil)
            return
        }

        Task { @MainActor in
            // Parse shared content
            guard let input = await inputParser.parse(inputItems: extensionItems) else {
                logger.error("Could not parse shared content")
                cancelRequest(error: nil)
                return
            }

            // Load cars from shared database
            let cars = DatabaseManager.shared.carRepository?.getAllCars() ?? []

            // Build ViewModel
            let viewModel = ShareFormViewModel()
            viewModel.configure(input: input, cars: cars)
            viewModel.onComplete = { [weak self] in
                self?.completeRequest()
            }
            viewModel.onCancel = { [weak self] in
                self?.cancelRequest(error: nil)
            }

            // Present SwiftUI form
            let formView = ShareFormView(viewModel: viewModel)
            let hostingController = UIHostingController(rootView: formView)

            addChild(hostingController)
            view.addSubview(hostingController.view)

            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

            hostingController.didMove(toParent: self)
        }
    }

    private func presentMigrationRequiredView() {
        let migrationView = VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(L("share.migration_required.title"))
                .font(.headline)
            Text(L("share.migration_required.message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(L("share.migration_required.dismiss")) { [weak self] in
                self?.cancelRequest(error: nil)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        let hostingController = UIHostingController(rootView: migrationView)
        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func cancelRequest(error: Error?) {
        let cancelError = error ?? NSError(
            domain: NSCocoaErrorDomain,
            code: NSUserCancelledError
        )
        extensionContext?.cancelRequest(withError: cancelError)
    }
}
