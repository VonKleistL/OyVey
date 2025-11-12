# OyVey Plugin Framework Integration Guide

## Integrating the Plugin System into the Main Application

This guide explains how to integrate the complete plugin framework into your OyVey native macOS Twitch client.

## File Structure

```
OyVey/
├── OyVeyApp.swift                      # Main app entry point
├── PluginFramework/
│   ├── PluginProtocol.swift           # Core protocol definitions
│   ├── PluginManager.swift            # Plugin lifecycle management
│   ├── PluginAPI.swift                # API implementation
│   └── README.md                      # Framework documentation
├── Plugins/                            # Plugin directory (user-installable)
│   └── BetterEmotes/
│       ├── manifest.json
│       └── BetterEmotesPlugin.dylib
└── Examples/
    └── SamplePlugin.swift              # Example plugin implementation
```

## Step 1: Initialize Plugin System in App

### OyVeyApp.swift

```swift
import SwiftUI

@main
struct OyVeyApp: App {
    @StateObject private var pluginSystem = PluginSystemCoordinator()
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pluginSystem)
                .environmentObject(appState)
        }
        .commands {
            // Add plugin menu
            PluginMenuCommands(pluginSystem: pluginSystem)
        }
    }
}
```

## Step 2: Create Plugin System Coordinator

### PluginSystemCoordinator.swift

```swift
import Foundation
import Combine

@MainActor
class PluginSystemCoordinator: ObservableObject {
    @Published var plugins: [PluginInfo] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var pluginManager: PluginManager!
    private var pluginAPI: OyVeyPluginAPI!
    
    // Component managers
    private var eventBus: PluginEventBus!
    private var networkManager: NetworkManager!
    private var twitchAPI: TwitchAPIManager!
    private var uiManager: UIManager!
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupPluginSystem()
    }
    
    private func setupPluginSystem() {
        // Initialize components
        eventBus = PluginEventBus()
        networkManager = NetworkManager()
        twitchAPI = TwitchAPIManager(networkManager: networkManager)
        uiManager = UIManager()
        
        // Get plugins directory
        let pluginsPath = getPluginsDirectory()
        
        // Create plugin manager
        pluginManager = PluginManager(pluginsDirectory: pluginsPath)
        
        // Subscribe to plugin manager events
        pluginManager.$loadedPlugins
            .map { $0.map { PluginInfo(from: $0) } }
            .assign(to: &$plugins)
        
        // Load plugins
        Task {
            await loadPlugins()
        }
    }
    
    private func getPluginsDirectory() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let pluginsDir = appSupport
            .appendingPathComponent("OyVey", isDirectory: true)
            .appendingPathComponent("Plugins", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: pluginsDir,
            withIntermediateDirectories: true
        )
        
        return pluginsDir
    }
    
    func loadPlugins() async {
        isLoading = true
        
        do {
            // Discover plugins
            try await pluginManager.discoverPlugins()
            
            // Load each plugin
            for pluginId in pluginManager.availablePlugins {
                try await loadPlugin(identifier: pluginId)
            }
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func loadPlugin(identifier: String) async throws {
        // Create storage manager for this plugin
        let storageManager = try PluginStorageManager(pluginId: identifier)
        
        // Create API instance for this plugin
        let api = OyVeyPluginAPI(
            pluginManager: pluginManager,
            eventBus: eventBus,
            storageManager: storageManager,
            networkManager: networkManager,
            twitchAPI: twitchAPI,
            uiManager: uiManager
        )
        
        // Load and initialize plugin
        try await pluginManager.loadPlugin(identifier: identifier, api: api)
    }
    
    func activatePlugin(identifier: String) async throws {
        try await pluginManager.activatePlugin(identifier: identifier)
    }
    
    func deactivatePlugin(identifier: String) async throws {
        try await pluginManager.deactivatePlugin(identifier: identifier)
    }
    
    func reloadPlugin(identifier: String) async throws {
        try await pluginManager.reloadPlugin(identifier: identifier)
    }
    
    func unloadPlugin(identifier: String) async throws {
        try await pluginManager.unloadPlugin(identifier: identifier)
    }
    
    // Get API for Twitch authentication
    func setTwitchCredentials(accessToken: String, clientId: String) {
        twitchAPI.setCredentials(accessToken: accessToken, clientId: clientId)
    }
    
    // Emit events to plugins
    func emitEvent(_ event: PluginEvent) {
        eventBus.emit(event)
    }
}

struct PluginInfo: Identifiable {
    let id: String
    let name: String
    let version: String
    let author: String
    let description: String
    let isActive: Bool
    let hasError: Bool
    let errorMessage: String?
    
    init(from plugin: LoadedPlugin) {
        self.id = plugin.metadata.identifier
        self.name = plugin.metadata.name
        self.version = plugin.metadata.version
        self.author = plugin.metadata.author
        self.description = plugin.metadata.description
        self.isActive = plugin.isActive
        self.hasError = plugin.hasError
        self.errorMessage = plugin.error?.localizedDescription
    }
}
```

