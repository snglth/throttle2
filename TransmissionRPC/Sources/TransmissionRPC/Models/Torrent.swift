import Foundation

/// Represents a torrent in Transmission
///
/// This structure uses dynamic field storage to support the flexible field system
/// in Transmission RPC, where different requests can return different subsets of fields.
public struct Torrent: Codable, Identifiable, Sendable {
    /// Dynamic storage for all torrent fields
    /// The fields present depend on what was requested in the torrent-get call
    public var fields: [String: JSONValue]

    /// Creates a torrent from dynamic fields
    public init(fields: [String: JSONValue]) {
        self.fields = fields
    }

    /// Decodes a torrent from dynamic JSON
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var fields: [String: JSONValue] = [:]

        for key in container.allKeys {
            fields[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
        }

        self.fields = fields
    }

    /// Encodes the torrent's dynamic fields
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)

        for (key, value) in fields {
            guard let codingKey = DynamicCodingKeys(stringValue: key) else { continue }
            try container.encode(value, forKey: codingKey)
        }
    }

    /// Dynamic coding keys for flexible field encoding/decoding
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

// MARK: - Identifiable
extension Torrent {
    /// Unique identifier for the torrent
    public var id: Int {
        intValue(for: .id) ?? 0
    }
}

// MARK: - Core Properties
extension Torrent {
    /// Torrent name
    public var name: String? {
        stringValue(for: .name)
    }

    /// SHA1 hash of the torrent
    public var hashString: String? {
        stringValue(for: .hashString)
    }

    /// Current status of the torrent
    public var status: TorrentStatus? {
        guard let rawValue = intValue(for: .status) else { return nil }
        return TorrentStatus(rawValue: rawValue)
    }
}

// MARK: - Progress Properties
extension Torrent {
    /// Download progress (0.0 to 1.0)
    public var percentDone: Double? {
        doubleValue(for: .percentDone)
    }

    /// Verification progress (0.0 to 1.0)
    public var percentComplete: Double? {
        doubleValue(for: .percentComplete)
    }

    /// Computed overall progress
    public var progress: Double {
        percentDone ?? percentComplete ?? {
            guard let downloaded = downloadedEver,
                  let total = totalSize,
                  total > 0 else { return 0 }
            return Double(downloaded) / Double(total)
        }()
    }
}

// MARK: - Size Properties
extension Torrent {
    /// Total size of all files in bytes
    public var totalSize: Int64? {
        int64Value(for: .totalSize)
    }

    /// Total bytes downloaded
    public var downloadedEver: Int64? {
        int64Value(for: .downloadedEver)
    }

    /// Total bytes uploaded
    public var uploadedEver: Int64? {
        int64Value(for: .uploadedEver)
    }

    /// Size when download is complete
    public var sizeWhenDone: Int64? {
        int64Value(for: .sizeWhenDone)
    }

    /// Bytes remaining to download
    public var leftUntilDone: Int64? {
        int64Value(for: .leftUntilDone)
    }
}

// MARK: - Error Properties
extension Torrent {
    /// Error code (0 means no error)
    public var error: Int? {
        intValue(for: .error)
    }

    /// Human-readable error message
    public var errorString: String? {
        stringValue(for: .errorString)
    }

    /// Whether the torrent has an error
    public var hasError: Bool {
        (error ?? 0) != 0
    }
}

