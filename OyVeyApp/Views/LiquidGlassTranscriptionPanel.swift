import SwiftUI

struct LiquidGlassTranscriptionPanel: View {
    @ObservedObject var manager: WhisperTranscriptionManager

    var body: some View {
        VStack(spacing: 12) {
            if manager.isTranscribing {
                Text(manager.latestTranscription)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .transition(.opacity.combined(with: .slide))
                    .animation(.easeOut(duration: 0.35), value: manager.latestTranscription)
            } else {
                Text("Transcription is off")
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .frame(maxWidth: 600)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .blur(radius: CGFloat(AppSettings.shared.blurIntensity))
        .opacity(Double(AppSettings.shared.transparency) / 100.0)
        .shadow(radius: 24)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 2)
        )
        .animation(.spring(), value: manager.isTranscribing)
    }
}