import Foundation

/// Information about a Transmission session
///
/// This structure uses dynamic field storage to support flexible session queries.
/// Different requests can return different subsets of session fields.
public struct SessionInfo: Codable, Sendable {
    /// Dynamic storage for all session fields
    public var fields: [String: JSONValue]

    public init(fields: [String: JSONValue]) {
        self.fields = fields
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var fields: [String: JSONValue] = [:]

        for key in container.allKeys {
            fields[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
        }

        self.fields = fields
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)

        for (key, value) in fields {
            guard let codingKey = DynamicCodingKeys(stringValue: key) else { continue }
            try container.encode(value, forKey: codingKey)
        }
    }

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            return nil
        }
    }
}

// MARK: - Common Session Properties
extension SessionInfo {
    /// Transmission version string
    public var version: String? {
        stringValue(for: "version")
    }

    /// RPC protocol version
    public var rpcVersion: Int? {
        intValue(for: "rpc_version")
    }

    /// Default download directory
    public var downloadDir: String? {
        stringValue(for: "download_dir")
    }

    /// Upload speed limit in kB/s
    public var speedLimitUp: Int? {
        intValue(for: "speed_limit_up")
    }

    /// Download speed limit in kB/s
    public var speedLimitDown: Int? {
        intValue(for: "speed_limit_down")
    }

    /// Whether upload speed limit is enabled
    public var speedLimitUpEnabled: Bool? {
        boolValue(for: "speed_limit_up_enabled")
    }

    /// Whether download speed limit is enabled
    public var speedLimitDownEnabled: Bool? {
        boolValue(for: "speed_limit_down_enabled")
    }

    /// Units configuration
    public var units: Units? {
        guard case .object(let unitsDict) = fields["units"] else { return nil }

        let speedUnits = extractStringArray(from: unitsDict["speed_units"] ?? unitsDict["speed-units"])
        let sizeUnits = extractStringArray(from: unitsDict["size_units"] ?? unitsDict["size-units"])
        let memoryUnits = extractStringArray(from: unitsDict["memory_units"] ?? unitsDict["memory-units"])

        let speedBytes = extractInt(from: unitsDict["speed_bytes"] ?? unitsDict["speed-bytes"])
        let sizeBytes = extractInt(from: unitsDict["size_bytes"] ?? unitsDict["size-bytes"])
        let memoryBytes = extractInt(from: unitsDict["memory_bytes"] ?? unitsDict["memory-bytes"])

        return Units(
            speedUnits: speedUnits ?? [],
            speedBytes: speedBytes ?? 0,
            sizeUnits: sizeUnits ?? [],
            sizeBytes: sizeBytes ?? 0,
            memoryUnits: memoryUnits ?? [],
            memoryBytes: memoryBytes ?? 0
        )
    }
}

// MARK: - Helper Methods
extension SessionInfo {
    /// Retrieves a string value for a field key
    public func stringValue(for key: String) -> String? {
        guard case .string(let value) = fields[key] else { return nil }
        return value
    }

    /// Retrieves an integer value for a field key
    public func intValue(for key: String) -> Int? {
        guard case .int(let value) = fields[key] else { return nil }
        return Int(value)
    }

    /// Retrieves a boolean value for a field key
    public func boolValue(for key: String) -> Bool? {
        guard case .bool(let value) = fields[key] else { return nil }
        return value
    }

    /// Retrieves a double value for a field key
    public func doubleValue(for key: String) -> Double? {
        switch fields[key] {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        default:
            return nil
        }
    }

    private func extractStringArray(from value: JSONValue?) -> [String]? {
        guard let value = value else { return nil }
        if case .array(let array) = value {
            return array.compactMap { item in
                if case .string(let string) = item { return string }
                return nil
            }
        }
        return nil
    }

    private func extractInt(from value: JSONValue?) -> Int? {
        guard let value = value else { return nil }
        if case .int(let int) = value { return Int(int) }
        return nil
    }
}

// MARK: - Units
extension SessionInfo {
    /// Units configuration for the Transmission session
    public struct Units: Codable, Sendable {
        public let speedUnits: [String]
        public let speedBytes: Int
        public let sizeUnits: [String]
        public let sizeBytes: Int
        public let memoryUnits: [String]
        public let memoryBytes: Int

        public init(
            speedUnits: [String],
            speedBytes: Int,
            sizeUnits: [String],
            sizeBytes: Int,
            memoryUnits: [String],
            memoryBytes: Int
        ) {
            self.speedUnits = speedUnits
            self.speedBytes = speedBytes
            self.sizeUnits = sizeUnits
            self.sizeBytes = sizeBytes
            self.memoryUnits = memoryUnits
            self.memoryBytes = memoryBytes
        }

        enum CodingKeys: String, CodingKey {
            case speedUnits = "speed_units"
            case speedBytes = "speed_bytes"
            case sizeUnits = "size_units"
            case sizeBytes = "size_bytes"
            case memoryUnits = "memory_units"
            case memoryBytes = "memory_bytes"
        }
    }
}
