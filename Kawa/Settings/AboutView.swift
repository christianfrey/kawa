import SwiftUI

struct AboutView: View {
    
    var body: some View {
        // About content with app icon, name, version and a short description/link
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
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

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

    // var body: some View {

    //     VStack(alignment: .center) {

    //         // Spacer()

    //         VStack(spacing: 10) {
    //             Image(nsImage: NSApp.applicationIconImage)
    //             Text("Kawa")
    //                 .font(.title)
    //                 .bold()
    //             HStack {
    //                 Text("Version 1.0")
    //                 // Text("(Build xyz)").font(.footnote)
    //             }

    //             // Text("Made with ❤️ by Christian Frey").font(.caption)
    //         }
    //         .padding(.vertical)

            // HStack {
            //     Spacer()
            //     Button(action: {
            //         NSWorkspace.shared.open(URL(string: "https://github.com/sponsors/christianfrey")!)
            //     }, label: {
            //         HStack(alignment: .center, spacing: 8) {
            //             Image(systemName: "heart")
            //                 .resizable()
            //                 .scaledToFit()
            //                 .frame(width: 16, height: 16)
            //                 .foregroundStyle(.pink)

            //             Text("Sponsor")
            //                 .font(.body)
            //                 .bold()
            //         }
            //         .padding(5)
            //     })
            //     Spacer()
            // }

            // Spacer()

            // GroupBox {
            //     HStack{

            //         Text("Submit a bug or feature request")
            //             .font(.callout)
            //             .foregroundStyle(.primary)
            //             .padding(.leading, 5)
            //         Spacer()
            //         Button {
            //             NSWorkspace.shared.open(URL(string: "https://github.com/christianfrey/kawa/issues/new/choose")!)
            //         } label: {
            //             Text("Open")
            //         }
            //         .buttonStyle(.bordered)
            //     }
            //     .padding(5)
            // }

    //     }
    // }
// }
