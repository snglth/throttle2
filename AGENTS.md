# Repository Guidelines

## Project Structure & Module Organization

- `Throttle 2/`: primary SwiftUI app source (notably `SSH/`, `Torrent/`, `Server/`, `Views/`, `Settings/`, `Helpers/`, `Assets.xcassets/`, and the Core Data model in `CoreData.xcdatamodeld/`).
- `Throttle 2.xcodeproj/`: Xcode project. `Throttle 2.xcworkspace/`: workspace that includes CocoaPods and should be preferred for day-to-day development.
- `Resources/`: bundled helpers/binaries and scripts (e.g., `transmission-daemon`, `transmission-remote`, launchd `.plist` files, and `install-ffmpeg-static.sh`).
- `Pods/`: CocoaPods checkout (ignored by git; recreated locally via `pod install`).
- Root scripts/docs: `bundle-transmission.sh`, `build-static-transmission.sh`, `enable-hardened-runtime.sh`, and design notes like `SSH_Safety_Analysis.md` and `LOCAL_SERVER_IMPLEMENTATION_PLAN.md`.

## Build, Test, and Development Commands

- `pod install`: installs iOS pod dependency (`MobileVLCKit`) and generates/updates `Throttle 2.xcworkspace`.
- `open "Throttle 2.xcworkspace"`: open in Xcode with Pods + Swift Package dependencies resolved.
- `xcodebuild -list -project "Throttle 2.xcodeproj"`: discover available schemes on your machine.
- `xcodebuild -workspace "Throttle 2.xcworkspace" -scheme "<Scheme>" -configuration Debug build`: command-line build.

Tip: several paths in this repo contain spaces; quote them in shell commands.

Note: `bundle-transmission.sh`, `build-static-transmission.sh`, and `enable-hardened-runtime.sh` are release helpers with hard-coded paths and signing identities—edit before running.

## Coding Style & Naming Conventions

- Swift formatting: follow existing files (2-space indentation is common here). Use `UpperCamelCase` for types/files and `lowerCamelCase` for functions/variables.
- Prefer scoped changes and keep platform conditionals (`#if os(iOS)` / `#if os(macOS)`) explicit.
- SSH safety: avoid long-lived/reused connections; prefer `SSHConnection.withConnection(...)` and related helpers (see `Throttle 2/SSH/SSHConnection.swift` and `SSH_Safety_Analysis.md`).

## Testing Guidelines

- Xcode targets include `Throttle 2Tests` and `Throttle 2UITests`. Add new tests under folders like `Throttle 2Tests/` and name files `SomethingTests.swift`.
- Run tests in Xcode (`⌘U`) or via CLI: `xcodebuild test -scheme "<Scheme>" -destination "<Destination>"`.

## Commit & Pull Request Guidelines

- History favors short, summary-first subjects; an occasional `Fix:` prefix is used when helpful. Keep messages descriptive and scoped (e.g., “Fix: thumbnail queue crash”).
- PRs: include a clear description, reproduction steps, and screenshots/screen recordings for UI changes. Call out platforms tested (iOS + macOS) and whether a remote SSH server path was exercised.

## Security & Configuration Tips

- Never commit secrets (private keys, passwords, real hostnames). Prefer Keychain-backed storage and scrub logs before sharing.
