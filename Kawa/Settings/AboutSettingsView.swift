import SwiftUI

// MARK: - Content View
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
                .cornerRadius(8)

            Text("Kawa")
                .font(.largeTitle)
                .bold()

            VStack {
                Text("Version 1.0.0")
                Text("© Christian Frey")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text("Keep your Mac awake with style.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            if let url = URL(string: "https://github.com/christianfrey/kawa") {
                Button(action: {
                    NSWorkspace.shared.open(url)
                }, label: {
                    Text("GitHub Repository")
                })
                .padding(.top, 8)
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
        .frame(width: 600)
}
