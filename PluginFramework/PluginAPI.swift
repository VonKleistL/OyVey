```swift
//
//  PluginAPI.swift
//  OyVey - Native macOS Twitch Client
//
//  Plugin API Implementation
//  This file provides the concrete implementation of the PluginAPI protocol
//  that plugins will use to interact with the host application.
//

import Foundation
import SwiftUI
import Combine

/// Main implementation of the PluginAPI protocol
/// This class provides all the functionality that plugins can access
public class OyVeyPluginAPI: PluginAPI {
    
    // MARK: - Properties
    
    private weak var pluginManager: PluginManager?
    private let eventBus: PluginEventBus
    private let storageManager: PluginStorageManager
    private let networkManager: NetworkManager
    private let twitchAPI: TwitchAPIManager
    private let uiManager: UIManager
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(pluginManager: PluginManager,
                eventBus: PluginEventBus,
                storageManager: PluginStorageManager,
                networkManager: NetworkManager,
                twitchAPI: TwitchAPIManager,
                uiManager: UIManager) {
        self.pluginManager = pluginManager
        self.eventBus = eventBus
        self.storageManager = storageManager
        self.networkManager = networkManager
        self.twitchAPI = twitchAPI
        self.uiManager = uiManager
    }
    
    // MARK: - Plugin Information
    
    public func getHostApplicationVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    public func getAPIVersion() -> String {
        return "1.0.0"
    }
    
    // MARK: - Event System
    
    public func subscribeToEvent(_ eventName: String, handler: @escaping (PluginEvent) -> Void) -> String {
        return eventBus.subscribe(to: eventName, handler: handler)
    }
    
    public func unsubscribeFromEvent(_ subscriptionId: String) {
        eventBus.unsubscribe(subscriptionId)
    }
    
    public func emitEvent(_ event: PluginEvent) {
        eventBus.emit(event)
    }
    
    // MARK: - Storage API
    
    public func saveData(key: String, value: Data) throws {
        try storageManager.save(key: key, value: value)
    }
    
    public func loadData(key: String) throws -> Data? {
        return try storageManager.load(key: key)
    }
    
    public func deleteData(key: String) throws {
        try storageManager.delete(key: key)
    }
    
    public func getAllKeys() throws -> [String] {
        return try storageManager.getAllKeys()
    }
    
    // MARK: - Network API
    
    public func makeHTTPRequest(url: String,
                                method: HTTPMethod,
                                headers: [String: String]?,
                                body: Data?) async throws -> HTTPResponse {
        return try await networkManager.request(
            url: url,
            method: method,
            headers: headers,
            body: body
        )
    }
    
    // MARK: - Twitch API
    
    public func getCurrentChannel() async throws -> TwitchChannel {
        return try await twitchAPI.getCurrentChannel()
    }
    
    public func getChannelInfo(channelName: String) async throws -> TwitchChannel {
        return try await twitchAPI.getChannel(name: channelName)
    }
    
    public func sendChatMessage(channel: String, message: String) async throws {
        try await twitchAPI.sendMessage(channel: channel, message: message)
    }
    
    public func getChatMessages(channel: String, limit: Int) async throws -> [ChatMessage] {
        return try await twitchAPI.getRecentMessages(channel: channel, limit: limit)
    }
    
    public func getStreamInfo(channel: String) async throws -> StreamInfo? {
        return try await twitchAPI.getStreamInfo(channel: channel)
    }
    
    public func getUserInfo(username: String) async throws -> TwitchUser {
        return try await twitchAPI.getUser(username: username)
    }
    
    // MARK: - UI Integration
    
    public func registerMenuItem(title: String, action: @escaping () -> Void) -> String {
        return uiManager.addMenuItem(title: title, action: action)
    }
    
    public func unregisterMenuItem(_ menuItemId: String) {
        uiManager.removeMenuItem(id: menuItemId)
    }
    
    public func showNotification(title: String, message: String, type: NotificationType) {
        uiManager.showNotification(title: title, message: message, type: type)
    }
    
    public func addCustomView(_ view: PluginView, position: ViewPosition) -> String {
        return uiManager.addCustomView(view, at: position)
    }
    
    public func removeCustomView(_ viewId: String) {
        uiManager.removeCustomView(id: viewId)
    }
    
    public func updateCustomView(_ viewId: String, view: PluginView) {
        uiManager.updateCustomView(id: viewId, view: view)
    }
    
    // MARK: - Chat Integration
    
    public func registerChatCommand(command: String, handler: @escaping (String, [String]) -> Void) -> String {
        return eventBus.registerChatCommand(command: command, handler: handler)
    }
    
    public func unregisterChatCommand(_ commandId: String) {
        eventBus.unregisterChatCommand(id: commandId)
    }
    
    public func addChatBadge(name: String, imageURL: String) throws {
        try uiManager.addChatBadge(name: name, imageURL: imageURL)
    }
    
    public func addEmote(name: String, imageURL: String, provider: String) throws {
        try uiManager.addEmote(name: name, imageURL: imageURL, provider: provider)
    }
    
    // MARK: - Settings API
    
    public func registerSettings(schema: SettingsSchema) throws {
        try uiManager.registerPluginSettings(schema: schema)
    }
    
    public func getSettingValue(key: String) throws -> Any? {
        return try storageManager.getSetting(key: key)
    }
    
    public func setSettingValue(key: String, value: Any) throws {
        try storageManager.setSetting(key: key, value: value)
        emitEvent(PluginEvent(
            name: "settings.changed",
            data: ["key": key, "value": value],
            source: "system"
        ))
    }
    
    // MARK: - Logging
    
    public func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        let logEntry = PluginLogEntry(
            level: level,
            message: message,
            metadata: metadata,
            timestamp: Date()
        )
        
        // Emit log event
        emitEvent(PluginEvent(
            name: "plugin.log",
            data: ["entry": logEntry],
            source: "plugin"
        ))
        
        // Also print to console for debugging
        print("[\(level)] \(message)")
        if let metadata = metadata {
            print("Metadata: \(metadata)")
        }
    }
    
    // MARK: - Inter-Plugin Communication
    
    public func sendMessageToPlugin(pluginId: String, message: PluginMessage) throws {
        guard let targetPlugin = pluginManager?.getPlugin(id: pluginId) else {
            throw PluginAPIError.pluginNotFound(pluginId)
        }
        
        // Emit inter-plugin message event
        emitEvent(PluginEvent(
            name: "plugin.message",
            data: [
                "targetPluginId": pluginId,
                "message": message
            ],
            source: "plugin-communication"
        ))
    }
    
    public func broadcastMessage(message: PluginMessage) {
        emitEvent(PluginEvent(
            name: "plugin.broadcast",
            data: ["message": message],
            source: "plugin-communication"
        ))
    }
}

// MARK: - Supporting Classes

/// Event Bus for managing plugin events
public class PluginEventBus {
    private var subscriptions: [String: EventSubscription] = [:]
    private var chatCommands: [String: ChatCommandHandler] = [:]
    private let queue = DispatchQueue(label: "com.oyvey.plugin.eventbus", attributes: .concurrent)
    
    struct EventSubscription {
        let id: String
        let eventName: String
        let handler: (PluginEvent) -> Void
    }
    
    struct ChatCommandHandler {
        let id: String
        let command: String
        let handler: (String, [String]) -> Void
    }
    
    public func subscribe(to eventName: String, handler: @escaping (PluginEvent) -> Void) -> String {
        let id = UUID().uuidString
        let subscription = EventSubscription(id: id, eventName: eventName, handler: handler)
        
        queue.async(flags: .barrier) {
            self.subscriptions[id] = subscription
        }
        
        return id
    }
    
    public func unsubscribe(_ subscriptionId: String) {
        queue.async(flags: .barrier) {
            self.subscriptions.removeValue(forKey: subscriptionId)
        }
    }
    
    public func emit(_ event: PluginEvent) {
        queue.async {
            for (_, subscription) in self.subscriptions {
                if subscription.eventName == event.name || subscription.eventName == "*" {
                    subscription.handler(event)
                }
            }
        }
    }
    
    public func registerChatCommand(command: String, handler: @escaping (String, [String]) -> Void) -> String {
        let id = UUID().uuidString
        let commandHandler = ChatCommandHandler(id: id, command: command, handler: handler)
        
        queue.async(flags: .barrier) {
            self.chatCommands[id] = commandHandler
        }
        
        return id
    }
    
    public func unregisterChatCommand(id: String) {
        queue.async(flags: .barrier) {
            self.chatCommands.removeValue(forKey: id)
        }
    }
    
    public func handleChatCommand(command: String, channel: String, args: [String]) {
        queue.async {
            for (_, handler) in self.chatCommands {
                if handler.command == command {
                    handler.handler(channel, args)
                }
            }
        }
    }
}

/// Storage Manager for plugin data persistence
public class PluginStorageManager {
    private let baseURL: URL
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init(pluginId: String) throws {
        // Create plugin-specific storage directory
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        baseURL = appSupport
            .appendingPathComponent("OyVey", isDirectory: true)
            .appendingPathComponent("PluginData", isDirectory: true)
            .appendingPathComponent(pluginId, isDirectory: true)
        
        // Create directory if it doesn't exist
        try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }
    
    public func save(key: String, value: Data) throws {
        let fileURL = baseURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
        try value.write(to: fileURL)
    }
    
    public func load(key: String) throws -> Data? {
        let fileURL = baseURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return try Data(contentsOf: fileURL)
    }
    
    public func delete(key: String) throws {
        let fileURL = baseURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    public func getAllKeys() throws -> [String] {
        let contents = try fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
        return contents.map { $0.lastPathComponent.removingPercentEncoding ?? $0.lastPathComponent }
    }
    
    public func getSetting(key: String) throws -> Any? {
        guard let data = try load(key: "settings.\(key)") else {
            return nil
        }
        
        return try JSONSerialization.jsonObject(with: data)
    }
    
    public func setSetting(key: String, value: Any) throws {
        let data = try JSONSerialization.data(withJSONObject: value)
        try save(key: "settings.\(key)", value: data)
    }
}

/// Network Manager for HTTP requests
public class NetworkManager {
    private let session: URLSession
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    public func request(url: String,
                       method: HTTPMethod,
                       headers: [String: String]?,
                       body: Data?) async throws -> HTTPResponse {
        guard let requestURL = URL(string: url) else {
            throw PluginAPIError.invalidURL(url)
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Add headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PluginAPIError.invalidResponse
        }
        
        return HTTPResponse(
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
            body: data
        )
    }
}

/// Twitch API Manager
public class TwitchAPIManager {
    private let networkManager: NetworkManager
    private let baseURL = "https://api.twitch.tv/helix"
    private var accessToken: String?
    private var clientId: String?
    
    public init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    public func setCredentials(accessToken: String, clientId: String) {
        self.accessToken = accessToken
        self.clientId = clientId
    }
    
    private func makeRequest(endpoint: String, method: HTTPMethod = .GET, body: Data? = nil) async throws -> HTTPResponse {
        guard let token = accessToken, let client = clientId else {
            throw PluginAPIError.unauthorized
        }
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Client-Id": client,
            "Content-Type": "application/json"
        ]
        
        return try await networkManager.request(
            url: "\(baseURL)\(endpoint)",
            method: method,
            headers: headers,
            body: body
        )
    }
    
    public func getCurrentChannel() async throws -> TwitchChannel {
        // Implementation would fetch current channel
        throw PluginAPIError.notImplemented
    }
    
    public func getChannel(name: String) async throws -> TwitchChannel {
        let response = try await makeRequest(endpoint: "/users?login=\(name)")
        // Parse response and return channel
        throw PluginAPIError.notImplemented
    }
    
    public func sendMessage(channel: String, message: String) async throws {
        // Implementation would send chat message
        throw PluginAPIError.notImplemented
    }
    
    public func getRecentMessages(channel: String, limit: Int) async throws -> [ChatMessage] {
        // Implementation would fetch recent messages
        throw PluginAPIError.notImplemented
    }
    
    public func getStreamInfo(channel: String) async throws -> StreamInfo? {
        let response = try await makeRequest(endpoint: "/streams?user_login=\(channel)")
        // Parse and return stream info
        throw PluginAPIError.notImplemented
    }
    
    public func getUser(username: String) async throws -> TwitchUser {
        let response = try await makeRequest(endpoint: "/users?login=\(username)")
        // Parse and return user info
        throw PluginAPIError.notImplemented
    }
}

/// UI Manager for plugin UI integration
public class UIManager {
    private var menuItems: [String: MenuItem] = [:]
    private var customViews: [String: CustomViewEntry] = [:]
    private var chatBadges: [String: String] = [:]
    private var emotes: [String: EmoteEntry] = [:]
    private var pluginSettings: [String: SettingsSchema] = [:]
    
    struct MenuItem {
        let id: String
        let title: String
        let action: () -> Void
    }
    
    struct CustomViewEntry {
        let id: String
        let view: PluginView
        let position: ViewPosition
    }
    
    struct EmoteEntry {
        let name: String
        let imageURL: String
        let provider: String
    }
    
    public func addMenuItem(title: String, action: @escaping () -> Void) -> String {
        let id = UUID().uuidString
        let item = MenuItem(id: id, title: title, action: action)
        menuItems[id] = item
        
        // Notify UI to update menu
        NotificationCenter.default.post(
            name: NSNotification.Name("OyVeyPluginMenuUpdated"),
            object: nil
        )
        
        return id
    }
    
    public func removeMenuItem(id: String) {
        menuItems.removeValue(forKey: id)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("OyVeyPluginMenuUpdated"),
            object: nil
        )
    }
    
    public func showNotification(title: String, message: String, type: NotificationType) {
        // Show native macOS notification
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    public func addCustomView(_ view: PluginView, at position: ViewPosition) -> String {
        let id = UUID().uuidString
        let entry = CustomViewEntry(id: id, view: view, position: position)
        customViews[id] = entry
        
        NotificationCenter.default.post(
            name: NSNotification.Name("OyVeyPluginViewAdded"),
            object: entry
        )
        
        return id
    }
    
    public func removeCustomView(id: String) {
        customViews.removeValue(forKey: id)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("OyVeyPluginViewRemoved"),
            object: id
        )
    }
    
    public func updateCustomView(id: String, view: PluginView) {
        guard var entry = customViews[id] else { return }
        entry = CustomViewEntry(id: id, view: view, position: entry.position)
        customViews[id] = entry
        
        NotificationCenter.default.post(
            name: NSNotification.Name("OyVeyPluginViewUpdated"),
            object: entry
        )
    }
    
    public func addChatBadge(name: String, imageURL: String) throws {
        chatBadges[name] = imageURL
        
        NotificationCenter.default.post(
            name: NSNotification.Name("OyVeyPluginBadgeAdded"),
            object: ["name": name, "url": imageURL]
        )
    }
    
    public func addEmote(name: String, imageURL: String, provider: String) throws {
        let emote = EmoteEntry(name: name, imageURL: imageURL, provider: provider)
        emotes[name] = emote
        
        NotificationCenter.default.post(
            name: NSNotification.Name("OyVeyPluginEmoteAdded"),
            object: emote
        )
    }
    
    public func registerPluginSettings(schema: SettingsSchema) throws {
        pluginSettings[schema.pluginId] = schema
        
        NotificationCenter.default.post(
            name: NSNotification.Name("OyVeyPluginSettingsRegistered"),
            object: schema
        )
    }
}

// MARK: - Error Types

public enum PluginAPIError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case unauthorized
    case pluginNotFound(String)
    case notImplemented
    case storageError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Not authorized to perform this action"
        case .pluginNotFound(let id):
            return "Plugin not found: \(id)"
        case .notImplemented:
            return "This feature is not yet implemented"
        case .storageError(let message):
            return "Storage error: \(message)"
        }
    }
}

// MARK: - Helper Structures

public struct PluginLogEntry: Codable {
    let level: LogLevel
    let message: String
    let metadata: [String: Any]?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case level, message, timestamp
    }
    
    public init(level: LogLevel, message: String, metadata: [String: Any]?, timestamp: Date) {
        self.level = level
        self.message = message
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

public struct HTTPResponse {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data
    
    public init(statusCode: Int, headers: [String: String], body: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}
```
