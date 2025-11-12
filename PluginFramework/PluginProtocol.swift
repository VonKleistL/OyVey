//
//  PluginProtocol.swift
//  OyVey Plugin Framework
//
//  Core protocol definitions for the OyVey plugin system
//

import Foundation

// MARK: - Plugin Metadata

/// Metadata structure for plugin identification and information
public struct PluginMetadata: Codable {
    public let identifier: String
    public let name: String
    public let version: String
    public let author: String
    public let description: String?
    public let minOyVeyVersion: String
    public let dependencies: [String]?
    public let permissions: [PluginPermission]
    
    public init(
        identifier: String? = nil,
        name: String,
        version: String,
        author: String,
        description: String? = nil,
        minOyVeyVersion: String = "1.0.0",
        dependencies: [String]? = nil,
        permissions: [PluginPermission] = []
    ) {
        self.identifier = identifier ?? "com.oyvey.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        self.name = name
        self.version = version
        self.author = author
        self.description = description
        self.minOyVeyVersion = minOyVeyVersion
        self.dependencies = dependencies
        self.permissions = permissions
    }
}

// MARK: - Plugin Permissions

/// Permissions that plugins can request
public enum PluginPermission: String, Codable {
    case networkAccess = "network.access"
    case chatRead = "chat.read"
    case chatWrite = "chat.write"
    case uiModification = "ui.modification"
    case streamMetadata = "stream.metadata"
    case fileSystemRead = "filesystem.read"
    case fileSystemWrite = "filesystem.write"
    case clipboard = "clipboard.access"
    case notifications = "notifications.send"
}

// MARK: - Plugin Lifecycle Protocol

/// Main protocol that all OyVey plugins must conform to
public protocol OyVeyPlugin: AnyObject {
    /// Unique metadata for this plugin
    var metadata: PluginMetadata { get }
    
    /// Called when the plugin is first loaded
    /// - Parameter api: The plugin API interface
    func onLoad(api: PluginAPI) async throws
    
    /// Called when the plugin is about to be unloaded
    func onUnload() async
    
    /// Called when plugin settings are updated
    /// - Parameter settings: New settings dictionary
    func onSettingsChanged(_ settings: [String: Any]) async
}

// MARK: - Plugin API

/// API interface exposed to plugins
public protocol PluginAPI: AnyObject {
    // MARK: Chat
    
    /// Register a custom chat command
    func registerChatCommand(_ command: String, handler: @escaping ([String]) async -> Void)
    
    /// Send a message to chat
    func sendChatMessage(_ message: String) async throws
    
    /// Register a chat message interceptor
    func registerChatInterceptor(_ handler: @escaping (ChatMessage) async -> ChatMessage?)
    
    // MARK: UI
    
    /// Register a custom UI component
    func registerUIComponent(_ component: PluginUIComponent, at location: UILocation)
    
    /// Modify existing UI element
    func modifyUIElement(_ identifier: String, modifier: @escaping (Any) -> Any)
    
    // MARK: Events
    
    /// Subscribe to application events
    func subscribeToEvent<T>(_ event: PluginEvent<T>, handler: @escaping (T) async -> Void)
    
    /// Emit custom plugin event
    func emitEvent<T>(_ event: PluginEvent<T>, data: T) async
    
    // MARK: Storage
    
    /// Get plugin-specific persistent storage
    func getStorage() -> PluginStorage
    
    // MARK: Network
    
    /// Make HTTP request (requires network permission)
    func makeHTTPRequest(_ request: PluginHTTPRequest) async throws -> PluginHTTPResponse
}

// MARK: - Chat Types

public struct ChatMessage: Codable {
    public let id: String
    public let username: String
    public let displayName: String
    public let message: String
    public let timestamp: Date
    public let badges: [String]
    public let color: String?
    public let emotes: [Emote]
    
    public init(id: String, username: String, displayName: String, message: String, timestamp: Date, badges: [String], color: String?, emotes: [Emote]) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.message = message
        self.timestamp = timestamp
        self.badges = badges
        self.color = color
        self.emotes = emotes
    }
}

public struct Emote: Codable {
    public let id: String
    public let name: String
    public let url: String
    public let range: NSRange
}

// MARK: - UI Types

public enum UILocation: String {
    case sidebar
    case toolbar
    case chatPanel
    case streamOverlay
    case settingsPanel
}

public protocol PluginUIComponent {
    var identifier: String { get }
    var view: Any { get } // SwiftUI View
}

// MARK: - Event System

public struct PluginEvent<T> {
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }
    
    // Predefined events
    public static var streamStarted: PluginEvent<StreamInfo> { PluginEvent("stream.started") }
    public static var streamEnded: PluginEvent<StreamInfo> { PluginEvent("stream.ended") }
    public static var chatConnected: PluginEvent<Void> { PluginEvent("chat.connected") }
    public static var chatDisconnected: PluginEvent<Void> { PluginEvent("chat.disconnected") }
}

public struct StreamInfo {
    public let channelName: String
    public let title: String
    public let game: String?
    public let viewerCount: Int
}

// MARK: - Storage

public protocol PluginStorage {
    func get<T: Codable>(_ key: String) async -> T?
    func set<T: Codable>(_ key: String, value: T) async throws
    func remove(_ key: String) async throws
    func clear() async throws
}

// MARK: - Network

public struct PluginHTTPRequest {
    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]?
    public let body: Data?
    
    public enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    public init(url: URL, method: HTTPMethod = .get, headers: [String: String]? = nil, body: Data? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}

public struct PluginHTTPResponse {
    public let statusCode: Int
    public let headers: [String: String]
    public let data: Data
}
