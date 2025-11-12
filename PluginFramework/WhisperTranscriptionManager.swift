import Foundation
import AVFoundation
import Combine

enum TranscriptionLanguage: String, CaseIterable {
    case english = "en"
    case russian = "ru"
    case german = "de"
    case japanese = "ja"
    case chinese = "zh"
    case french = "fr"

    var displayName: String {
        switch self {
        case .english: return "English (UK)"
        case .russian: return "Russian"
        case .german: return "German"
        case .japanese: return "Japanese"
        case .chinese: return "Chinese (Simplified)"
        case .french: return "French"
        }
    }
}

class WhisperTranscriptionManager: ObservableObject {
    @Published var latestTranscription: String = ""
    @Published var isTranscribing: Bool = false
    @Published var selectedLanguage: TranscriptionLanguage = .english

    private var audioEngine: AVAudioEngine?
    private var recognizer: WhisperRecognizer?
    private var cancellables = Set<AnyCancellable>()

    func toggleTranscription() {
        isTranscribing ? stopTranscription() : startTranscription()
    }

    func startTranscription() {
        guard !isTranscribing else { return }
        isTranscribing = true
        setupAudioSession()
        recognizer = WhisperRecognizer(language: selectedLanguage.rawValue)
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine!.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.recognizer?.transcribeAudioBuffer(buffer) { text in
                DispatchQueue.main.async {
                    self.latestTranscription = text
                }
            }
        }
        audioEngine?.prepare()
        try? audioEngine?.start()
    }

    func stopTranscription() {
        audioEngine?.stop()
        audioEngine = nil
        recognizer = nil
        isTranscribing = false
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)
    }
}

// WhisperRecognizer is a placeholder - your implementation wraps OpenAI Whisper or a local lib
class WhisperRecognizer {
    let language: String
    init(language: String) { self.language = language }
    func transcribeAudioBuffer(_ buffer: AVAudioPCMBuffer, completion: @escaping (String) -> Void) {
        // TODO: Integrate Whisper Core ML or running whisper.cpp
        completion("Transcribed text here...")
    }
}