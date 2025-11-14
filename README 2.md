# OyVey - Native macOS Twitch Client

> A beautiful, modern, and extensible Twitch client for macOS built with SwiftUI and Liquid Glass design.

## ✨ Features

### 🎨 Liquid Glass UI
- Stunning modern interface using Apple's Liquid Glass design language
- Fluid animations and responsive interactions
- Translucent materials with dynamic blur effects
- Adaptive UI that responds to system appearance

### 🔌 Plugin System
- Powerful plugin architecture (similar to Vencord/BetterDiscord)
- Hot-reload support for plugin development
- Sandboxed plugin execution for security
- Plugin API for extending functionality
- Community plugin marketplace

### 📺 Twitch Integration
- Native Twitch API integration
- Live stream viewing with adaptive quality
- Chat with custom emotes and badges
- Channel points and predictions
- Multi-stream support

- ### 🎙️ Real-Time Voice Transcription

- Live audio transcription using iLiveData RTVT API
- Support for 20+ languages with automatic language detection
- Real-time translation to target language
- Microphone audio capture (16kHz, 16-bit PCM)
- Low-latency transcription overlay
- WebSocket-based streaming communication
- Built-in error handling and reconnection

### 🛠 Modding Capabilities
- Custom themes and styles
- UI element customization
- Chat modification system
- Event hooks and interceptors
- JavaScript/Swift plugin support

## 🏗 Architecture

```
OyVey/
├── OyVeyApp/                 # Main macOS application
│   ├── App/                  # App lifecycle and entry point
│   ├── Views/                # SwiftUI views with Liquid Glass
│   ├── ViewModels/           # MVVM architecture
│   └── Resources/            # Assets and configurations
├── OyVeyCore/               # Core business logic
│   ├── Twitch/              # Twitch API client
│   ├── Chat/                # Chat engine
│   └── Streaming/           # Video player integration
├── PluginFramework/         # Plugin system framework
│   ├── PluginProtocol.swift # Plugin interface
│   ├── PluginManager.swift  # Plugin lifecycle management
│   └── PluginAPI.swift      # API exposed to plugins
├── LiquidGlassUI/          # Reusable Liquid Glass components
│   ├── Materials/           # Glass effects and materials
│   ├── Components/          # Custom UI components
│   └── Animations/          # Fluid animation utilities
└── Plugins/                 # Sample plugins
    ├── ThemeEngine/         # Theme customization plugin
    ├── ChatEnhancer/        # Chat enhancement plugin
    └── StreamOverlay/       # Stream overlay plugin
```

## 🚀 Getting Started

### Prerequisites
- macOS 14.0+ (Sonoma or later)
- Xcode 16.0+
- Swift 6.0+
- Apple Silicon Mac (recommended for best performance)

### Building

```bash
# Clone the repository
git clone https://github.com/VonKleistL/OyVey.git
cd OyVey

# Open in Xcode
open OyVey.xcodeproj

# Build and run (⌘+R)
```

### Enabling Transcription

To use the real-time transcription feature:

1. **Microphone Permissions**: Add the following to your `Info.plist` (or in Xcode project settings):
```xml
<key>NSMicrophoneUsageDescription</key>
<string>OyVey needs microphone access for real-time voice transcription</string>
```

2. **Using the Feature**:
   - Launch OyVey and open a Twitch stream
   - Click the "Transcription" button at the bottom of the window
   - Click "Start" to begin transcription
   - The app will request microphone permission on first use
   - Transcribed text will appear in the overlay panel

3. **Configuration**:
   - Source language: Auto-detected by default (configurable in RTVTManager)
   - Target language: English by default (configurable in RTVTManager)
   - Audio format: 16kHz, 16-bit PCM (automatic)

## 🔌 Plugin Development

Create custom plugins to extend OyVey's functionality:

```swift
import PluginFramework

class MyPlugin: OyVeyPlugin {
    var metadata = PluginMetadata(
        name: "My Awesome Plugin",
        version: "1.0.0",
        author: "Your Name"
    )
    
    func onLoad(api: PluginAPI) {
        // Initialize your plugin
        api.registerChatCommand("/mycommand") { args in
            // Handle command
        }
    }
}
```

## 📦 Plugin API

The Plugin API provides hooks into:
- Chat events and messages
- UI customization
- Stream metadata
- User interactions
- Network requests

## 🎨 Liquid Glass Components

Built-in Liquid Glass components for consistent UI:
- `GlassButton` - Interactive buttons with glass effect
- `GlassCard` - Container with translucent background
- `GlassToolbar` - Floating toolbar with blur
- `GlassSheet` - Modal sheets with glass material
- `FluidAnimation` - Smooth, physics-based animations

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines.

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Inspired by Vencord and BetterDiscord plugin systems
- Built with Apple's Liquid Glass design principles
- Powered by Twitch API

## 🔗 Links

- [Documentation](https://github.com/VonKleistL/OyVey/wiki)
- [Plugin Marketplace](https://github.com/VonKleistL/OyVey/discussions)
- [Report Issues](https://github.com/VonKleistL/OyVey/issues)

---

**Note**: This is an unofficial third-party Twitch client and is not affiliated with Twitch Interactive, Inc.
