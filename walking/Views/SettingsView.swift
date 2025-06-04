//  SettingsView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 14/05/2025.
//

import SwiftUI
import UIKit


// MARK: - AppIcon Definition
struct AppIcon: Identifiable {
  let id = UUID()
  let name: String
  let displayName: String
}


// MARK: - Settings View
struct SettingsView: View {
  @Binding var doYouNeedAGoal: Bool
  @State private var showingColorPresets = false
  @State private var showingIconPresets = false
  @AppStorage(SharedKeys.goalTarget, store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var goalTarget = 5000
  @AppStorage("notificationsEnabled", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) private var notificationsEnabled: Bool = true
  @AppStorage("active_icon", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) private var activeAppIcon: String = "AppIcon"
  @AppStorage("darkMode", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) private var darkMode: Bool = true
  @AppStorage("unit", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) private var unit: Bool = true
  @AppStorage("accentColor", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) private var storedColorData: Data = {
    try! JSONEncoder().encode(CodableColor.lavenderBlue) // Default to Lavender Blue 💜
  }()

  private var accentColor: Color {
    (try? JSONDecoder().decode(CodableColor.self, from: storedColorData))?.color ?? Color.blue
  }

  private func saveAccentColor(_ newColor: Color) {
    if let encoded = try? JSONEncoder().encode(CodableColor(newColor)) {
      storedColorData = encoded
      // redundant but safe
      UserDefaults(suiteName: "group.com.matanyah.WalkTracker")?.set(encoded, forKey: "accentColor")
    }
  }

  private func savePresetColor(_ preset: CodableColor) {
    if let encoded = try? JSONEncoder().encode(preset) {
      storedColorData = encoded
      UserDefaults(suiteName: "group.com.matanyah.WalkTracker")?.set(encoded, forKey: "accentColor")
    }
  }

  private var currentCodableColor: CodableColor? {
    try? JSONDecoder().decode(CodableColor.self, from: storedColorData)
  }
  private var accentColorName: String {
    switch currentCodableColor {
    case CodableColor.lavenderBlue:
      return "Lavender Blue"
    case CodableColor.turquoiseMint:
      return "Turquoise Mint"
    case CodableColor.vibrantOrange:
      return "Vibrant Orange"
    case CodableColor.limeGreen:
      return "Lime Green"
    case .none:
      return "Unknown"
    default:
      return "Custom Color"
    }
  }

  private var currentIconDisplayName: String {
      switch activeAppIcon {
      case "AppIcon":
        return darkMode ? "Default (white)" : "Default (white)-L"
      case "AppIcon-Blue":
        return darkMode ? "Lavender Blue" : "Lavender Blue-L"
      case "AppIcon-Mint":
        return darkMode ? "Turquoise Mint" : "Turquoise Mint-L"
      case "AppIcon-Orange":
        return darkMode ? "Vibrant Orange" : "Vibrant Orange-L"
      case "AppIcon-Green":
        return darkMode ? "Lime Green" : "Lime Green-L"
      default:
        return darkMode ?  "Default (white)" :"Default (white)-L"
      }
    }

  var body: some View {
    NavigationStack {
      List {

        Section(header: Text("Payment Wall")) {
            NavigationLink("View Paywall") {
                PaymentWall()
            }
        }

        // Goals & Targets Section
        Section(header: Text("Goals & Targets")) {
          Toggle(isOn: $doYouNeedAGoal) {
            VStack(alignment: .leading) {
              Text("Require Setting a Goal")
              Text("If enabled, you'll need to set a meter goal before tracking")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          if doYouNeedAGoal {
            Stepper(value: $goalTarget, in: 1000...20000, step: 500) {
              VStack(alignment: .leading) {
                Text("Default Goal: \(goalTarget.formatted(.number)) meter")
                Text("Starting target for your daily walks")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
        }

        // Appearance Section
        Section(header: Text("Appearance"), footer: Text("The accent color will be used throughout the app")) {
              Button{
                  showingColorPresets.toggle()
              }label: {
                ColorPicker("Choose Preset Colors", selection: Binding(
                    get: { accentColor },
                    set: { saveAccentColor($0) }
                ), supportsOpacity: false)
                .colorScheme(darkMode ? .dark : .light)
              }
          .sheet(isPresented: $showingColorPresets) {
            PresetColorsView(selectColor: savePresetColor)
              .presentationDetents([.medium ,.large])
              .presentationDragIndicator(.visible)
              .colorScheme(darkMode ? .dark : .light)
          }

          Button{
              showingIconPresets.toggle()
          }label: {
            HStack{
              Text("Choose App Icon")
              Spacer()
              Image(currentIconDisplayName)
                  .resizable()
                  .aspectRatio(1, contentMode: .fit)
                  .frame(width: 29, height: 29)
                  .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                  .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                  .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                      .stroke(
                            Color.accentFromSettings,
                            lineWidth: 1
                          )
                  )
            }
          }
          .sheet(isPresented: $showingIconPresets) {
            AppIconPickerView(activeAppIcon: $activeAppIcon)
              .presentationDetents([.medium ,.large])
              .presentationDragIndicator(.visible)
              .colorScheme(darkMode ? .dark : .light)
          }
          Toggle(isOn: $darkMode) {
            Text("Dark Mode")
          }
        }

        Section(
            header: Text("Units"),
            footer: Text("Metrics or Imperial")
        ) {
            Toggle(isOn: $unit) {
                Text("Current unit: \(unit ? "KM" : "MI")")
            }
        }

        // Additional Settings Section
        Section(
            header: Text("Additional Settings"),
            footer: Text(" ").frame(height: 75)
        ) {
          //Toggle("Enable Notifications", isOn: $notificationsEnabled)

          NavigationLink(destination: AboutView()) {
            Label("About This App", systemImage: "info.circle")
              .foregroundStyle(Color.accentFromSettings)
          }

          NavigationLink(destination: HelpView()) {
            Label("Help & Support", systemImage: "questionmark.circle")
              .foregroundStyle(Color.accentFromSettings)
          }

          /*
          NavigationLink(destination: ThanksView()) {
            Label("Thank You", systemImage: "heart.circle")
              .foregroundStyle(Color.accentFromSettings)
          }
           */
        }
      }
      .navigationTitle("Settings")
      .tint(Color.accentFromSettings)
    }
  }
}



// MARK: - Preset Colors View
struct PresetColorsView: View {
  @Environment(\.dismiss) var dismiss
  var selectColor: (CodableColor) -> Void

  // Use same suite for custom colors storage
  @AppStorage("customColors", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker"))
  private var savedColorsData: Data = Data()

  @State private var customColors: [CodableColor] = []
  @State private var newColor: Color = .teal
  @State private var showDeleteAlert = false

  @State private var editingColor: CodableColor?
  @State private var editingName: String = ""
  @State private var showEditNameSheet = false

  private let presets: [(name: String, color: CodableColor)] = [
    ("Lavender Blue", CodableColor.lavenderBlue),
    ("Turquoise Mint", CodableColor.turquoiseMint),
    ("Vibrant Orange", CodableColor.vibrantOrange),
    ("Lime Green", CodableColor.limeGreen)
  ]

  private func loadSavedColors() {
    if let decoded = try? JSONDecoder().decode([CodableColor].self, from: savedColorsData) {
      customColors = decoded
    }
  }

  private func saveColors() {
    if let encoded = try? JSONEncoder().encode(customColors) {
      savedColorsData = encoded
    }
  }

  private func addCustomColor() {
    let codable = CodableColor(newColor)
    if !customColors.contains(codable) {
      customColors.append(codable)
      saveColors()
    }
  }

  private func deleteColor(at offsets: IndexSet) {
    customColors.remove(atOffsets: offsets)
    saveColors()
  }

  var body: some View {
    NavigationStack {
      List {
        Section(header: Text("Presets")) {
          ForEach(presets, id: \.name) { preset in
            Button {
              selectColor(preset.color)
              dismiss()
            } label: {
              HStack {
                Text(preset.name)
                Spacer()
                Circle()
                  .fill(preset.color.color)
                  .frame(width: 24, height: 24)
              }
            }
            .buttonStyle(BorderlessButtonStyle())
          }
        }

        if !customColors.isEmpty {
          Section(header: Text("Custom Colors")) {
            ForEach(customColors, id: \.self) { color in
              Button {
                selectColor(color)
                dismiss()
              } label: {
                HStack {
                  Text(color.name ?? "Custom")
                  Spacer()
                  Circle()
                    .fill(color.color)
                    .frame(width: 24, height: 24)
                }
              }
              .buttonStyle(BorderlessButtonStyle())
              .swipeActions(edge: .leading, allowsFullSwipe: true) {
                  Button("Edit") {
                      editingColor = color
                      editingName = color.name ?? ""
                      showEditNameSheet = true
                  }
                  .tint(.blue)
              }
            }
            .onDelete(perform: deleteColor)
          }
        }
      }
      .navigationTitle("Choose Preset")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          HStack {
            ColorPicker("Create New Color", selection: $newColor, supportsOpacity: false)
              .labelsHidden()
              .onChange(of: newColor) {
                addCustomColor()
              }

            if !customColors.isEmpty {
              Button {
                showDeleteAlert = true
              } label: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
              }
              .accessibilityLabel("Delete All Custom Colors")
              .confirmationDialog("Are you sure you want to delete all custom colors?",
                                  isPresented: $showDeleteAlert,
                                  titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                  customColors.removeAll()
                  saveColors()
                }
                Button("Cancel", role: .cancel) { }
              }
            }
          }
        }
      }
      .onAppear(perform: loadSavedColors)
      .sheet(isPresented: $showEditNameSheet) {
        NavigationStack {
          Form {
            TextField("New name", text: $editingName)
          }
          .navigationTitle("Edit Name")
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Save") {
                  if let index = customColors.firstIndex(of: editingColor ?? CodableColor(.clear)) {
                      customColors[index].name = editingName
                      saveColors()
                  }
                  showEditNameSheet = false
              }
            }
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                showEditNameSheet = false
              }
            }
          }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
      }
    }
  }
}


