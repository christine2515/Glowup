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
                            Text(theme.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if config.themeID == theme.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.accent)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } header: {
                Text("Theme")
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
    }
}

/// A small preview chip showing a theme's wash + macro colors.
struct ThemeSwatch: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.wash)
            HStack(spacing: 3) {
                Circle().fill(theme.calories)
                Circle().fill(theme.protein)
                Circle().fill(theme.carbs)
                Circle().fill(theme.fat)
            }
            .frame(height: 8)
            .padding(.horizontal, 6)
        }
        .frame(width: 56, height: 32)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(theme.accent.opacity(0.4), lineWidth: 1)
        )
    }
}
