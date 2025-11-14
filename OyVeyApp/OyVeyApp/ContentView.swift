//
//  ContentView.swift
//  OyVey
//
//  Created by Luke Edgar on 12/11/2025.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var pluginManager = PluginManager.shared
    @State private var showTranscriptionPanel = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Twitch WebView with plugins
            TwitchWebView()
                .frame(minWidth: 800, minHeight: 600)
                .background(Color.black)
            
            // Transcription overlay panel (Liquid Glass UI)
            if showTranscriptionPanel {
                LiquidGlassTranscriptionPanel(
                    isShowing: $showTranscriptionPanel,
                    transcriptionText: pluginManager.currentTranscription,
                    translationText: pluginManager.currentTranslation
                )
                .transition(.move(edge: .bottom))
            }
            
            // Settings panel
            if showSettings {
                SettingsPanel(isShowing: $showSettings)
                    .transition(.move(edge: .trailing))
            }
            
            // Control buttons overlay
            if !showTranscriptionPanel && !showSettings {
                HStack(spacing: 16) {
                    // Transcription button
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
                    
                    // Settings button
                    Button(action: {
                        withAnimation {
                            showSettings = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            // Load plugins on app launch
            pluginManager.loadPlugins()
        }
    }
}

#Preview {
    ContentView()
}
