RTVTManager.swift//
//  RTVTManager.swift
//  OyVey
//
//  Real-Time Voice Transcription Manager
//  Integrates with iLiveData RTVT API
//

import Foundation
import AVFoundation
import Combine

// MARK: - RTVT Models
struct RTVTConfig {
    let apiHost = "https://account-api.ilivedata.com/rtvtchrome/gettoken"
    var asrLang: String = "auto"  // Source language
    var altLang: String = "en"    // Target language
    var uid: String
    var endpoint: String = ""
    var pid: Int = 0
    var token: String = ""
    var timestamp: Int = 0
}

struct TranscriptionResult {
    let streamId: String
    let taskId: String
    let text: String
    let isTemp: Bool
    let isFinal: Bool
}

struct TranslationResult {
    let streamId: String
    let taskId: String
    let translatedText: String
    let isTemp: Bool
}

// MARK: - RTVT Manager
class RTVTManager: ObservableObject {
    @Published var latestTranscription: String = ""
    @Published var latestTranslation: String = ""
    @Published var isTranscribing: Bool = false
    @Published var errorMessage: String? = nil
    
    private var config: RTVTConfig
    private var audioEngine: AVAudioEngine?
    private var audioCaptureNode: AVAudioInputNode?
    private var currentSegment: Int = 0
    private var streamId: String?
    private var urlSession: URLSession
    private var webSocketTask: URLSessionWebSocketTask?
    
    init(uid: String) {
        self.config = RTVTConfig(uid: uid)
        self.urlSession = URLSession(configuration: .default)
    }
    
    // MARK: - Public Methods
    
    func startTranscription(sourceLanguage: String = "auto", targetLanguage: String = "en") {
        guard !isTranscribing else { return }
        
        config.asrLang = sourceLanguage
        config.altLang = targetLanguage
        
        Task {
            do {
                try await fetchToken()
                try await connectToRTVT()
                try await startAudioCapture()
                
                await MainActor.run {
                    self.isTranscribing = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isTranscribing = false
                }
            }
        }
    }
    
    func stopTranscription() {
        stopAudioCapture()
        disconnectWebSocket()
        
        isTranscribing = false
        currentSegment = 0
        streamId = nil
    }
    
