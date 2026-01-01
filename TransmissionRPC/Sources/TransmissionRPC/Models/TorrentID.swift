import Foundation

/// Identifies a torrent by either its numeric ID or SHA1 hash
///
/// Transmission RPC accepts torrent IDs in multiple formats:
/// - Integer ID (not stable across daemon restarts)
/// - SHA1 hash string (stable identifier)
/// - String "recently_active" for recently active torrents
public enum TorrentID: Sendable, Equatable {
    /// Numeric torrent ID (not stable across daemon restarts)
    case id(Int)

    /// SHA1 hash string (stable identifier)
    case hash(String)

    /// Special value for recently active torrents
    case recentlyActive

    /// Creates a TorrentID from an integer
    public static func from(_ id: Int) -> TorrentID {
        .id(id)
    }

    /// Creates a TorrentID from a hash string
    public static func from(_ hash: String) -> TorrentID {
        .hash(hash)
    }
}

extension TorrentID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            self = .id(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            if stringValue == "recently_active" {
                self = .recentlyActive
            } else {
                self = .hash(stringValue)
            }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "TorrentID must be an Int or String"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .id(let id):
            try container.encode(id)
        case .hash(let hash):
            try container.encode(hash)
        case .recentlyActive:
            try container.encode("recently_active")
        }
    }
}

extension TorrentID: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .id(value)
    }
}

extension TorrentID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        if value == "recently_active" {
            self = .recentlyActive
        } else {
            self = .hash(value)
        }
    }
}
