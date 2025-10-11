import SwiftUI

// MARK: - Content View
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
                .cornerRadius(8)

            Text("Kawa")
                .font(.title2)
                .bold()

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .foregroundColor(.secondary)

            Text("Keep your Mac awake with style.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            if let url = URL(string: "https://github.com/christianfrey/kawa") {
                Link("GitHub Repository", destination: url)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
    }
}

// MARK: - Preview
#Preview {
    AboutSettingsView()
        .frame(width: 500)
}
