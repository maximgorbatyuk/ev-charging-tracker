//
//  AboutView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 16.10.2025.
//

import SwiftUI

struct AboutView: SwiftUICore.View {

    let appVersion = Bundle.main.object(forInfoDictionaryKey: "AppVisibleVersion") as? String ?? "0.0.0"

    let developerName = Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String ?? "-"
    
    let githubRepoUrl = Bundle.main.object(forInfoDictionaryKey: "GithubRepoUrl") as? String ?? "-"
    
    let buildEnvironment = Bundle.main.object(forInfoDictionaryKey: "BuildEnvironment") as? String ?? "-"

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
                        Text(NSLocalizedString("Track your electric vehicle charging costs and discover your true cost per kilometer.", comment: "About description line 1"))
                            .padding(.bottom)

                        Text(NSLocalizedString("Log charging sessions, analyze expenses, and optimize your EV charging strategy with detailed insights and automatic calculations.", comment: "About description line 2"))
                            .padding(.bottom)

                        Text(NSLocalizedString("If you have any questions or suggestions, feel free to create an issue on Github:", comment: "About contact prompt"))

                        if let url = URL(string: getGithubLink()) {
                            Link(NSLocalizedString("ev-charging-tracker", comment: "GitHub repo link label"), destination: url)
                        } else {
                            Text(getGithubLink())
                                .foregroundColor(.blue)
                        }
                            
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading) {

                        Divider()
                        Text(String(format: NSLocalizedString("Version: %@", comment: "Version label with version"), appVersion))
                            .fontWeight(.semibold)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)

                        Text(String(format: NSLocalizedString("Developer: © %@", comment: "Developer label with name"), developerName))
                            .fontWeight(.semibold)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)

                        if (buildEnvironment == "dev") {
                            Text(NSLocalizedString("Build: development", comment: "Build environment label"))
                                .fontWeight(.semibold)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle(NSLocalizedString("EV Charge Tracker", comment: "Navigation title for About view"))
            .navigationBarTitleDisplayMode(.automatic)
        }
    }

    private func getGithubLink() -> String {
        return "https://\(githubRepoUrl)"
    }
}

#Preview {
    AboutView()
}
