```swift
//
//  SamplePlugin.swift
//  OyVey - Sample Plugin Implementation
//
//  This is an example plugin that demonstrates how to use the OyVey Plugin Framework
//  to extend Twitch client functionality
//

import Foundation

/// Sample plugin that adds custom emote support and chat commands
public class BetterEmotesPlugin: Plugin {
    
    // MARK: - Plugin Properties
    
    public var metadata: PluginMetadata = PluginMetadata(
        identifier: "com.oyvey.betteremotes",
        name: "Better Emotes",
        version: "1.0.0",
        author: "OyVey Team",
        description: "Adds support for BTTV and 7TV emotes to the Twitch client",
        homepage: "https://github.com/VonKleistL/OyVey",
        requiredPermissions: [.network, .uiModification, .chatAccess],
        dependencies: []
    )
    
    private var api: PluginAPI?
    private var emoteCache: [String: EmoteData] = [:]
    private var chatCommandId: String?
    private var messageSubscriptionId: String?
    
    // MARK: - Plugin Lifecycle
    
    public init() {}
    
    public func initialize(with api: PluginAPI) throws {
        self.api = api
        
        api.log(level: .info, message: "Better Emotes plugin initializing...", metadata: nil)
        
        // Subscribe to chat message events
        messageSubscriptionId = api.subscribeToEvent("chat.message.received") { [weak self] event in
            self?.handleChatMessage(event)
        }
        
        // Register chat command
        chatCommandId = api.registerChatCommand(command: "emotes") { [weak self] channel, args in
            self?.handleEmotesCommand(channel: channel, args: args)
        }
        
        api.log(level: .info, message: "Better Emotes plugin initialized successfully", metadata: nil)
    }
    
    public func activate() throws {
        guard let api = api else {
            throw PluginError.notInitialized
        }
        
        api.log(level: .info, message: "Better Emotes plugin activating...", metadata: nil)
        
        // Load emotes from BTTV
        Task {
            await loadBTTVEmotes()
        }
        
        // Load emotes from 7TV
        Task {
            await load7TVEmotes()
        }
        
        // Add menu item
        let menuId = api.registerMenuItem(title: "Better Emotes Settings") { [weak self] in
            self?.showSettings()
        }
        
        // Show activation notification
        api.showNotification(
            title: "Better Emotes",
            message: "Plugin activated! Now supporting BTTV and 7TV emotes.",
            type: .info
        )
        
        api.log(level: .info, message: "Better Emotes plugin activated", metadata: nil)
    }
    
    public func deactivate() throws {
        guard let api = api else {
            throw PluginError.notInitialized
        }
        
        api.log(level: .info, message: "Better Emotes plugin deactivating...", metadata: nil)
        
        // Unsubscribe from events
        if let subId = messageSubscriptionId {
            api.unsubscribeFromEvent(subId)
        }
        
        // Unregister chat command
        if let cmdId = chatCommandId {
            api.unregisterChatCommand(cmdId)
        }
        
        // Clear emote cache
        emoteCache.removeAll()
        
        api.log(level: .info, message: "Better Emotes plugin deactivated", metadata: nil)
    }
    
    public func onEvent(_ event: PluginEvent) {
        // Handle plugin-specific events
        switch event.name {
        case "settings.changed":
            handleSettingsChanged(event)
        default:
            break
        }
    }
    
    // MARK: - Emote Loading
    
    private func loadBTTVEmotes() async {
        guard let api = api else { return }
        
        do {
            api.log(level: .info, message: "Loading BTTV emotes...", metadata: nil)
            
            // Fetch global BTTV emotes
            let response = try await api.makeHTTPRequest(
                url: "https://api.betterttv.net/3/cached/emotes/global",
                method: .GET,
                headers: nil,
                body: nil
            )
            
            // Parse JSON response
            if let emotes = try? JSONDecoder().decode([BTTVEmote].self, from: response.body) {
                for emote in emotes {
                    let emoteData = EmoteData(
                        name: emote.code,
                        imageURL: "https://cdn.betterttv.net/emote/\(emote.id)/3x",
                        provider: "BTTV"
                    )
                    
                    emoteCache[emote.code] = emoteData
                    
                    // Register with API
                    try? api.addEmote(
                        name: emote.code,
                        imageURL: emoteData.imageURL,
                        provider: "BTTV"
                    )
                }
                
                api.log(
                    level: .info,
                    message: "Loaded \(emotes.count) BTTV emotes",
                    metadata: ["count": emotes.count]
                )
                
                // Save to cache
                try? saveEmoteCache()
            }
            
        } catch {
            api.log(
                level: .error,
                message: "Failed to load BTTV emotes: \(error.localizedDescription)",
                metadata: ["error": error.localizedDescription]
            )
        }
    }
    
    private func load7TVEmotes() async {
        guard let api = api else { return }
        
        do {
            api.log(level: .info, message: "Loading 7TV emotes...", metadata: nil)
            
            // Fetch global 7TV emotes
            let response = try await api.makeHTTPRequest(
                url: "https://7tv.io/v3/emote-sets/global",
                method: .GET,
                headers: nil,
                body: nil
            )
            
            // Parse JSON response
            if let emoteSet = try? JSONDecoder().decode(SevenTVEmoteSet.self, from: response.body) {
                for emote in emoteSet.emotes {
                    let emoteData = EmoteData(
                        name: emote.name,
                        imageURL: "https://cdn.7tv.app/emote/\(emote.id)/4x.webp",
                        provider: "7TV"
                    )
                    
                    emoteCache[emote.name] = emoteData
                    
                    // Register with API
                    try? api.addEmote(
                        name: emote.name,
                        imageURL: emoteData.imageURL,
                        provider: "7TV"
                    )
                }
                
                api.log(
                    level: .info,
                    message: "Loaded \(emoteSet.emotes.count) 7TV emotes",
                    metadata: ["count": emoteSet.emotes.count]
                )
                
                // Save to cache
                try? saveEmoteCache()
            }
            
        } catch {
            api.log(
                level: .error,
                message: "Failed to load 7TV emotes: \(error.localizedDescription)",
                metadata: ["error": error.localizedDescription]
            )
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleChatMessage(_ event: PluginEvent) {
        guard let api = api else { return }
        
        // Process message for emotes
        if let messageData = event.data["message"] as? [String: Any],
           let content = messageData["content"] as? String {
            
            let words = content.split(separator: " ")
            for word in words {
                let wordStr = String(word)
                if emoteCache.keys.contains(wordStr) {
                    // Emote found - emit event for UI to render it
                    api.emitEvent(PluginEvent(
                        name: "emote.detected",
                        data: [
                            "emote": wordStr,
                            "url": emoteCache[wordStr]?.imageURL ?? "",
                            "provider": emoteCache[wordStr]?.provider ?? ""
                        ],
                        source: metadata.identifier
                    ))
                }
            }
        }
    }
    
    private func handleEmotesCommand(channel: String, args: [String]) {
        guard let api = api else { return }
        
        if args.isEmpty {
            // Show emote count
            Task {
                try? await api.sendChatMessage(
                    channel: channel,
                    message: "Better Emotes: \(emoteCache.count) emotes loaded (BTTV + 7TV)"
                )
            }
        } else if args[0] == "reload" {
            // Reload emotes
            Task {
                await loadBTTVEmotes()
                await load7TVEmotes()
                
                try? await api.sendChatMessage(
                    channel: channel,
                    message: "Better Emotes: Reloaded \(emoteCache.count) emotes"
                )
            }
        }
    }
    
    private func handleSettingsChanged(_ event: PluginEvent) {
        guard let api = api else { return }
        
        api.log(level: .info, message: "Settings changed", metadata: event.data)
        
        // Reload emotes if settings changed
        Task {
            await loadBTTVEmotes()
            await load7TVEmotes()
        }
    }
    
    // MARK: - Storage
    
    private func saveEmoteCache() throws {
        guard let api = api else { return }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(emoteCache)
        try api.saveData(key: "emote_cache", value: data)
    }
    
    private func loadEmoteCache() throws {
        guard let api = api else { return }
        
        if let data = try api.loadData(key: "emote_cache") {
            let decoder = JSONDecoder()
            emoteCache = try decoder.decode([String: EmoteData].self, from: data)
        }
    }
    
    // MARK: - UI
    
    private func showSettings() {
        guard let api = api else { return }
        
        // Register settings schema
        let schema = SettingsSchema(
            pluginId: metadata.identifier,
            sections: [
                SettingsSection(
                    title: "Emote Providers",
                    settings: [
                        Setting(
                            key: "bttv_enabled",
                            title: "Enable BTTV",
                            type: .boolean,
                            defaultValue: true
                        ),
                        Setting(
                            key: "7tv_enabled",
                            title: "Enable 7TV",
                            type: .boolean,
                            defaultValue: true
                        )
                    ]
                ),
                SettingsSection(
                    title: "Cache",
                    settings: [
                        Setting(
                            key: "cache_duration",
                            title: "Cache Duration (hours)",
                            type: .number,
                            defaultValue: 24
                        )
                    ]
                )
            ]
        )
        
        try? api.registerSettings(schema: schema)
    }
}

// MARK: - Supporting Types

struct EmoteData: Codable {
    let name: String
    let imageURL: String
    let provider: String
}

struct BTTVEmote: Codable {
    let id: String
    let code: String
    let imageType: String
}

struct SevenTVEmoteSet: Codable {
    let id: String
    let name: String
    let emotes: [SevenTVEmote]
}

struct SevenTVEmote: Codable {
    let id: String
    let name: String
}

enum PluginError: Error {
    case notInitialized
    case invalidConfiguration
}
```
