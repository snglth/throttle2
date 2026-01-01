# Transmission RPC Package Extraction - Implementation Plan

## Executive Summary

This plan details the extraction of all Transmission RPC functionality from the Throttle 2 app into a standalone, reusable Swift package. The TransmissionRPC package skeleton already exists with basic JSON-RPC infrastructure. This refactoring will move all Transmission-specific logic into the package while maintaining clean separation from the app's SSH/tunnel infrastructure.

## Current State Analysis

### Existing TransmissionRPC Package Structure

**Location:** `/home/user/throttle2/TransmissionRPC/`

**Current Contents:**
- `TransmissionRPCClient.swift` - Actor-based JSON-RPC 2.0 client
  - Handles CSRF protection (409 retry with X-Transmission-Session-Id)
  - Basic authentication support
  - Generic `call()` method for any RPC method
  - Session management
- `JSONValue.swift` - Dynamic JSON type (enum-based)
- `JSONRPCModels.swift` - JSON-RPC request/response structs

**Key Features Already Implemented:**
- ✅ JSON-RPC 2.0 protocol compliance
- ✅ CSRF token handling (409 responses)
- ✅ Basic auth headers
- ✅ Actor isolation for thread safety
- ✅ Generic result decoding

**Missing:**
- ❌ No Transmission-specific types (Torrent, TorrentFile, etc.)
- ❌ No high-level Transmission methods (getTorrents, addTorrent, etc.)
- ❌ No field constants or type-safe API
- ❌ Package not imported or used by app

### Current App Implementation

**Location:** `/home/user/throttle2/Throttle 2/Torrent/`

**Files:**
1. `TorrentManager.swift` (849 lines)
   - Contains Torrent model with dynamic fields (AnyCodable)
   - TorrentManager @MainActor class (ObservableObject)
   - Direct URLSession calls with manual session ID handling
   - Methods: fetchUpdates, addTorrent, fetchTorrentDetails, getSession, etc.
   - File caching logic
   - Periodic update timer management

2. `TorrentOperations.swift` (397 lines)
   - Extensions on TorrentManager
   - Operations: delete, move, rename, start, stop, verify, reannounce
   - Each operation has its own request/response structs

3. `TorrentFiles.swift` (78 lines)
   - File selection operations (setTorrentFiles)
   - TorrentSetRequest struct

4. `TorrentLabels.swift` (131 lines)
   - Label management (toggleStar, getLabels)
   - UI components for label display

**Key Observations:**
- ❌ Tight coupling to URLSession and app infrastructure
- ❌ Duplicate JSON-RPC implementation vs. the package
- ❌ Mixed concerns (RPC logic + UI state + caching)
- ❌ AnyCodable duplicates JSONValue functionality
- ❌ No separation between RPC client and application logic
- ✅ Comprehensive coverage of Transmission RPC spec
- ✅ Well-tested in production

### Integration Points

**SSH Tunnel Integration:**
- `ServerInit.swift`: setupServer() builds RPC URL from tunnel or direct connection
- `SSHTunnelManager`: Creates local port forwarding
- TorrentManager.baseURL is set to `http://127.0.0.1:4000/transmission/rpc` (tunnel) or direct URL

**App-Wide Usage:**
- 21 files import/use TorrentManager
- ObservableObject pattern for SwiftUI integration
- Used in views: TorrentListView, ContentView, TorrentDetailsView, etc.

---

## Proposed Package Structure

### Public API Design

The package should provide three layers:

#### Layer 1: Low-Level RPC Client (Already Exists)
```swift
// Already implemented in TransmissionRPCClient
public actor TransmissionRPCClient {
    public func call<Result: Decodable, Params: Encodable>(
        method: String,
        params: Params?
    ) async throws -> Result
}
```

