import Foundation
import Combine
import NaturalLanguage

class ChatTranslationManager: ObservableObject {
    @Published var translatedMessages: [String: String] = [:] // messageID: translation
    var targetLanguage: TranscriptionLanguage = .english

    func translateMessage(_ id: String, text: String, completion: @escaping (String) -> Void) {
        let sourceLang = detectLanguage(text: text)
        guard sourceLang != targetLanguage.rawValue else { completion(text); return }

        // Call translation API (local or remote)
        translateAPI(text: text, from: sourceLang, to: targetLanguage.rawValue) { translated in
            DispatchQueue.main.async {
                self.translatedMessages[id] = translated
                completion(translated)
            }
        }
    }

    func detectLanguage(text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue ?? "en"
    }

    func translateAPI(text: String, from: String, to: String, completion: @escaping (String) -> Void) {
        // TODO: DeepL/Google/OpenAI translation API integration
        completion("Translated message here...")
    }
}