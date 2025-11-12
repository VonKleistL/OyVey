import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    @AppStorage("transparency") var transparency: Int = 80
    @AppStorage("blurIntensity") var blurIntensity: Int = 30
    @Published var transcriptionLanguage: TranscriptionLanguage = .english
    @Published var translationLanguage: TranscriptionLanguage = .english
}

struct SettingsPanel: View {
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        Form {
            Section(header: Text("Liquid Glass Appearance")) {
                HStack {
                    Text("Transparency")
                    Slider(value: Binding(
                        get: { Double(settings.transparency) },
                        set: { settings.transparency = Int($0) }
                    ), in: 0...100)
                    Text("\(settings.transparency)%")
                }
                HStack {
                    Text("Blur Intensity")
                    Slider(value: Binding(
                        get: { Double(settings.blurIntensity) },
                        set: { settings.blurIntensity = Int($0) }
                    ), in: 0...80)
                    Text("\(settings.blurIntensity)")
                }
            }
            Section(header: Text("Languages")) {
                Picker("Transcription", selection: $settings.transcriptionLanguage) {
                    ForEach(TranscriptionLanguage.allCases, id: \.self) {
                        Text($0.displayName)
                    }
                }
                Picker("Translation", selection: $settings.translationLanguage) {
                    ForEach(TranscriptionLanguage.allCases, id: \.self) {
                        Text($0.displayName)
                    }
                }
            }
        }
        .padding()
    }
}