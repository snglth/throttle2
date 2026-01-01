import Foundation

/// Result of adding a torrent to Transmission
public struct AddTorrentResult: Codable, Sendable {
    /// The newly added torrent (if not a duplicate)
    public let torrentAdded: TorrentInfo?

    /// The duplicate torrent (if it already exists)
    public let torrentDuplicate: TorrentInfo?

    /// Whether this was a duplicate
    public var isDuplicate: Bool {
        torrentDuplicate != nil
    }

    /// The torrent info (either added or duplicate)
    public var torrent: TorrentInfo? {
        torrentAdded ?? torrentDuplicate
    }

    /// The torrent ID
    public var id: Int? {
        torrent?.id
    }

    /// The torrent name
    public var name: String? {
        torrent?.name
    }

    /// The torrent hash
    public var hashString: String? {
        torrent?.hashString
    }

    public init(torrentAdded: TorrentInfo? = nil, torrentDuplicate: TorrentInfo? = nil) {
        self.torrentAdded = torrentAdded
        self.torrentDuplicate = torrentDuplicate
    }

    enum CodingKeys: String, CodingKey {
        case torrentAdded = "torrent_added"
        case torrentDuplicate = "torrent_duplicate"
    }

    /// Basic information about a torrent returned when adding
    public struct TorrentInfo: Codable, Sendable {
        public let id: Int?
        public let name: String?
        public let hashString: String?

        public init(id: Int? = nil, name: String? = nil, hashString: String? = nil) {
            self.id = id
            self.name = name
            self.hashString = hashString
        }

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case hashString = "hash_string"
        }
    }
}
