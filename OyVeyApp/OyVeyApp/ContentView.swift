//
//  ContentView.swift
//  OyVey
//
//  Created by Luke Edgar on 12/11/2025.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var rtvtManager = RTVTManager()
    @State private var showTranscriptionPanel = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Twitch WebView (main content)
            TwitchWebView()
                .frame(minWidth: 800, minHeight: 600)
                .background(Color.black)
            
            // Transcription overlay panel
            if showTranscriptionPanel {
                VStack(spacing: 0) {
                    // Transcription display area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if !rtvtManager.latestTranscription.isEmpty {
                                Text("Transcription:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(rtvtManager.latestTranscription)
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                            
                            if !rtvtManager.latestTranslation.isEmpty {
                                Text("Translation:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                Text(rtvtManager.latestTranslation)
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                            
                            if let error = rtvtManager.errorMessage {
                                Text("Error:")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 8)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                    }
                    .frame(height: 150)
                    .background(Color.black.opacity(0.85))
                    
                    // Control buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            if rtvtManager.isTranscribing {
                                rtvtManager.stopTranscription()
                            } else {
                                Task {
                                    await rtvtManager.startTranscription()
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: rtvtManager.isTranscribing ? "stop.circle.fill" : "mic.circle.fill")
                                Text(rtvtManager.isTranscribing ? "Stop" : "Start")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(rtvtManager.isTranscribing ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            showTranscriptionPanel = false
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Hide")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.9))
                }
                .transition(.move(edge: .bottom))
            }
            
            // Show transcription button (when panel is hidden)
            if !showTranscriptionPanel {
                Button(action: {
                    withAnimation {
                        showTranscriptionPanel = true
                    }
                }) {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                        Text("Transcription")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    ContentView()
}
