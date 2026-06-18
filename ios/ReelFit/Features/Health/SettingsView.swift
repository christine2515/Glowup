import SwiftUI

/// App settings: backend connection, units, and the water goal.
struct SettingsView: View {
    @State private var config = AppConfig.shared

    var body: some View {
        Form {
            Section {
                TextField("http://192.168.x.x:8000", text: $config.backendURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField("API token (optional)", text: $config.apiToken)
            } header: {
                Text("Backend")
            } footer: {
                Text("The ReelFit backend that extracts workouts and suggests meals. Run it on your Mac and enter its address (e.g. your Mac's local IP).")
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
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
