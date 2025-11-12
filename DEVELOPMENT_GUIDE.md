# OyVey Development Guide

## Complete Implementation Roadmap

This guide outlines the complete implementation of OyVey with ALL features from BetterTTV and 7TV.

---

## BetterTTV Features to Implement

### 1. Emote System
- ✅ Custom emote rendering in chat
- ✅ BetterTTV emote library integration
- ✅ Personal emotes
- ✅ Shared emotes
- ✅ Emote autocomplete
- ✅ Animated GIF emotes
- ✅ Emote menu/picker

### 2. Chat Enhancements
- ✅ Chat badges (custom badges)
- ✅ Username colors customization
- ✅ Highlight keywords
- ✅ Split chat (multiple channels)
- ✅ Pinned highlights
- ✅ Blacklist users/phrases
- ✅ Deleted message history
- ✅ Chat timestamps

### 3. UI Customizations
- ✅ Dark theme
- ✅ Theater mode
- ✅ Hide sidebar
- ✅ Hide chat
- ✅ Custom CSS injection
- ✅ Split chat mode

### 4. Moderation Tools
- ✅ Mod view enhancements
- ✅ Quick ban/timeout
- ✅ Auto-mod assistant
- ✅ Timeout duration presets

### 5. Quality of Life
- ✅ Anon chat mode
- ✅ Click-to-play GIFs
- ✅ Auto-expand videos
- ✅ Disable channel points  
- ✅ Show deleted messages

---

## 7TV Features to Implement

### 1. Advanced Emote System
- ✅ Zero-width emotes
- ✅ Emote overlays
- ✅ Personal emote sets
- ✅ Channel emote sets
- ✅ Global emote sets
- ✅ Animated WEBP emotes
- ✅ High-res emote support (2x, 4x)
- ✅ Emote aliases

### 2. Real-time Emote Updates
- ✅ Live emote additions
- ✅ Live emote removals
- ✅ EventSource/WebSocket integration
- ✅ No refresh required

### 3. Emote Modifier System
- ✅ Flip modifiers (flipX, flipY)
- ✅ Rotation modifiers
- ✅ Scale modifiers
- ✅ Stack multiple modifiers
- ✅ Width modifiers (wide, ultra-wide)

### 4. Paint System
- ✅ Animated username colors
- ✅ Gradient name colors
- ✅ Custom paint effects
- ✅ Badge painting

### 5. Badge System
- ✅ 7TV badges
- ✅ Custom badge support
- ✅ Badge tooltips
- ✅ Clickable badges

### 6. Cosmetics
- ✅ Profile cosmetics
- ✅ Custom avatars
- ✅ Animated profiles

### 7. Chat Features
- ✅ Inline emote search
- ✅ TAB completion
- ✅ Recent emotes
- ✅ Frequently used emotes
- ✅ Emote favorites
- ✅ Quick emote access (CTRL+E)

### 8. Performance
- ✅ Virtualized chat rendering
- ✅ Lazy emote loading
- ✅ Efficient re-renders
- ✅ Memory optimization

---

## Project File Structure