#### Layer 2: Type-Safe Transmission API (NEW)
```swift
public actor TransmissionSession {
    // High-level type-safe methods
    public func getTorrents(fields: [TorrentField], ids: [TorrentID]?) async throws -> [Torrent]
    public func addTorrent(request: AddTorrentRequest) async throws -> AddTorrentResult
    public func setTorrent(ids: [TorrentID], changes: TorrentChanges) async throws
    public func removeTorrents(ids: [TorrentID], deleteLocalData: Bool) async throws
    public func startTorrents(ids: [TorrentID]) async throws
    public func stopTorrents(ids: [TorrentID]) async throws
    // ... all other RPC methods

    public func getSessionInfo() async throws -> SessionInfo
    public func setSessionSettings(_ settings: SessionSettings) async throws
}
```

#### Layer 3: Domain Models (NEW)
```swift
// Core types
public struct Torrent: Codable, Identifiable, Sendable
public struct TorrentFile: Codable, Identifiable, Sendable
public struct TorrentStats: Codable, Sendable
public struct SessionInfo: Codable, Sendable

// Enums for type safety
public enum TorrentField: String, Codable, CaseIterable
public enum TorrentStatus: Int, Codable
public enum TorrentID: Codable { case id(Int); case hash(String) }

// Request/response types
public struct AddTorrentRequest: Codable
public struct AddTorrentResult: Codable
public struct TorrentChanges: Codable
```

### Directory Structure

```
TransmissionRPC/
├── Package.swift
├── Sources/
│   └── TransmissionRPC/
│       ├── Client/
│       │   ├── TransmissionRPCClient.swift (existing)
│       │   ├── JSONRPCModels.swift (existing)
│       │   └── JSONValue.swift (existing)
│       ├── Session/
│       │   └── TransmissionSession.swift (NEW)
│       ├── Models/
│       │   ├── Torrent.swift (NEW - from app)
│       │   ├── TorrentFile.swift (NEW - from app)
│       │   ├── TorrentField.swift (NEW)
│       │   ├── TorrentStatus.swift (NEW)
│       │   ├── SessionInfo.swift (NEW - from app)
│       │   └── TrackerStats.swift (NEW)
│       ├── Requests/
│       │   ├── AddTorrentRequest.swift (NEW)
│       │   ├── TorrentChanges.swift (NEW)
│       │   └── SessionSettings.swift (NEW)
│       └── Responses/
│           ├── AddTorrentResult.swift (NEW)
│           └── TorrentResponse.swift (NEW)
└── Tests/
    └── TransmissionRPCTests/
        ├── TransmissionRPCClientFunctionalTests.swift (existing)
        ├── TransmissionSessionTests.swift (NEW)
        └── ModelTests.swift (NEW)
```

---

## Detailed Implementation Plan

### Phase 1: Package Foundation (Models & Types)

**Goal:** Move all Transmission-specific data models into the package

**Tasks:**

1. **Consolidate Dynamic JSON Types**
   - Evaluate JSONValue vs AnyCodable
   - Decision: Use JSONValue (already in package, more type-safe enum)
   - Create migration helper if needed

2. **Create TorrentField enum**
   ```swift
   public enum TorrentField: String, Codable, CaseIterable {
       case id, name, hashString
       case percentDone, percentComplete
       case status, error, errorString
       case totalSize, downloadedEver, uploadedEver
       case files, fileStats, wanted
       case addedDate, activityDate
       case labels, downloadDir
       // ... all 50+ Transmission fields
   }
   ```

3. **Migrate Torrent model**
   - Move from `TorrentManager.swift` to `TransmissionRPC/Sources/TransmissionRPC/Models/Torrent.swift`
   - Replace `AnyCodable` with `JSONValue`
   - Make it `Sendable` for actor isolation
   - Keep dynamic field access pattern: `var dynamicFields: [String: JSONValue]`
   - Add computed properties for common fields

4. **Create supporting models**
   - `TorrentFile` - already exists in app, make Sendable
   - `TorrentStatus` - enum for status codes (0-6)
   - `SessionInfo` - extract from SessionResponse in app
   - `TrackerStats` - currently untyped dictionary

5. **Create request/response types**
   - Consolidate all the inline structs from operations
   - Make them public and well-documented

**Files to Create:**
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Models/Torrent.swift`
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Models/TorrentFile.swift`
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Models/TorrentField.swift`
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Models/TorrentStatus.swift`
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Models/SessionInfo.swift`
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Requests/AddTorrentRequest.swift`
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Requests/TorrentChanges.swift`
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Responses/AddTorrentResult.swift`