    func updateLanguages(source: String, target: String) {
        config.asrLang = source
        config.altLang = target
        
        // Restart if currently transcribing
        if isTranscribing {
            stopTranscription()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startTranscription(sourceLanguage: source, targetLanguage: target)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchToken() async throws {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let urlString = "\(config.apiHost)?lang=\(lang)&ver=new"
        
        guard let url = URL(string: urlString) else {
            throw RTVTError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RTVTError.networkError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let status = json?["status"] as? Int, status == 0,
              let pid = json?["pid"] as? Int,
              let token = json?["token"] as? String,
              let ts = json?["ts"] as? Int,
              let endpoint = json?["endpoint"] as? String else {
            throw RTVTError.invalidResponse
        }
        
        config.pid = pid
        config.token = token
        config.timestamp = ts
        config.endpoint = endpoint
        
        print("[RTVT] Token fetched successfully. Endpoint: \(endpoint)")
    }
    
    private func connectToRTVT() async throws {
        // For FPNN protocol, we would need a proper WebSocket implementation
        // For now, this is a placeholder for the connection logic
        // The actual RTVT uses FPNN (Fast Portable Network Protocol)
        
        guard let url = URL(string: "wss://\(config.endpoint)") else {
            throw RTVTError.invalidURL
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Send login message
        try await sendLoginMessage()
        
        // Create stream
        try await createStream()
        
        // Start receiving messages
        receiveMessages()
    }
    
    private func sendLoginMessage() async throws {
        let loginData: [String: Any] = [
            "cmd": "login",
            "pid": config.pid,
            "uid": config.uid,
            "token": config.token,
            "ts": config.timestamp
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: loginData)
        let message = URLSessionWebSocketTask.Message.data(jsonData)
        
        try await webSocketTask?.send(message)
        print("[RTVT] Login message sent")
    }
    
    private func createStream() async throws {
        streamId = UUID().uuidString
        
        let streamData: [String: Any] = [
            "cmd": "createStream",
            "streamId": streamId!,
            "asrLang": config.asrLang,
            "altLang": config.altLang,
            "needASR": true,
            "needTranslation": true
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: streamData)
        let message = URLSessionWebSocketTask.Message.data(jsonData)
        
        try await webSocketTask?.send(message)
        print("[RTVT] Stream created: \(streamId!)")
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessages() // Continue receiving
                
            case .failure(let error):
                print("[RTVT] WebSocket error: \(error)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Connection error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        guard case .data(let data) = message else { return }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cmd = json["cmd"] as? String else {
                return
            }
            
            switch cmd {
            case "recognizedResult":
                handleTranscriptionResult(json, isTemp: false)
                
            case "recognizedTempResult":
                handleTranscriptionResult(json, isTemp: true)
                
            case "translatedResult":
                handleTranslationResult(json, isTemp: false)
                
            case "translatedTempResult":
                handleTranslationResult(json, isTemp: true)
                
            default:
                print("[RTVT] Unknown command: \(cmd)")
            }
            
        } catch {
            print("[RTVT] Failed to parse message: \(error)")
        }
    }
    
    private func handleTranscriptionResult(_ json: [String: Any], isTemp: Bool) {
        guard let data = json["data"] as? [String: Any],
              let text = data["asr"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            self.latestTranscription = text
        }
    }
    
    private func handleTranslationResult(_ json: [String: Any], isTemp: Bool) {
        guard let data = json["data"] as? [String: Any],
              let translatedText = data["trans"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            self.latestTranslation = translatedText
        }
    }
    
    // MARK: - Audio Capture
    
    private func startAudioCapture() async throws {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            throw RTVTError.audioEngineError
        }
        
        // Request microphone permission
        let permission = await AVCaptureDevice.requestAccess(for: .audio)
        guard permission else {
            throw RTVTError.permissionDenied
        }
        
        audioCaptureNode = audioEngine.inputNode
        
        // Configure audio format: 16kHz, 16-bit PCM (as required by RTVT)
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )
        
        guard let format = recordingFormat else {
            throw RTVTError.audioFormatError
        }
        
        audioCaptureNode?.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: format
        ) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        try audioEngine.start()
        print("[RTVT] Audio capture started")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.int16ChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let pcmData = Data(bytes: channelData[0], count: frameLength * MemoryLayout<Int16>.size)
        
        // Send audio segment to RTVT
        Task {
            await sendVoiceData(pcmData)
        }
    }
    
    private func sendVoiceData(_ data: Data) async {
        guard let streamId = streamId else { return }
        
        let voiceData: [String: Any] = [
            "cmd": "sendVoice",
            "streamId": streamId,
            "seg": currentSegment,
            "data": data.base64EncodedString()
        ]
        
        currentSegment += 1
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: voiceData)
            let message = URLSessionWebSocketTask.Message.data(jsonData)
            try await webSocketTask?.send(message)
        } catch {
            print("[RTVT] Failed to send voice data: \(error)")
        }
    }
    
    private func stopAudioCapture() {
        audioCaptureNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioCaptureNode = nil
        
        print("[RTVT] Audio capture stopped")
    }
    
    private func disconnectWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        print("[RTVT] WebSocket disconnected")
    }
}

// MARK: - Errors
enum RTVTError: LocalizedError {
    case invalidURL
    case networkError
    case invalidResponse
    case audioEngineError
    case audioFormatError
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network connection failed"
        case .invalidResponse:
            return "Invalid server response"
        case .audioEngineError:
            return "Failed to initialize audio engine"
        case .audioFormatError:
            return "Unsupported audio format"
        case .permissionDenied:
            return "Microphone permission denied"
        }
    }
}
