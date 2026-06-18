import SwiftUI

/// "Me" tab. Phase 0: app/backend settings + Apple Health steps.
/// Phases 4–5 add water, supplements, and body-weight tracking here.
struct HealthView: View {
    @State private var config = AppConfig.shared
    @State private var health = HealthKitManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Apple Health") {
                    HStack {
                        Label("Steps today", systemImage: "shoeprints.fill")
                        Spacer()
                        Text("\(health.todaySteps)").bold()
                    }
                    Button("Connect Apple Health") {
                        Task { await health.requestAuthorization() }
                    }
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
                    Text("The ReelFit backend that extracts workouts and suggests meals. Run it on your Mac and enter its address (e.g. your Mac's local IP).")
                }

                Section("Units") {
                    Picker("Body weight", selection: $config.useMetric) {
                        Text("kg").tag(true)
                        Text("lb").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Me")
            .task {
                if health.authorized { await health.refreshTodaySteps() }
            }
        }
    }
}