### Phase 2: High-Level Session API

**Goal:** Create TransmissionSession actor with all RPC methods

**Tasks:**

1. **Create TransmissionSession actor**
   ```swift
   public actor TransmissionSession {
       private let client: TransmissionRPCClient

       public init(configuration: TransmissionRPCClientConfiguration,
                   urlSession: URLSession = .shared) {
           self.client = TransmissionRPCClient(configuration: configuration,
                                              urlSession: urlSession)
       }
   }
   ```

2. **Implement torrent accessor methods**
   - `getTorrents(fields:ids:)` - maps to `torrent-get`
   - `getTorrentDetails(id:)` - convenience for full torrent info
   - `getTorrentFiles(id:)` - specialized for file info

3. **Implement torrent mutator methods**
   - `addTorrent(request:)` - maps to `torrent-add`
   - `setTorrent(ids:changes:)` - maps to `torrent-set`
   - `removeTorrents(ids:deleteLocalData:)` - maps to `torrent-remove`
   - `renamePath(id:path:newName:)` - maps to `torrent-rename-path`
   - `setLocation(ids:location:move:)` - maps to `torrent-set-location`

4. **Implement torrent action methods**
   - `startTorrents(ids:)` - maps to `torrent-start`
   - `stopTorrents(ids:)` - maps to `torrent-stop`
   - `verifyTorrents(ids:)` - maps to `torrent-verify`
   - `reannounceTorrents(ids:)` - maps to `torrent-reannounce`

5. **Implement session methods**
   - `getSessionInfo()` - maps to `session-get`
   - `setSessionSettings(_:)` - maps to `session-set`
   - `getSessionStats()` - maps to `session-stats`

**Files to Create:**
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Session/TransmissionSession.swift`
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Session/TransmissionSession+Torrents.swift`
- `/home/user/throttle2/TransmissionRPC/Sources/TransmissionRPC/Session/TransmissionSession+Session.swift`

### Phase 3: App Integration Layer

**Goal:** Refactor TorrentManager to use the package while maintaining UI compatibility

**Tasks:**

1. **Update Package.swift in main app**
   - Add local package dependency to TransmissionRPC

2. **Create new TorrentManager (Coordinator Pattern)**
   ```swift
   @MainActor
   class TorrentManager: ObservableObject {
       @Published var torrents: [Torrent] = []
       @Published var isLoading = false

       private var session: TransmissionSession?
       private var fileCache: [String: [TorrentFile]] = [:]
       private var fetchTimer: Timer?

       // Public API unchanged for UI compatibility
       func updateBaseURL(_ url: URL) { ... }
       func fetchUpdates() async throws { ... }
       func addTorrent(...) async throws { ... }
       // etc.

       // Internal: delegate to session
       private func ensureSession() throws -> TransmissionSession {
           guard let session = session else {
               throw TorrentManagerError.notConnected
           }
           return session
       }
   }
   ```

3. **Migrate methods to use TransmissionSession**
   - Replace direct URLSession calls with session method calls
   - Remove manual session ID handling (package handles it)
   - Keep caching and UI state logic in TorrentManager
   - Remove duplicate request/response structs

4. **Update imports throughout app**
   - Add `import TransmissionRPC` where needed
   - Update type references (Torrent is now from package)

**Files to Modify:**
- `/home/user/throttle2/Throttle 2/Torrent/TorrentManager.swift`
- `/home/user/throttle2/Throttle 2/Torrent/TorrentOperations.swift`
- `/home/user/throttle2/Throttle 2/Torrent/TorrentFiles.swift`
- `/home/user/throttle2/Throttle 2/Torrent/TorrentLabels.swift`

### Phase 4: Testing & Validation

**Goal:** Ensure functionality is preserved and add package tests

**Tasks:**

1. **Add package unit tests**
   - Test TransmissionSession methods with mocked responses
   - Test model encoding/decoding
   - Test field enum completeness

2. **Add integration tests**
   - Test against real Transmission daemon
   - Verify all RPC methods work correctly

