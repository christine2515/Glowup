import SwiftUI

/// App settings: backend connection, units, and the water goal.
struct SettingsView: View {
    @State private var config = AppConfig.shared

    var body: some View {
        Form {
            Section {
                ForEach(AppTheme.all) { theme in
                    Button {
                        config.themeID = theme.id
                    } label: {
                        HStack(spacing: 12) {
                            ThemeSwatch(theme: theme)
                            Text("\(theme.emoji)  \(theme.name)")
                                .font(.sans(15, .semibold))
                                .foregroundStyle(config.theme.ink)
                            Spacer()
                            if config.themeID == theme.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.accent)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            } header: {
                Text("Theme").sectionLabel().foregroundStyle(config.theme.ink2)
            }

            Section {
                TextField("http://192.168.x.x:8000", text: $config.backendURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField("API token (optional)", text: $config.apiToken)
            } header: {
                Text("Backend")
            } footer: {
                Text("The Glowup backend that extracts workouts from reels. Run it on your Mac and enter its address (e.g. your Mac's local IP).")
            }

            Section("Units") {
                Picker("Body weight", selection: $config.useMetric) {
                    Text("kg").tag(true)
                    Text("lb").tag(false)
                }
                .pickerStyle(.segmented)
            }

            Section("Water goal") {
                Stepper("\(Int(config.waterGoalML)) ml/day",
                        value: $config.waterGoalML, in: 500...6000, step: 250)
            }

            Section {
                Toggle("iCloud sync", isOn: $config.useICloudSync)
            } header: {
                Text("Sync")
            } footer: {
                Text("Syncs your data across devices via your iCloud account. Requires the CloudKit capability and a paid Apple Developer account. Restart the app after changing this.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .tint(config.theme.accent)
        .airyBackground(config.theme)
    }
}

/// A rounded gradient chip previewing a theme's accent → secondary.
struct ThemeSwatch: View {
    let theme: AppTheme

    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(theme.swatch)
            .frame(width: 32, height: 32)
    }
}
