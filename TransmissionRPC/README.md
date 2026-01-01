# TransmissionRPC

Swift client for Transmission's JSON-RPC 2.0 API (Transmission 4.1+, `rpc_version` 18), following `rpc-spec.md` in the repo root.

## Usage

```swift
import TransmissionRPC

let client = TransmissionRPCClient(configuration: .init(
  url: URL(string: "http://host:9091/transmission/rpc")!,
  credentials: .init(username: "user", password: "pass")
))

struct SessionGetResult: Decodable { let version: String }
let result: SessionGetResult = try await client.call(
  method: "session_get",
  params: ["fields": .array([.string("version")])]
)
print(result.version)
```

## Tests

Run package tests from `TransmissionRPC/`:

```sh
swift test
```

If you see sandbox/cache permission errors, use:

```sh
./scripts/test.sh
```

If you see an SDK/toolchain mismatch (common with Nix-provided Apple SDKs), force the Xcode SDK:

```sh
swift test --sdk "$(xcrun --sdk macosx --show-sdk-path)" --disable-sandbox
```

If `xcrun` is pointing at a Nix SDK, force Xcode's developer directory:

```sh
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" ./scripts/test.sh
```