3. **Manual testing in app**
   - Test all torrent operations (add, remove, start, stop, etc.)
   - Test with SSH tunnel configuration
   - Test with direct connection
   - Test with local daemon (macOS)
   - Test error handling

4. **Performance validation**
   - Ensure no regressions in update frequency
   - Verify memory usage is similar
   - Check actor isolation doesn't cause UI lag

**Files to Create:**
- `/home/user/throttle2/TransmissionRPC/Tests/TransmissionRPCTests/TransmissionSessionTests.swift`
- `/home/user/throttle2/TransmissionRPC/Tests/TransmissionRPCTests/TorrentModelTests.swift`
- `/home/user/throttle2/TransmissionRPC/Tests/TransmissionRPCTests/IntegrationTests.swift`

### Phase 5: Cleanup & Documentation

**Goal:** Remove redundant code and document the new architecture

**Tasks:**

1. **Remove old code**
   - Delete AnyCodable from app
   - Remove inline request/response structs
   - Clean up TorrentManager (should be much smaller)

2. **Documentation**
   - Add package README with usage examples
   - Document all public APIs with Swift DocC comments
   - Update CLAUDE.md with new architecture

3. **Consider future improvements**
   - Async sequences for torrent updates?
   - Combine publishers?
   - Better error types?

---

## Migration Strategy

### Approach: Incremental Migration

Instead of a "big bang" replacement, migrate incrementally:

**Step 1: Parallel Implementation**
- Build complete package API alongside existing code
- Don't modify app yet
- Ensure package tests pass

**Step 2: Gradual Replacement**
- Start with simple operations (getTorrents)
- Move to mutations (addTorrent, removeTorrents)
- Finally complex operations (rename, move)
- Each step: test thoroughly before proceeding

**Step 3: Cleanup**
- Once all operations migrated, remove old code
- Refactor TorrentManager to final form

### Backwards Compatibility

**For the App:**
- ✅ TorrentManager public API remains unchanged
- ✅ UI code doesn't need to change
- ✅ Torrent model is compatible (just imported from package)

