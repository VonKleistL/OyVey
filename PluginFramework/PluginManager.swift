//
//  PluginManager.swift
//  OyVey Plugin Framework
//
//  Plugin loading, lifecycle management, and hot-reload support
//

import Foundation
import Combine

/// Main plugin management system
@MainActor
public class PluginManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = PluginManager()
    
    // MARK: - Published Properties
    
    @Published public private(set) var loadedPlugins: [String: LoadedPlugin] = [:]
    @Published public private(set) var isLoading = false
    @Published public private(set) var errors: [PluginError] = []
    
    // MARK: - Private Properties
    
    private var pluginDirectories: [URL] = []
    private var apiImplementation: PluginAPIImplementationProtocol?
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupPluginDirectories()
        print("[PluginManager] Initialized with directories: \(pluginDirectories)")
    }
    
    // MARK: - Setup
    
    private func setupPluginDirectories() {
        // Application Support directory
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let oyVeyDir = appSupport.appendingPathComponent("OyVey/Plugins")
            pluginDirectories.append(oyVeyDir)
            
            // Create directory if needed
            try? FileManager.default.createDirectory(at: oyVeyDir, withIntermediateDirectories: true)
        }
        
        // Bundle plugins
        if let bundlePlugins = Bundle.main.url(forResource: "Plugins", withExtension: nil) {
            pluginDirectories.append(bundlePlugins)
        }
    }
    
    /// Set the API implementation
    public func setAPIImplementation(_ api: PluginAPIImplementationProtocol) {
        self.apiImplementation = api
    }
    
    // MARK: - Plugin Discovery
    
    /// Discover all available plugins
    public func discoverPlugins() async -> [PluginInfo] {
        var discovered: [PluginInfo] = []
        
        for directory in pluginDirectories {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
                
                for url in contents {
                    if url.pathExtension == "oyplugin" || url.pathExtension == "bundle" {
                        if let info = try? await loadPluginInfo(from: url) {
                            discovered.append(info)
                        }
                    }
                }
            } catch {
                print("[PluginManager] Error discovering plugins in \(directory): \(error)")
            }
        }
        
        return discovered
    }
    
    private func loadPluginInfo(from url: URL) async throws -> PluginInfo {
        // Load manifest.json
        let manifestURL = url.appendingPathComponent("manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(PluginManifest.self, from: data)
        
        return PluginInfo(
            url: url,
            manifest: manifest
        )
    }
    
    // MARK: - Plugin Loading
    
    /// Load a plugin by identifier
    public func loadPlugin(identifier: String) async throws {
        guard !loadedPlugins.keys.contains(identifier) else {
            throw PluginError.alreadyLoaded(identifier)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Find plugin
        let plugins = await discoverPlugins()
        guard let pluginInfo = plugins.first(where: { $0.manifest.identifier == identifier }) else {
            throw PluginError.notFound(identifier)
        }
        
        // Check version compatibility
        guard isCompatible(pluginInfo.manifest) else {
            throw PluginError.incompatibleVersion(identifier)
        }
        
        // Load dependencies first
        if let dependencies = pluginInfo.manifest.dependencies {
            for dep in dependencies {
                if !loadedPlugins.keys.contains(dep) {
                    try await loadPlugin(identifier: dep)
                }
            }
        }
        
        // Load the plugin bundle
        guard let bundle = Bundle(url: pluginInfo.url) else {
            throw PluginError.invalidBundle(identifier)
        }
        
        // Instantiate plugin
        guard let pluginClass = bundle.principalClass as? OyVeyPlugin.Type else {
            throw PluginError.invalidPrincipalClass(identifier)
        }
        
        let plugin = pluginClass.init()
        
        // Verify permissions
        try verifyPermissions(plugin.metadata.permissions)
        
        // Call onLoad
        guard let api = apiImplementation else {
            throw PluginError.apiNotInitialized
        }
        
        try await plugin.onLoad(api: api as! PluginAPI)
        
        // Store loaded plugin
        let loaded = LoadedPlugin(
            plugin: plugin,
            bundle: bundle,
            info: pluginInfo,
            loadedAt: Date()
        )
        
        loadedPlugins[identifier] = loaded
        
        print("[PluginManager] Loaded plugin: \(identifier)")
    }
    
    // MARK: - Plugin Unloading
    
    /// Unload a plugin
    public func unloadPlugin(identifier: String) async throws {
        guard let loaded = loadedPlugins[identifier] else {
            throw PluginError.notLoaded(identifier)
        }
        
        // Check dependencies
        for (otherID, otherPlugin) in loadedPlugins where otherID != identifier {
            if otherPlugin.info.manifest.dependencies?.contains(identifier) == true {
                throw PluginError.hasDependents(identifier)
            }
        }
        
        // Call onUnload
        await loaded.plugin.onUnload()
        
        // Remove
        loadedPlugins.removeValue(forKey: identifier)
        
        print("[PluginManager] Unloaded plugin: \(identifier)")
    }
    
    /// Unload all plugins
    public func unloadAllPlugins() async {
        for identifier in loadedPlugins.keys {
            try? await unloadPlugin(identifier: identifier)
        }
    }
    
    // MARK: - Plugin Reload
    
    /// Reload a plugin (hot-reload)
    public func reloadPlugin(identifier: String) async throws {
        guard loadedPlugins.keys.contains(identifier) else {
            throw PluginError.notLoaded(identifier)
        }
        
        try await unloadPlugin(identifier: identifier)
        try await loadPlugin(identifier: identifier)
    }
    
    // MARK: - Hot Reload Support
    
    /// Enable hot-reload for development
    public func enableHotReload() {
        for directory in pluginDirectories {
            watchDirectory(directory)
        }
    }
    
    private func watchDirectory(_ url: URL) {
        // File system monitoring for hot-reload
        let fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: .main
        )
        
        source.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.handleFileSystemChange()
            }
        }
        
        source.setCancelHandler {
            close(fileDescriptor)
        }
        
        source.resume()
        self.fileMonitor = source
    }
    
    private func handleFileSystemChange() async {
        print("[PluginManager] File system change detected, checking for updates...")
        
        // Reload all plugins
        let identifiers = Array(loadedPlugins.keys)
        for identifier in identifiers {
            do {
                try await reloadPlugin(identifier: identifier)
            } catch {
                print("[PluginManager] Failed to reload \(identifier): \(error)")
            }
        }
    }
    
    // MARK: - Validation
    
    private func isCompatible(_ manifest: PluginManifest) -> Bool {
        // Check version compatibility
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return compareVersions(appVersion, manifest.minOyVeyVersion) >= 0
    }
    
    private func compareVersions(_ v1: String, _ v2: String) -> Int {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(parts1.count, parts2.count) {
            let part1 = i < parts1.count ? parts1[i] : 0
            let part2 = i < parts2.count ? parts2[i] : 0
            
            if part1 < part2 { return -1 }
            if part1 > part2 { return 1 }
        }
        
        return 0
    }
    
    private func verifyPermissions(_ permissions: [PluginPermission]) throws {
        // Validate requested permissions
        // In production, this would check user-granted permissions
        print("[PluginManager] Verifying permissions: \(permissions)")
    }
}

