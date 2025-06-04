import SwiftUI

struct PaymentWall: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      Image("PaywallBackground")
        .resizable()
        .padding(.vertical, -40.0)
        .scaledToFill()
        .ignoresSafeArea()

      VStack(spacing: 24) {
        HStack {
          Spacer().frame(width: 350)
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle")
              .font(.title)
              .fontWeight(.thin)
              .foregroundStyle(Color.white)
          }
          .padding([.top, .trailing])
        }

        VStack(spacing: 8) {
          Text("Unlock Walking Plus")
            .font(.largeTitle.bold())
            .foregroundStyle(Color.white)
          Text("Upgrade once. Enjoy forever.")
            .font(.subheadline)
            .foregroundStyle(Color.white)
        }

        VStack(alignment: .leading, spacing: 12) {
          Label("Unlimited saved walks", systemImage: "infinity")
          Label("Ad-free experience", systemImage: "nosign")
          Label("Custom themes & colors", systemImage: "paintpalette")
          Label("Advanced analytics & stats", systemImage: "chart.bar.xaxis")
        }
        .font(.body)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
        Spacer()

        //Here you see the center of the background image, a cat on a skateboard.

        VStack(spacing: 12) {
          Text("$7.99 – One-time purchase")
            .font(.headline)
            .foregroundStyle(Color.white)

          Button("Unlock Walking Plus") {
            Task {
              // await storeManager.purchase()
            }
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .backgroundStyle(Color.accentFromSettings)
          .foregroundStyle(Color.white)

          Button("Restore Purchase") {
            Task {
              // await storeManager.restore()
            }
          }
          .font(.footnote)
          .foregroundStyle(Color.white)
        }
        .padding()

        Button("☕ Buy Me a Coffee") {
          if let url = URL(string: "https://buymeacoffee.com/yourlink") {
            UIApplication.shared.open(url)
          }
        }
        .font(.caption)
        .foregroundStyle(Color.white)
        .padding(.bottom)
      }
    }
  }
}

#Preview {
  PaymentWall()
}