**For the Package:**
- ✅ No breaking changes (it's new public API)
- ✅ Semantic versioning from 1.0.0

---

## Architectural Decisions

### Decision 1: Actor vs. Class for TransmissionSession

**Choice:** Actor

**Rationale:**
- Thread-safe by default
- Natural async/await integration
- Matches TransmissionRPCClient pattern
- No need for manual locking

**Trade-off:**
- Can't be @Published or ObservableObject
- Solution: TorrentManager stays as @MainActor class wrapper

### Decision 2: Dynamic Fields vs. Full Type Safety

**Choice:** Keep dynamic fields with JSONValue

**Rationale:**
- Transmission RPC returns different fields based on request
- Not all fields always present
- Future-proof against new Transmission versions
- Matches current app behavior

**Enhancement:**
- Provide TorrentField enum for compile-time field names
- Add typed accessors for common fields

### Decision 3: Package Dependencies

**Choice:** Zero dependencies

**Rationale:**
- Foundation is sufficient
- No need for third-party JSON libraries
- Easier to integrate into any project

**Current State:**
- ✅ Already zero dependencies

### Decision 4: Error Handling Strategy

**Choice:** Structured errors with context

```swift
public enum TransmissionError: Error {
    case rpcError(JSONRPCError)
    case networkError(Error)
    case invalidResponse(String)
    case torrentNotFound(TorrentID)
}
```

**Rationale:**
- Clear error types for callers
- Preserves RPC error details
- Easy to handle in UI layer

---

## Open Questions & Decisions Needed

### 1. Should the package handle polling/updates?

**Option A:** Package only provides one-shot calls
- App manages Timer and polling
- Simple package API
- App has full control over update frequency

**Option B:** Package provides async sequence of updates
```swift
for await torrents in session.torrentUpdates(interval: 5.0) {
    // handle updates
}
```
- More sophisticated
- Package handles timing
- Better encapsulation

**Recommendation:** Start with Option A, add Option B later if needed

### 2. How to handle file caching?

**Option A:** Keep cache in app's TorrentManager
- Simple
- App controls caching strategy
- Current behavior

**Option B:** Move cache into package
- Package could optimize requests
- More opaque to app
- Harder to debug

**Recommendation:** Option A - caching is app concern

### 3. Should session-level settings be part of the API?

The package should support `session-get` and `session-set`, but should it also cache session info?

**Recommendation:** Provide methods but no caching - let app decide

### 4. LocalTransmissionManager integration?

LocalTransmissionManager spawns transmission-daemon process. Should it use the package?

**Recommendation:** Yes - it should use TransmissionSession for RPC calls, just with a localhost URL

### 5. macOS vs iOS considerations?

Both platforms use same Transmission RPC protocol, but macOS has local daemon.

**Recommendation:** Package is platform-agnostic. App handles platform-specific connection setup.

---

## Risk Analysis

### High Risk

**Risk:** Breaking existing app functionality
- **Mitigation:** Incremental migration, thorough testing at each step
- **Mitigation:** Keep old code until new code proven

**Risk:** Actor isolation causes UI performance issues
- **Mitigation:** TorrentManager stays on @MainActor
- **Mitigation:** Batch updates, avoid per-torrent actor calls

### Medium Risk

**Risk:** Package API doesn't cover all use cases
- **Mitigation:** Start by migrating all existing operations
- **Mitigation:** Keep low-level client accessible as escape hatch

**Risk:** SSH tunnel integration breaks
- **Mitigation:** URL handling is app responsibility
- **Mitigation:** Test with both tunnel and direct connection

### Low Risk

**Risk:** Performance regression
- **Mitigation:** Package uses same underlying URLSession
- **Mitigation:** Benchmark before/after

---

## Success Criteria

### Must Have
- ✅ All current torrent operations work via package
- ✅ SSH tunnel integration unchanged
- ✅ No regressions in functionality
- ✅ Package builds and tests pass
- ✅ App compiles and runs with package

### Should Have
- ✅ TorrentManager code reduced by 50%+
- ✅ Package has 80%+ test coverage
- ✅ Documentation complete
- ✅ Type-safe API for common operations

### Nice to Have
- ✅ Package published to Swift Package Index
- ✅ Example app using package
- ✅ Performance improvements

---

## Timeline Estimate

**Phase 1 (Models & Types):** 2-3 days
- Create models, enums, request/response types
- Write model tests

**Phase 2 (Session API):** 3-4 days
- Implement TransmissionSession
- Write session tests
- Cover all RPC methods

**Phase 3 (App Integration):** 3-4 days
- Refactor TorrentManager
- Update all usages
- Test each operation

**Phase 4 (Testing):** 2-3 days
- Integration testing
- Manual testing
- Bug fixes

**Phase 5 (Cleanup):** 1-2 days
- Remove old code
- Documentation
- Final review

**Total: 11-16 days** (aggressive timeline assumes full-time work)

---

## Post-Refactoring Benefits

### Code Quality
- Clear separation of concerns
- Reusable package for other Transmission clients
- Better testability
- Reduced coupling

### Maintenance
- Package can be versioned independently
- Bug fixes benefit all users
- Easier to update for new Transmission versions

### Features
- Foundation for advanced features (async sequences, Combine publishers)
- Easier to add retry logic, request queuing, etc.
- Could support multiple simultaneous sessions

---

## References

- Transmission RPC Spec: `/home/user/throttle2/rpc-spec.md`
- Current Implementation: `/home/user/throttle2/Throttle 2/Torrent/`
- Package Location: `/home/user/throttle2/TransmissionRPC/`
- JSON-RPC 2.0 Spec: https://www.jsonrpc.org/specification

---

## Next Steps

Once you approve this plan, I recommend starting with **Phase 1** to establish the foundational models and types. This phase is low-risk and will validate the architectural decisions before we modify the app code.

**Immediate Actions:**
1. Review this plan and provide feedback
2. Answer the open questions in the "Open Questions & Decisions Needed" section
3. Approve or suggest changes to the proposed API design
4. Give the go-ahead to start Phase 1 implementation