// MARK: - Supporting Types

public struct LoadedPlugin {
    public let plugin: OyVeyPlugin
    public let bundle: Bundle
    public let info: PluginInfo
    public let loadedAt: Date
}

public struct PluginInfo {
    public let url: URL
    public let manifest: PluginManifest
}

public struct PluginManifest: Codable {
    public let identifier: String
    public let name: String
    public let version: String
    public let author: String
    public let description: String?
    public let minOyVeyVersion: String
    public let dependencies: [String]?
    public let permissions: [PluginPermission]
}

public enum PluginError: LocalizedError {
    case notFound(String)
    case alreadyLoaded(String)
    case notLoaded(String)
    case invalidBundle(String)
    case invalidPrincipalClass(String)
    case incompatibleVersion(String)
    case hasDependents(String)
    case apiNotInitialized
    
    public var errorDescription: String? {
        switch self {
        case .notFound(let id): return "Plugin not found: \(id)"
        case .alreadyLoaded(let id): return "Plugin already loaded: \(id)"
        case .notLoaded(let id): return "Plugin not loaded: \(id)"
        case .invalidBundle(let id): return "Invalid plugin bundle: \(id)"
        case .invalidPrincipalClass(let id): return "Invalid principal class: \(id)"
        case .incompatibleVersion(let id): return "Incompatible version: \(id)"
        case .hasDependents(let id): return "Plugin has dependents: \(id)"
        case .apiNotInitialized: return "Plugin API not initialized"
        }
    }
}

// Protocol for dependency injection
public protocol PluginAPIImplementationProtocol: AnyObject {}