## Step 3: Create Plugin Management UI

### PluginManagerView.swift

```swift
import SwiftUI

struct PluginManagerView: View {
    @EnvironmentObject var pluginSystem: PluginSystemCoordinator
    @State private var selectedPlugin: PluginInfo?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            // Plugin list
            List(pluginSystem.plugins, selection: $selectedPlugin) { plugin in
                PluginRowView(plugin: plugin)
                    .tag(plugin)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 250)
            
            // Plugin details
            if let plugin = selectedPlugin {
                PluginDetailView(plugin: plugin)
            } else {
                Text("Select a plugin to view details")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Plugin Manager")
        .toolbar {
            ToolbarItemGroup {
                Button(action: reloadPlugins) {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                
                Button(action: openPluginsFolder) {
                    Label("Open Folder", systemImage: "folder")
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func reloadPlugins() {
        Task {
            await pluginSystem.loadPlugins()
        }
    }
    
    private func openPluginsFolder() {
        // Open plugins directory in Finder
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: pluginSystem.pluginsDirectory.path)
    }
}

struct PluginRowView: View {
    let plugin: PluginInfo
    
    var body: some View {
        HStack {
            Image(systemName: pluginIcon)
                .foregroundColor(pluginColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name)
                    .font(.headline)
                
                Text(plugin.version)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if plugin.hasError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var pluginIcon: String {
        if plugin.hasError {
            return "puzzlepiece.fill"
        } else if plugin.isActive {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var pluginColor: Color {
        if plugin.hasError {
            return .orange
        } else if plugin.isActive {
            return .green
        } else {
            return .gray
        }
    }
}

struct PluginDetailView: View {
    @EnvironmentObject var pluginSystem: PluginSystemCoordinator
    let plugin: PluginInfo
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(plugin.name)
                            .font(.title)
                        
                        Text("by \\(plugin.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Activate/Deactivate button
                    Button(plugin.isActive ? "Deactivate" : "Activate") {
                        togglePlugin()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Divider()
                
                // Description
                Text(plugin.description)
                    .font(.body)
                
                // Version info
                InfoRow(title: "Version", value: plugin.version)
                InfoRow(title: "Status", value: plugin.isActive ? "Active" : "Inactive")
                
                if plugin.hasError, let error = plugin.errorMessage {
                    InfoRow(title: "Error", value: error)
                        .foregroundColor(.red)
                }
                
                Divider()
                
                // Actions
                HStack {
                    Button("Reload") {
                        reloadPlugin()
                    }
                    
                    Button("Uninstall") {
                        uninstallPlugin()
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 400)
    }
    
    private func togglePlugin() {
        Task {
            do {
                if plugin.isActive {
                    try await pluginSystem.deactivatePlugin(identifier: plugin.id)
                } else {
                    try await pluginSystem.activatePlugin(identifier: plugin.id)
                }
            } catch {
                print("Error toggling plugin: \\(error)")
            }
        }
    }
    
    private func reloadPlugin() {
        Task {
            try? await pluginSystem.reloadPlugin(identifier: plugin.id)
        }
    }
    
    private func uninstallPlugin() {
        Task {
            try? await pluginSystem.unloadPlugin(identifier: plugin.id)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
```

## Step 4: Add Plugin Menu Commands

### PluginMenuCommands.swift

