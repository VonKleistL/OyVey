# OyVey Plugin Framework - Developer Guide

## Overview

The OyVey Plugin Framework provides a comprehensive system for extending the native macOS Twitch client with custom functionality. This guide covers the complete implementation of the plugin system including the API, storage, events, and sample plugins.

## Architecture

The plugin framework consists of four main components:

### 1. **PluginProtocol.swift** - Core Definitions
- `Plugin` protocol - Base interface all plugins must implement
- `PluginMetadata` - Plugin information and configuration
- `PluginAPI` protocol - Interface for host application interaction
- Permission system and dependency management

### 2. **PluginManager.swift** - Plugin Lifecycle Management
- Plugin discovery and loading
- Hot-reload support
- Dependency resolution
- Permission validation
- Plugin state management

### 3. **PluginAPI.swift** - API Implementation
- `OyVeyPluginAPI` - Main API implementation
- `PluginEventBus` - Event subscription and emission
- `PluginStorageManager` - Persistent data storage
- `NetworkManager` - HTTP request handling
- `TwitchAPIManager` - Twitch API integration
- `UIManager` - UI integration and notifications

### 4. **SamplePlugin.swift** - Example Implementation
- Demonstrates BTTV and 7TV emote integration
- Shows event handling and chat commands
- Illustrates storage and network usage

## Creating a Plugin

### Basic Plugin Structure

```swift
import Foundation

public class MyPlugin: Plugin {
    public var metadata: PluginMetadata = PluginMetadata(
        identifier: "com.example.myplugin",
        name: "My Plugin",
        version: "1.0.0",
        author: "Your Name",
        description: "Description of your plugin",
        homepage: "https://github.com/yourusername/myplugin",
        requiredPermissions: [.network, .storage],
        dependencies: []
    )
    
    private var api: PluginAPI?
    
    public init() {}
    
    public func initialize(with api: PluginAPI) throws {
        self.api = api
        // Initialize your plugin
    }
    
    public func activate() throws {
        // Activate plugin functionality
    }
    
    public func deactivate() throws {
        // Clean up resources
    }
    
    public func onEvent(_ event: PluginEvent) {
        // Handle events
    }
}
```

## API Reference

### Plugin Lifecycle

#### initialize(with:)
Called when the plugin is first loaded. Use this to set up initial state.

```swift
public func initialize(with api: PluginAPI) throws {
    self.api = api
    api.log(level: .info, message: "Plugin initialized", metadata: nil)
}
```

#### activate()
Called when the plugin is activated. Start functionality here.

```swift
public func activate() throws {
    guard let api = api else { return }
    
    // Subscribe to events
    eventId = api.subscribeToEvent("chat.message") { event in
        // Handle event
    }
}
```

#### deactivate()
Called when the plugin is deactivated. Clean up resources.

```swift
public func deactivate() throws {
    guard let api = api else { return }
    
    // Unsubscribe from events
    if let id = eventId {
        api.unsubscribeFromEvent(id)
    }
}
```

### Event System

#### Subscribe to Events

```swift
let subscriptionId = api.subscribeToEvent("event.name") { event in
    print("Event received: \\(event.name)")
    print("Data: \\(event.data)")
}
```

Available events:
- `chat.message.received` - New chat message
- `chat.message.sent` - Message sent by user
- `stream.started` - Stream went live
- `stream.ended` - Stream went offline
- `user.follow` - New follower
- `user.subscribe` - New subscriber
- `settings.changed` - Plugin settings updated

#### Emit Events

```swift
api.emitEvent(PluginEvent(
    name: "custom.event",
    data: ["key": "value"],
    source: "my-plugin"
))
```

#### Unsubscribe

```swift
api.unsubscribeFromEvent(subscriptionId)
```

### Storage API

#### Save Data

```swift
let data = try JSONEncoder().encode(myObject)
try api.saveData(key: "my_key", value: data)
```

#### Load Data

```swift
if let data = try api.loadData(key: "my_key") {
    let myObject = try JSONDecoder().decode(MyType.self, from: data)
}
```

#### Delete Data

```swift
try api.deleteData(key: "my_key")
```

#### List All Keys

```swift
let keys = try api.getAllKeys()
```

### Network API

#### HTTP Requests

```swift
let response = try await api.makeHTTPRequest(
    url: "https://api.example.com/data",
    method: .GET,
    headers: ["Authorization": "Bearer token"],
    body: nil
)

print("Status: \\(response.statusCode)")
print("Body: \\(String(data: response.body, encoding: .utf8) ?? "")")
```

Supported methods: `.GET`, `.POST`, `.PUT`, `.DELETE`, `.PATCH`

### Twitch API

#### Get Channel Info

```swift
let channel = try await api.getChannelInfo(channelName: "channelname")
print("Channel: \\(channel.displayName)")
```

#### Send Chat Message

```swift
try await api.sendChatMessage(
    channel: "channelname",
    message: "Hello from plugin!"
)
```

#### Get Stream Info

```swift
if let stream = try await api.getStreamInfo(channel: "channelname") {
    print("Live with \\(stream.viewerCount) viewers")
}
```

#### Get User Info

```swift
let user = try await api.getUserInfo(username: "username")
print("User ID: \\(user.id)")
```

### UI Integration

#### Add Menu Item

```swift
let menuId = api.registerMenuItem(title: "My Plugin Settings") {
    // Show settings UI
}
```

#### Show Notification

```swift
api.showNotification(
    title: "Plugin Notification",
    message: "Something happened!",
    type: .info  // .info, .warning, .error, .success
)
```

#### Add Custom View

```swift
let viewId = api.addCustomView(
    myCustomView,
    position: .sidebar  // .sidebar, .header, .footer, .chatPanel
)
```

