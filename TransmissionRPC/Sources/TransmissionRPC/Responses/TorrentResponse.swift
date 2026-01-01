import Foundation

/// Response from a torrent-get request
public struct TorrentResponse: Codable, Sendable {
    /// Array of torrents matching the request
    public let torrents: [Torrent]

    /// Array of recently-removed torrent IDs (only present if `ids` was "recently_active")
    public let removed: [Int]?

    public init(torrents: [Torrent], removed: [Int]? = nil) {
        self.torrents = torrents
        self.removed = removed
    }
}