```swift
import SwiftUI

struct PluginMenuCommands: Commands {
    @ObservedObject var pluginSystem: PluginSystemCoordinator
    
    var body: some Commands {
        CommandMenu("Plugins") {
            Button("Plugin Manager...") {
                openPluginManager()
            }
            .keyboardShortcut("P", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Reload All Plugins") {
                Task {
                    await pluginSystem.loadPlugins()
                }
            }
            
            Button("Open Plugins Folder") {
                openPluginsFolder()
            }
            
            Divider()
            
            ForEach(pluginSystem.plugins) { plugin in
                Toggle(plugin.name, isOn: Binding(
                    get: { plugin.isActive },
                    set: { isActive in
                        togglePlugin(plugin, active: isActive)
                    }
                ))
            }
        }
    }
    
    private func openPluginManager() {
        // Open plugin manager window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Plugin Manager"
        window.contentView = NSHostingView(
            rootView: PluginManagerView()
                .environmentObject(pluginSystem)
        )
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    private func openPluginsFolder() {
        NSWorkspace.shared.selectFile(
            nil,
            inFileViewerRootedAtPath: pluginSystem.pluginsDirectory.path
        )
    }
    
    private func togglePlugin(_ plugin: PluginInfo, active: Bool) {
        Task {
            do {
                if active {
                    try await pluginSystem.activatePlugin(identifier: plugin.id)
                } else {
                    try await pluginSystem.deactivatePlugin(identifier: plugin.id)
                }
            } catch {
                print("Error toggling plugin: \\(error)")
            }
        }
    }
}
```

## Step 5: Integrate with Chat System

### ChatViewModel.swift

```swift
import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    
    private let pluginEventBus: PluginEventBus
    private var cancellables = Set<AnyCancellable>()
    
    init(pluginEventBus: PluginEventBus) {
        self.pluginEventBus = pluginEventBus
    }
    
    func sendMessage(_ message: String, in channel: String) {
        // Send message via Twitch
        // ...
        
        // Emit event for plugins
        pluginEventBus.emit(PluginEvent(
            name: "chat.message.sent",
            data: [
                "channel": channel,
                "message": message,
                "timestamp": Date()
            ],
            source: "chat"
        ))
    }
    
    func receiveMessage(_ message: ChatMessage) {
        messages.append(message)
        
        // Emit event for plugins
        pluginEventBus.emit(PluginEvent(
            name: "chat.message.received",
            data: [
                "channel": message.channel,
                "username": message.username,
                "message": message.content,
                "timestamp": message.timestamp
            ],
            source: "chat"
        ))
    }
}
```

## Step 6: Add to Build System

### Package.swift (if using SPM)

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OyVey",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OyVey", targets: ["OyVey"]),
    ],
    dependencies: [
        // Add any dependencies here
    ],
    targets: [
        .executableTarget(
            name: "OyVey",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "OyVeyTests",
            dependencies: ["OyVey"],
            path: "Tests"
        )
    ]
)
```

## Testing the Integration

### 1. Build and Run

```bash
cd OyVey
swift build
swift run
```

### 2. Install Sample Plugin

```bash
# Copy sample plugin to plugins directory
cp -r Examples/BetterEmotes ~/Library/Application\\ Support/OyVey/Plugins/
```

### 3. Verify Plugin Loading

Check the console for plugin initialization messages:

```
[INFO] Better Emotes plugin initializing...
[INFO] Better Emotes plugin initialized successfully
[INFO] Better Emotes plugin activated
[INFO] Loaded 200 BTTV emotes
[INFO] Loaded 150 7TV emotes
```

## Troubleshooting

### Plugin Not Loading

1. Check plugin manifest.json is valid
2. Verify plugin file has correct permissions
3. Check console for error messages
4. Enable debug logging in PluginManager

### Hot Reload Not Working

1. Ensure file watcher is running
2. Check plugin directory is correct
3. Try manual reload via Plugin Manager

### API Errors

1. Verify Twitch credentials are set
2. Check network connectivity
3. Review API error logs

## Next Steps

1. **Implement remaining Twitch API methods** in TwitchAPIManager
2. **Add plugin settings UI** for user configuration
3. **Create plugin marketplace** for easy discovery
4. **Add automatic updates** for installed plugins
5. **Implement plugin sandboxing** for security

## Resources

- [Plugin Development Guide](./Plugin-Dev-Guide.md)
- [PluginProtocol.swift](./PluginProtocol.swift)
- [PluginManager.swift](./PluginManager.swift)
- [PluginAPI.swift](./PluginAPI.swift)
- [SamplePlugin.swift](../Examples/SamplePlugin.swift)

## Support

For issues or questions:
- GitHub Issues: https://github.com/VonKleistL/OyVey/issues
- Discord: [Join Server]
- Email: support@oyvey.app