// MARK: - Date Properties
extension Torrent {
    /// Date when the torrent was added
    public var addedDate: Date? {
        guard let timestamp = intValue(for: .addedDate) else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    /// Date of last activity
    public var activityDate: Date? {
        guard let timestamp = intValue(for: .activityDate) else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    /// Date when download completed
    public var doneDate: Date? {
        guard let timestamp = intValue(for: .doneDate) else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}

// MARK: - File Properties
extension Torrent {
    /// Download directory path
    public var downloadDir: String? {
        stringValue(for: .downloadDir)
    }

    /// Array indicating which files are wanted
    public var wanted: [Bool]? {
        arrayValue(for: .wanted)?.compactMap { value in
            if case .bool(let bool) = value { return bool }
            if case .int(let int) = value { return int != 0 }
            return nil
        }
    }

    /// Files in the torrent
    public var files: [TorrentFile] {
        guard let filesArray = arrayValue(for: .files) else { return [] }

        return filesArray.compactMap { fileValue in
            guard case .object(let fileDict) = fileValue,
                  case .string(let name) = fileDict["name"],
                  let length = extractInt64(from: fileDict["length"]),
                  let bytesCompleted = extractInt64(from: fileDict["bytes_completed"] ?? fileDict["bytesCompleted"])
            else {
                return nil
            }

            let beginPiece = extractInt(from: fileDict["begin_piece"] ?? fileDict["beginPiece"])
            let endPiece = extractInt(from: fileDict["end_piece"] ?? fileDict["endPiece"])

            return TorrentFile(
                name: name,
                length: length,
                bytesCompleted: bytesCompleted,
                beginPiece: beginPiece,
                endPiece: endPiece
            )
        }
    }
}

// MARK: - Tracker Properties
extension Torrent {
    /// Labels assigned to the torrent
    public var labels: [String]? {
        arrayValue(for: .labels)?.compactMap { value in
            if case .string(let string) = value { return string }
            return nil
        }
    }

    /// Tracker statistics
    public var trackerStats: [JSONObject]? {
        arrayValue(for: .trackerStats)?.compactMap { value in
            if case .object(let object) = value { return object }
            return nil
        }
    }
}

// MARK: - Transfer Rate Properties
extension Torrent {
    /// Current download rate in bytes/second
    public var rateDownload: Int64? {
        int64Value(for: .rateDownload)
    }

    /// Current upload rate in bytes/second
    public var rateUpload: Int64? {
        int64Value(for: .rateUpload)
    }

    /// Upload ratio
    public var uploadRatio: Double? {
        doubleValue(for: .uploadRatio)
    }
}

// MARK: - Helper Methods
extension Torrent {
    /// Retrieves a string value for a field
    public func stringValue(for field: TorrentField) -> String? {
        guard case .string(let value) = fields[field.rawValue] else { return nil }
        return value
    }

    /// Retrieves an integer value for a field
    public func intValue(for field: TorrentField) -> Int? {
        guard case .int(let value) = fields[field.rawValue] else { return nil }
        return Int(value)
    }

    /// Retrieves an Int64 value for a field
    public func int64Value(for field: TorrentField) -> Int64? {
        guard case .int(let value) = fields[field.rawValue] else { return nil }
        return value
    }

    /// Retrieves a double value for a field (handles both double and int)
    public func doubleValue(for field: TorrentField) -> Double? {
        switch fields[field.rawValue] {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        default:
            return nil
        }
    }

    /// Retrieves a boolean value for a field
    public func boolValue(for field: TorrentField) -> Bool? {
        guard case .bool(let value) = fields[field.rawValue] else { return nil }
        return value
    }

    /// Retrieves an array value for a field
    public func arrayValue(for field: TorrentField) -> [JSONValue]? {
        guard case .array(let value) = fields[field.rawValue] else { return nil }
        return value
    }

    /// Retrieves an object value for a field
    public func objectValue(for field: TorrentField) -> JSONObject? {
        guard case .object(let value) = fields[field.rawValue] else { return nil }
        return value
    }

    /// Extracts an Int from a JSONValue
    private func extractInt(from value: JSONValue?) -> Int? {
        guard let value = value else { return nil }
        if case .int(let int) = value { return Int(int) }
        return nil
    }

    /// Extracts an Int64 from a JSONValue
    private func extractInt64(from value: JSONValue?) -> Int64? {
        guard let value = value else { return nil }
        if case .int(let int) = value { return int }
        return nil
    }
}