#### Add Emote

```swift
try api.addEmote(
    name: "Kappa",
    imageURL: "https://cdn.example.com/kappa.png",
    provider: "MyEmoteProvider"
)
```

#### Add Chat Badge

```swift
try api.addChatBadge(
    name: "subscriber",
    imageURL: "https://cdn.example.com/badge.png"
)
```

### Chat Commands

#### Register Command

```swift
let commandId = api.registerChatCommand(command: "mycommand") { channel, args in
    print("Command executed in \\(channel)")
    print("Arguments: \\(args)")
}
```

Usage in chat: `/mycommand arg1 arg2`

#### Unregister Command

```swift
api.unregisterChatCommand(commandId)
```

### Settings

#### Register Settings Schema

```swift
let schema = SettingsSchema(
    pluginId: metadata.identifier,
    sections: [
        SettingsSection(
            title: "General",
            settings: [
                Setting(
                    key: "enabled",
                    title: "Enable Feature",
                    type: .boolean,
                    defaultValue: true
                ),
                Setting(
                    key: "api_key",
                    title: "API Key",
                    type: .string,
                    defaultValue: ""
                ),
                Setting(
                    key: "refresh_rate",
                    title: "Refresh Rate (seconds)",
                    type: .number,
                    defaultValue: 60
                )
            ]
        )
    ]
)

try api.registerSettings(schema: schema)
```

#### Get/Set Setting Values

```swift
// Get value
if let enabled = try api.getSettingValue(key: "enabled") as? Bool {
    print("Feature enabled: \\(enabled)")
}

// Set value
try api.setSettingValue(key: "enabled", value: false)
```

### Logging

```swift
api.log(level: .debug, message: "Debug message", metadata: nil)
api.log(level: .info, message: "Info message", metadata: nil)
api.log(level: .warning, message: "Warning", metadata: ["key": "value"])
api.log(level: .error, message: "Error occurred", metadata: ["error": errorDescription])
```

Log levels: `.debug`, `.info`, `.warning`, `.error`

### Inter-Plugin Communication

#### Send Message to Specific Plugin

```swift
try api.sendMessageToPlugin(
    pluginId: "com.example.otherplugin",
    message: PluginMessage(
        type: "request",
        payload: ["action": "getData"]
    )
)
```

#### Broadcast to All Plugins

```swift
api.broadcastMessage(PluginMessage(
    type: "notification",
    payload: ["event": "something_happened"]
))
```

## Permissions

Declare required permissions in plugin metadata:

```swift
requiredPermissions: [
    .network,           // Network requests
    .storage,           // Persistent storage
    .twitchAPI,         // Twitch API access
    .chatAccess,        // Read/write chat
    .uiModification,    // Modify UI
    .systemCommands     // Execute system commands
]
```

## Dependencies

Declare plugin dependencies:

```swift
dependencies: [
    PluginDependency(
        identifier: "com.example.dependency",
        version: "1.0.0",
        required: true
    )
]
```

## Plugin Distribution

### Directory Structure

```
MyPlugin/
├── manifest.json          # Plugin metadata
├── MyPlugin.swift        # Main plugin class
├── Resources/            # Images, assets
│   └── icon.png
└── README.md            # Plugin documentation
```

### manifest.json

```json
{
    "identifier": "com.example.myplugin",
    "name": "My Plugin",
    "version": "1.0.0",
    "author": "Your Name",
    "description": "Description of your plugin",
    "homepage": "https://github.com/yourusername/myplugin",
    "mainClass": "MyPlugin",
    "permissions": ["network", "storage"],
    "dependencies": []
}
```

### Installation

1. Build your plugin as a dynamic library (`.dylib`)
2. Place the compiled library and manifest in the plugins directory:
   ```
   ~/Library/Application Support/OyVey/Plugins/MyPlugin/
   ```
3. Restart OyVey or use hot-reload

## Hot Reload

The plugin manager supports hot-reload for development:

```swift
// In your host application
pluginManager.reloadPlugin(identifier: "com.example.myplugin")
```

## Best Practices

1. **Error Handling**: Always handle errors gracefully
```swift
do {
    try api.saveData(key: "data", value: data)
} catch {
    api.log(level: .error, message: "Save failed: \\(error)", metadata: nil)
}
```

2. **Resource Cleanup**: Unsubscribe from events in `deactivate()`

3. **Async Operations**: Use Swift concurrency for network requests
```swift
Task {
    let data = try await api.makeHTTPRequest(...)
}
```

4. **Memory Management**: Use `weak self` in closures
```swift
api.subscribeToEvent("event") { [weak self] event in
    self?.handleEvent(event)
}
```

5. **Logging**: Log important actions for debugging
```swift
api.log(level: .info, message: "Action performed", metadata: ["detail": "info"])
```

## Testing

Create a test harness:

```swift
class MockPluginAPI: PluginAPI {
    // Implement protocol methods for testing
}

let testAPI = MockPluginAPI()
let plugin = MyPlugin()
try plugin.initialize(with: testAPI)
try plugin.activate()
```

## Debugging

1. Check logs in Console.app for plugin output
2. Use breakpoints in your plugin code
3. Enable verbose logging:
```swift
api.log(level: .debug, message: "Debug info", metadata: debugData)
```

## Examples

See `SamplePlugin.swift` for a complete working example that:
- Loads emotes from BTTV and 7TV APIs
- Handles chat messages
- Registers chat commands
- Uses persistent storage
- Integrates with the UI

## Support

- GitHub: https://github.com/VonKleistL/OyVey
- Documentation: https://vonkleistl.github.io/oyvey-docs
- Discord: [Join Server]

## License

MIT License - See LICENSE file for details