// MARK: - App Icon Picker View
struct AppIconPickerView: View {
    @Binding var activeAppIcon: String
    @Environment(\.dismiss) var dismiss
  @AppStorage("darkMode", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var darkMode: Bool = true

  private var icons: [AppIcon] {
      [
          AppIcon(name: "AppIcon", displayName: "Default (white)"),
          AppIcon(name: "AppIcon-Blue", displayName: "Lavender Blue"),
          AppIcon(name: "AppIcon-Mint", displayName: "Turquoise Mint"),
          AppIcon(name: "AppIcon-Orange", displayName: "Vibrant Orange"),
          AppIcon(name: "AppIcon-Green", displayName: "Lime Green")
      ]
  }

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(icons) { icon in
                        VStack(spacing: 12) {
                            Button {
                                selectIcon(icon)
                            } label: {
                                Image(icon.displayName)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(
                                                activeAppIcon == icon.name ? Color.accentColor : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                    .scaleEffect(activeAppIcon == icon.name ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: activeAppIcon)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text(icon.displayName)
                                .font(.caption)
                                .fontWeight(activeAppIcon == icon.name ? .semibold : .regular)
                                .multilineTextAlignment(.center)
                                .foregroundColor(activeAppIcon == icon.name ? .accentColor : .primary)
                                .animation(.easeInOut(duration: 0.2), value: activeAppIcon)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Choose App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func selectIcon(_ icon: AppIcon) {
        // Haptic feedback for selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        withAnimation(.easeInOut(duration: 0.2)) {
            activeAppIcon = icon.name
        }

        // Change the app icon
        UIApplication.shared.setAlternateIconName(
            icon.name == "AppIcon" ? nil : icon.name
        ) { error in
            if let error = error {
                print("Failed to change app icon: \(error)")
            }
        }
    }
}




// MARK: - About View
struct AboutView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Walking App")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("Version 1.0")
          .font(.subheadline)

        Text("This app helps you track your daily walking goals and maintain a healthy lifestyle through regular physical activity.")
          .padding(.top)

        Text("© 2025 Matanyah Eliyahu\nAll rights reserved.")
          .font(.caption)
          .padding(.top, 40)
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .navigationTitle("About")
  }
}



// MARK: - Help View
struct HelpView: View {
  var body: some View {
    List {
      Section(header: Text("Frequently Asked Questions")) {
        DisclosureGroup("How do I set a daily goal?") {
          Text("Go to the Settings tab and enable 'Require Setting a Daily Goal'. Then use the stepper to set your target step count.")
            .padding(.vertical, 8)
        }

        DisclosureGroup("How does the app track my steps?") {
          Text("The app uses your device's built-in pedometer to track steps. Make sure to give the app permission to access motion & fitness data in your device settings.")
            .padding(.vertical, 8)
        }

        DisclosureGroup("Why should I customize the accent color?") {
          Text("The accent color is used throughout the app's interface. Choose a color that you find visually pleasing or that helps with visibility.")
            .padding(.vertical, 8)
        }
      }

      Section(header: Text("Contact Support")) {
        Button {
          if let emailURL = URL(string: "matanyah.k8@gmail.com") {
            UIApplication.shared.open(emailURL)
          }
        } label: {
          Label("Email Support", systemImage: "envelope")
        }

        Button {
          if let websiteURL = URL(string: "https://github.com/matanyah123") {
            UIApplication.shared.open(websiteURL)
          }
        } label: {
          Label("Me in Github", systemImage: "globe")
        }
      }
    }
    .navigationTitle("Help & Support")
  }
}


struct Supporter: Identifiable {
    var id: String { name }
    var name: String
    var link: URL
}

// MARK: - Help View
struct ThanksView: View {
  @State var supporters: [Supporter] = [
    Supporter(name: "Alice", link: URL(string: "https://github.com/alice")!),
    Supporter(name: "Bob", link: URL(string: "https://github.com/bob")!)
  ]

  var body: some View {
    List {
      Text("Thanks to everyone who supported me since day one.")
        .font(.headline)
        .multilineTextAlignment(.center)
        .padding(.vertical)
      Section(header: Text("Supporters")) {
        ForEach(supporters) { supporter in
          Button {
            UIApplication.shared.open(supporter.link)
          } label: {
            Label(supporter.name, systemImage: "person.crop.circle")
          }
        }
      }

      Section(header: Text("Want to support?")) {
        Button {
          if let websiteURL = URL(string: "https://linktr.ee/Matanyah") {
            UIApplication.shared.open(websiteURL)
          }
        } label: {
          Label("Buy me a coffee", systemImage: "cup.and.saucer.fill")
        }
      }
    }
    .navigationTitle("Thank You!")
  }
}

/*
#Preview {
  @State var deepLink: String?
  ContentView(deepLink: $deepLink)
    .preferredColorScheme(.dark)
}
*/
// MARK: - Preview
#Preview("Settings View") {
  @Previewable @State var doYouNeedAGoal: Bool = false
  SettingsView(doYouNeedAGoal: $doYouNeedAGoal)
    .preferredColorScheme(.light)
}
 /*
#Preview("Preset Colors") {
  PresetColorsView(selectColor: { _ in })
}

#Preview{
  ThanksView()
}
*/
