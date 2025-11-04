//
//  AboutView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import SwiftUI

struct AboutView: SwiftUICore.View {
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var envorinment = EnvironmentService.shared

    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {
                
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0) // 👈 This will keep other views (like a large text) in the frame
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.2)

                ScrollView {
                    VStack(alignment: .leading) {
                        Text(L("Track your electric vehicle charging costs and discover your true cost per kilometer."))
                            .padding(.bottom)

                        Text(L("Log charging sessions, analyze expenses, and optimize your EV charging strategy with detailed insights and automatic calculations."))
                            .padding(.bottom)

                        Text(L("If you have any questions or suggestions, feel free to create an issue on Github:"))

                        if let url = URL(string: getGithubLink()) {
                            Link(L("ev-charging-tracker"), destination: url)
                        } else {
                            Text(getGithubLink())
                                .foregroundColor(.blue)
                        }
                            
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading) {

                        Divider()
                        Text(String(format: L("Version: %@"), envorinment.getAppVisibleVersion()))
                            .fontWeight(.semibold)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)

                        Text(String(format: L("Developer: © %@"), envorinment.getDeveloperName()))
                            .fontWeight(.semibold)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)

                        if (envorinment.getBuildEnvironment() == "dev") {
                            Text(L("Build: development"))
                                .fontWeight(.semibold)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle(L("EV Charge Tracker"))
            .navigationBarTitleDisplayMode(.automatic)
        }
    }

    private func getGithubLink() -> String {
        return "https://\(envorinment.getGitHubRepositoryUrl())"
    }
}

#Preview {
    AboutView()
}
