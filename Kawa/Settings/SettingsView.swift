import SwiftUI

struct SettingsView: View {

    @ObservedObject var settingsState: SettingsState

    var body: some View {

        TabView(selection: $settingsState.selectedTab) {

            GeneralSettingsView()
                .tag(SettingsTab.general)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AboutView()
                .tag(SettingsTab.about)
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }

        }
        .padding(20)
        .frame(width: 500, height: 300)
    }
}
