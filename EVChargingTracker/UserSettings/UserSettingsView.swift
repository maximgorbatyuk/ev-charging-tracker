//
//  UserSettingsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

import SwiftUI
import StoreKit

struct UserSettingsView: SwiftUICore.View {

    @StateObject private var viewModel = UserSettingsViewModel()
    @State private var showEditCurrencyModal: Bool = false
    @State private var editingCar: CarDto? = nil
    @State private var isNotificationsEnabled: Bool = false

    @State private var showingAppAboutModal = false

    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var notificationsManager = NotificationManager.shared
    @ObservedObject private var environment = EnvironmentService.shared

    @Environment(\.requestReview) var requestReview

    var body: some SwiftUICore.View {
        NavigationView {

            Form {
                Section(header: Text(L("Base settings"))) {
                    HStack {
                        Picker(L("Language"), selection: $viewModel.selectedLanguage) {
                            ForEach(AppLanguage.allCases, id: \.self) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: viewModel.selectedLanguage) { _, newLang in
                            viewModel.saveLanguage(newLang)
                        }
                    }
                    
                    VStack {
                        HStack {
                            Text(L("Notifications enabled"))
                                .fontWeight(.semibold)
                                .font(.system(size: 16, weight: .bold))

                            Spacer()
                            
                            Toggle("", isOn: $isNotificationsEnabled)
                                .disabled(true)
                                .labelsHidden()
                        }

                        HStack {
                            Text(L("In case you want to change this setting, please open app settings"))
                                .foregroundColor(.secondary)

                            Spacer()
                            Button(L("Open settings")) {
                                notificationsManager.checkAndRequestPermission(
                                    completion: {
                                        openSettings()
                                    },
                                    onDeniedNotificationPermission: {
                                        openSettings()
                                    }
                                )
                            }
                        }
                        .font(.caption)
                    }

                    VStack {
                        HStack {
                            Text(L("Currency"))
                                .fontWeight(.semibold)
                                .font(.system(size: 16, weight: .bold))

                            Spacer()

                            if (!viewModel.hasAnyExpense()) {
                                Button(action: {
                                    showEditCurrencyModal = true
                                }) {
                                    Text("\(String(describing: viewModel.defaultCurrency).uppercased()) (\(viewModel.defaultCurrency.rawValue))")
                                        .fontWeight(.semibold)
                                        .font(.system(size: 16, weight: .bold))
                                }
                            } else {
                                Text("\(String(describing: viewModel.defaultCurrency).uppercased()) (\(viewModel.defaultCurrency.rawValue))")
                                    .fontWeight(.semibold)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack {
                            Text(L("It is recommended to set the default currency before adding any expenses."))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                if (viewModel.getCarsCount() > 0) {
                    Section(header: Text(L("Cars"))) {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.allCars) { car in
                                CarRecordView(
                                    car: car,
                                    onEdit: {
                                        editingCar = car
                                    })
                            }
                        }
                    }
                }

                Section(header: Text(L("Support"))) {
                    Button(action: {
                        showingAppAboutModal = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.green)

                            Text(L("What is the app about?"))
                                .padding(.leading, 4)
                                .foregroundColor(.primary)
                        }
                    }

                    Button {
                        requestReview()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)

                            Text(L("Rate the app"))
                                .padding(.leading, 4)
                                .foregroundColor(.primary)
                        }
                    }

                    Link(destination: URL(string: environment.getDeveloperTelegramLink())!) {
                        HStack {
                            Image(systemName: "ellipses.bubble.fill")
                                .foregroundColor(.blue)

                            Text(L("Contact developer via Telegram"))
                                .padding(.leading, 4)
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section(header: Text(L("About app"))) {
                    HStack {
                        Label(L("App version"), systemImage: "info.circle")
                        Spacer()
                        Text(environment.getAppVisibleVersion())
                    }

                    HStack {
                        Label(L("Developer"), systemImage: "person")
                        Spacer()
                        Text(environment.getDeveloperName())
                    }

                    if (viewModel.isDevelopmentMode()) {
                        HStack {
                            Label(L("Build"), systemImage: "star.circle")
                            Spacer()
                            Text("Development")
                        }
                    }
                }

                if (viewModel.isDevelopmentMode()) {

                    Section(header: Text(L("Developer section"))) {

                        Button(action: {
                            NotificationManager.shared.requestPermission()
                        }) {
                            Text("Request Permission")
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            NotificationManager.shared.sendNotification(
                                title: "Hello!",
                                body: "This is a test notification"
                            )
                        }) {
                            Text("Send Notification Now")
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            NotificationManager.shared.scheduleNotification(
                                title: "Reminder",
                                body: "5 seconds have passed!",
                                afterSeconds: 5
                            )
                        }) {
                            Text("Schedule for 5 seconds")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(L("User settings"))
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showEditCurrencyModal) {
                EditDefaultCurrencyView(
                    selectedCurrency: viewModel.getDefaultCurrency(),
                    onSave: { newCurrency in
                        viewModel.saveDefaultCurrency(newCurrency)
                    })
            }
            .sheet(item: $editingCar) { car in
                EditCarView(
                    car: car,
                    onSave: { updated in
                        
                        if updated.name.trimmingCharacters(in: .whitespaces).isEmpty {
                            // TODO mgorbatyuk: show alert
                            return
                        }

                        if let batteryCapacity = updated.batteryCapacity, batteryCapacity < 0 {
                            // TODO mgorbatyuk: show alert
                            return
                        }

                        guard let carToUpdate = viewModel.getCarById(car.id) else {
                            // TODO mgorbatyuk: alert that car was not found
                            return
                        }

                        carToUpdate.updateValues(
                            name: updated.name,
                            batteryCapacity: updated.batteryCapacity,
                            currentMileage: updated.currentMileage)

                        _ = viewModel.updateCar(car: carToUpdate)

                        editingCar = nil
                        viewModel.refetchCars()
                    },
                    onCancel: {
                        editingCar = nil
                    }
                )
            }
            .onAppear {
                refreshData()
            }
            .refreshable {
                refreshData()
            }
            .sheet(isPresented: $showingAppAboutModal) {
                AboutAppSubView()
            }
        }
    }

    private func refreshData() -> Void {
        viewModel.refetchCars()

        notificationsManager.getAuthorizationStatus() { status in
           DispatchQueue.main.async {
               self.isNotificationsEnabled = status == .authorized
           }
       }
    }

    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    UserSettingsView()
}