```
OyVey/
├── OyVeyApp/
│   ├── OyVeyApp.swift                    # App entry point
│   ├── ContentView.swift                  # Main view
│   ├── Views/
│   │   ├── StreamView.swift              # Video player view
│   │   ├── ChatView.swift                # Chat interface
│   │   ├── SidebarView.swift             # Channel sidebar
│   │   └── SettingsView.swift            # Settings panel
│   ├── ViewModels/
│   │   ├── StreamViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   └── PluginViewModel.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
│
├── OyVeyCore/
│   ├── Twitch/
│   │   ├── TwitchAPI.swift               # API client
│   │   ├── TwitchAuth.swift              # OAuth handler
│   │   ├── TwitchWebSocket.swift         # Chat websocket
│   │   └── Models/
│   │       ├── Channel.swift
│   │       ├── Stream.swift
│   │       └── User.swift
│   ├── Chat/
│   │   ├── ChatEngine.swift              # Chat message processing
│   │   ├── EmoteParser.swift             # Emote detection/parsing
│   │   ├── MessageRenderer.swift         # Message rendering
│   │   └── BadgeManager.swift            # Badge system
│   └── Streaming/
│       ├── VideoPlayer.swift             # AVPlayer wrapper
│       └── QualityManager.swift          # Adaptive quality
│
├── PluginFramework/
│   ├── PluginProtocol.swift              # ✅ Already created
│   ├── PluginManager.swift               # Plugin loader
│   ├── PluginAPIImplementation.swift     # API implementation
│   ├── PluginStorage.swift               # Persistent storage
│   ├── PluginSandbox.swift               # Security sandbox
│   └── PluginDiscovery.swift             # Auto-discovery
│
├── LiquidGlassUI/
│   ├── Materials/
│   │   ├── GlassMaterial.swift           # Base glass effect
│   │   ├── BlurEffect.swift              # Dynamic blur
│   │   └── TranslucentBackground.swift   # Translucent views
│   ├── Components/
│   │   ├── GlassButton.swift
│   │   ├── GlassCard.swift
│   │   ├── GlassToolbar.swift
│   │   ├── GlassSheet.swift
│   │   ├── GlassTab.swift
│   │   └── GlassTextField.swift
│   └── Animations/
│       ├── FluidAnimation.swift
│       ├── SpringPhysics.swift
│       └── GestureAnimations.swift
│
└── Plugins/
    ├── BetterTTV/
    │   ├── BetterTTVPlugin.swift         # Main plugin
    │   ├── BTTVEmoteProvider.swift       # Emote API
    │   ├── BTTVChatModifier.swift        # Chat enhancements
    │   ├── BTTVSettings.swift            # Settings UI
    │   └── Features/
    │       ├── EmoteMenu.swift
    │       ├── ChatHighlights.swift
    │       ├── CustomBadges.swift
    │       └── ModTools.swift
    │
    ├── SevenTV/
    │   ├── SevenTVPlugin.swift           # Main plugin
    │   ├── SevenTVAPI.swift              # 7TV API client
    │   ├── EmoteSetManager.swift         # Emote set handling
    │   ├── PaintSystem.swift             # Paint/cosmetics
    │   ├── SevenTVWebSocket.swift        # Real-time updates
    │   └── Features/
    │       ├── ZeroWidthEmotes.swift
    │       ├── EmoteModifiers.swift
    │       ├── AnimatedPaints.swift
    │       ├── EmoteSearch.swift
    │       └── VirtualizedChat.swift
    │
    └── CoreExtensions/
        ├── ThemeEngine.swift             # Custom themes
        ├── ChatLogger.swift              # Message logging
        └── StreamOverlay.swift           # On-stream overlay
```

---

## API Integrations Required

### BetterTTV API
```
Base URL: https://api.betterttv.net/3/

Endpoints:
- GET /cached/emotes/global
- GET /cached/users/twitch/:userId
- GET /cached/frankerfacez/emotes/global
- GET /cached/frankerfacez/users/twitch/:userId
```

### 7TV API
```
Base URL: https://7tv.io/v3/

Endpoints:
- GET /emote-sets/:setId
- GET /users/twitch/:userId
- GET /emotes/global
- GET /cosmetics
- GET /paints
- WebSocket: wss://events.7tv.io/v3
```

### Twitch API
```
Base URL: https://api.twitch.tv/helix/

Required:
- OAuth 2.0 authentication
- IRC/WebSocket for chat
- Video player integration
```

---

## Development Phases

### Phase 1: Core Foundation ✅
- [x] Repository setup
- [x] Plugin framework
- [x] Basic architecture

### Phase 2: Plugin System (In Progress)
- [ ] PluginManager implementation
- [ ] Plugin loading/unloading
- [ ] Hot-reload support
- [ ] Sandbox security

### Phase 3: UI Framework
- [ ] Liquid Glass components
- [ ] Material system
- [ ] Animation framework

### Phase 4: Twitch Integration
- [ ] OAuth authentication
- [ ] Stream playback
- [ ] Chat connection
- [ ] API client

### Phase 5: BetterTTV Plugin
- [ ] Emote provider
- [ ] Chat modifications
- [ ] UI customizations
- [ ] Moderation tools

### Phase 6: 7TV Plugin
- [ ] Advanced emote system
- [ ] Real-time updates
- [ ] Paint system
- [ ] Cosmetics

### Phase 7: Polish & Optimization
- [ ] Performance tuning
- [ ] Memory optimization
- [ ] Error handling
- [ ] User testing

---

## Next Files to Create

1. **PluginFramework/PluginManager.swift** - Core plugin loader
2. **LiquidGlassUI/Materials/GlassMaterial.swift** - Base glass effect
3. **OyVeyCore/Twitch/TwitchAPI.swift** - Twitch integration
4. **Plugins/BetterTTV/BetterTTVPlugin.swift** - BetterTTV main
5. **Plugins/SevenTV/SevenTVPlugin.swift** - 7TV main

---

## Building the App

```bash
# Open in Xcode
open OyVey.xcodeproj

# Or use command line
xcodebuild -scheme OyVey -configuration Debug

# Run
open build/Debug/OyVey.app
```

---

## Contributing

See CONTRIBUTING.md for plugin development guidelines.

## License

MIT License - See LICENSE file
