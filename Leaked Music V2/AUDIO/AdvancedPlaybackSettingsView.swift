import SwiftUI

struct AdvancedPlaybackSettingsView: View {
    @State private var crossfadeDuration: Double = 5.0
    @State private var equalizerPreset: String = "Flat"
    
    var body: some View {
        Form {
            Section(header: Text("Crossfade Duration")) {
                Slider(value: $crossfadeDuration, in: 0...10, step: 0.5)
                Text("Duration: \(crossfadeDuration, specifier: "%.1f") seconds")
            }
            Section(header: Text("Equalizer Preset")) {
                Picker("Preset", selection: $equalizerPreset) {
                    Text("Flat").tag("Flat")
                    Text("Rock").tag("Rock")
                    Text("Pop").tag("Pop")
                    Text("Classical").tag("Classical")
                    Text("Jazz").tag("Jazz")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            Button("Apply Settings") {
                Logger.log("Applied playback settings: crossfade \(crossfadeDuration), equalizer: \(equalizerPreset)")
                // In a real implementation, these settings would be applied to your audio engine.
            }
        }
        .navigationTitle("Playback Settings")
        .appBackground()
    }
}
