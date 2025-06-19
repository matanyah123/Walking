import SwiftUI

struct PaymentWall: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack (alignment: .topTrailing) {
      VStack(spacing: 24) {
        VStack(spacing: 8) {
          Text("Unlock Walking Plus")
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.white)

          Text("Upgrade once. Enjoy forever.")
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.white)
        }

        .padding(.horizontal)
        .padding(.top, 30)

		  /* MARK: if #available(iOS 26.0, *) {
          VStack(alignment: .leading, spacing: 12) {
            Label("Widgets", systemImage: "widget.extralarge")
            //Label("Live Activity", systemImage: "dot.radiowaves.left.and.right")
            Label("Activity View", systemImage: "calendar")
            Label("Sharing Walks", systemImage: "square.and.arrow.up")
            Label("Custom App Icons", systemImage: "app.badge")
            Label("System Color Customization", systemImage: "paintpalette")
            Label("Remove Ads", systemImage: "nosign")
          }
          .font(.body)
          .padding()
		.glassEffect(in: .rect(cornerRadius: 16))
          .padding(.horizontal)
        } else { */
          VStack(alignment: .leading, spacing: 12) {
            Label("Widgets", systemImage: "widget.extralarge")
            //Label("Full Live Activity", systemImage: "dot.radiowaves.left.and.right")
            Label("Activity View", systemImage: "calendar")
            Label("Sharing Walks", systemImage: "square.and.arrow.up")
            Label("Custom App Icons", systemImage: "app.badge")
            Label("System Color Customization", systemImage: "paintpalette")
            Label("Remove Ads", systemImage: "nosign")
          }
          .font(.body)
          .padding()
          .background(.ultraThinMaterial)
          .cornerRadius(16)
          .padding(.horizontal)
        //}

        Image(systemName: "figure.run")
          .resizable()
          .scaledToFit()
          .foregroundStyle(.white)

        VStack() {
          Text("$7.99 – One-time purchase")
            .font(.headline)
            .foregroundStyle(Color.white)

          /*if #available(iOS 26, *) {
            GlassEffectContainer {
              Button("Unlock Walking Plus") {
                Task {
                  // await storeManager.purchase()
                }
              }
              .glassEffect(.regular.interactive())
              .buttonStyle(.borderedProminent)
              .controlSize(.large)
              .foregroundStyle(Color.white)
              .tint(Color.accentFromSettings)
              .padding(.bottom, 30)

              HStack{
                Button("Restore Purchase") {
                  Task {
                    // await storeManager.restore()
                  }
                }
                .font(.subheadline)
                .foregroundStyle(Color.black)
                .padding(10)
                .padding(.horizontal, 10)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                /*
                Button("☕ Buy Me a Coffee") {
                  if let url = URL(string: "https://buymeacoffee.com/yourlink") {
                    UIApplication.shared.open(url)
                  }
                }
                .font(.subheadline)
                .foregroundStyle(Color.black)
                .padding(10)
                .padding(.horizontal, 10)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                 */
              }
            }
          } else { */
            Button("Unlock Walking Plus") {
              Task {
                // await storeManager.purchase()
              }
            }
            .backgroundStyle(Color.accentFromSettings)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .foregroundStyle(Color.white)

            Button("Restore Purchase") {
              Task {
                // await storeManager.restore()
              }
            }
            .font(.footnote)
            .foregroundStyle(Color.white)
            .padding(5)
            /*
            Button("☕ Buy Me a Coffee") {
              if let url = URL(string: "https://buymeacoffee.com/yourlink") {
                UIApplication.shared.open(url)
              }
            }
            .font(.caption)
            .foregroundStyle(Color.white)
            .padding(.bottom)
             */
			//}
        }
        .padding(.bottom, 20)
      }
      .background(Image("PaywallBackground"))
      .safeAreaInset(edge: .bottom) {
        Color.clear.frame(height: 40)
      }
      .shadow(radius: 10)
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle")
          .font(.largeTitle)
          .foregroundStyle(Color.white)
      }
      .padding(5)
    }
  }
}

struct SmallPaymentWall: View {
  @Binding var selectedDetent: PresentationDetent
  @Environment(\.dismiss) var dismiss
  var body: some View {
    NavigationStack{
      ZStack (alignment: .topTrailing) {
        VStack {
          Text("If you're already stopping for a rest, why not consider buying Plus?")
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.black)
          HStack{
            Text("It's cheap, a one-time purchase, and helps me a lot.")
              .font(.title)
              .multilineTextAlignment(.center)
              .foregroundStyle(Color.black)
          }
          NavigationLink {
            PaymentWall()
              .onAppear{
                selectedDetent = .large
              }
              .onDisappear {
                selectedDetent = .medium
              }
          }label: {
            Text("You know what? Why not?\nwhat do i get?").bold().foregroundStyle(Color.black)
              .multilineTextAlignment(.center)
              .padding(10)
              .background(Color.blue.gradient)
              .cornerRadius(20)
          }
        }
        .padding(30)
        .background(Image("PaywallBackground"))
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark.circle")
            .font(.largeTitle)
            .foregroundStyle(Color.black)
        }
        .padding(0)
      }
    }
  }
}

#Preview {
  SmallPaymentWall(selectedDetent: .constant(.medium))
}
