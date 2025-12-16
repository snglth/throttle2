# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Throttle 2 is a SwiftUI iOS/macOS application for managing Transmission torrent downloads and remote file systems. It connects to remote servers via SSH to control Transmission RPC and provides SFTP-based file browsing with server-side thumbnail generation.

## Build Commands

```bash
# Build via Xcode
xcodebuild -workspace "Throttle 2.xcworkspace" -scheme "Throttle 2" -configuration Debug build

# Install dependencies (iOS uses CocoaPods for MobileVLCKit)
pod install
```

The Xcode workspace (`Throttle 2.xcworkspace`) should be used for development as it includes CocoaPods dependencies.

## Architecture

### Core Components

**App Entry & State Management**
- `Throttle_2App.swift` - Main app entry, handles platform-specific window setup, scene lifecycle, and network monitoring
- `store.swift` - Contains `Store`, `Presenting`, and `TorrentFilters` ObservableObjects for app-wide state
- `DataManager.swift` - Core Data singleton with optional CloudKit sync support

**SSH/SFTP Layer** (`SSH/`)
- `SSHConnection.swift` - Core SSH client wrapping Citadel library. Use `SSHConnection.withConnection()` for automatic cleanup
- `SSHTunnel.swift` - Manages port forwarding for Transmission RPC tunneling
- `GlobalConnectionSemaphore.swift` - Rate limits concurrent SSH connections
- `SSHKeyManager.swift` - Handles SSH key authentication with macOS keychain integration

**Transmission Integration** (`Torrent/`)
- `TorrentManager.swift` - RPC client for Transmission daemon, handles torrent listing/operations
- Uses dynamic field parsing via `AnyCodable` for flexible Transmission RPC response handling
- `LocalTransmissionManager.swift` (macOS only) - Manages bundled transmission-daemon for local operation

**File Browser** (`SSH/Browser/`)
- `SFTPBrowser.swift` - SwiftUI file browser view
- `SFTPConnectionManager.swift` - Manages SFTP connection pooling
- `ViewModel.swift` - File browser view model with upload/download operations

**Thumbnails** (`SSH/Thumbnails/`)
- `ThumbnailManagerRemote.swift` - Generates thumbnails via FFmpeg on remote server over SSH
- `ThumbnailManagerLocal.swift` - Local thumbnail generation
- `RemoteFFmpegInstaller.swift` - Installs FFmpeg on remote servers if needed

**Media Playback** (`SSH/Playback/`)
- `VLCVideoPlayer.swift` / `AVVideoPlayer.swift` - Video playback options
- `FTPServer.swift` - Local FTP proxy for streaming SFTP files to video players on iOS

**macOS Mounting** (`SSH/Mounting/`)
- `MountManager.swift` - SSHFS/FUSE-T integration for mounting remote drives

### Key Patterns

1. **SSH Connection Safety**: Always use `SSHConnection.withConnection()` to ensure connections are properly closed:
   ```swift
   try await SSHConnection.withConnection(server: server) { connection in
       // use connection
   }
   ```

2. **Server Selection**: The selected server is stored in `Store.selection` and persisted via `@AppStorage("selectedServerId")`

3. **Platform Conditionals**: Uses `#if os(macOS)` / `#if os(iOS)` extensively for platform-specific features

4. **Singleton Managers**: Several managers use shared singletons:
   - `DataManager.shared`
   - `ServerMountManager.shared`
   - `ThumbnailManagerRemote.shared`
   - `SSHConnectionManager.shared`
   - `TunnelManagerHolder.shared`

### Data Model

Core Data entity `ServerEntity` stores server configurations including:
- SSH/SFTP credentials and host info
- Transmission RPC settings
- Local daemon settings (for macOS bundled Transmission)
- Mount preferences

Keychain storage via KeychainAccess library for passwords/passphrases.

### Dependencies

- **Citadel** - Swift SSH/SFTP client (NIO-based)
- **KeychainAccess** - Keychain wrapper
- **SimpleToast** - Toast notifications
- **MobileVLCKit** (iOS only via CocoaPods) - VLC video playback

### Platform-Specific Notes

**macOS**:
- Bundles `transmission-daemon` and `transmission-remote` binaries
- Uses SSHFS/FUSE-T for native Finder integration
- Bundles QLVideo for video thumbnails

**iOS**:
- Creates local FTP proxy (`SimpleFTPServer`) for video streaming when using SSH key auth
- Supports external display mirroring via `ExternalDisplayManager`
