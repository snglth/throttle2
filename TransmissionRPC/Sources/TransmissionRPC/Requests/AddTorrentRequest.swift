import Foundation

/// Request to add a new torrent to Transmission
///
/// Either `filename` (for magnet links or file URLs) or `metainfo` (for base64-encoded .torrent data) must be provided.
public struct AddTorrentRequest: Codable, Sendable {
    /// Magnet link or file URL
    public var filename: String?

    /// Base64-encoded .torrent file content
    public var metainfo: String?

    /// Download directory (optional, uses session default if not specified)
    public var downloadDir: String?

    /// Whether to start the torrent paused
    public var paused: Bool?

    /// Files to download (array of file indices, optional)
    public var filesWanted: [Int]?

    /// Files to not download (array of file indices, optional)
    public var filesUnwanted: [Int]?

    /// High-priority files (array of file indices, optional)
    public var priorityHigh: [Int]?

    /// Low-priority files (array of file indices, optional)
    public var priorityLow: [Int]?

    /// Normal-priority files (array of file indices, optional)
    public var priorityNormal: [Int]?

    /// Labels to assign to the torrent
    public var labels: [String]?

    /// Bandwidth priority
    public var bandwidthPriority: Int?

    /// Maximum number of connected peers
    public var peerLimit: Int?

    public init(
        filename: String? = nil,
        metainfo: String? = nil,
        downloadDir: String? = nil,
        paused: Bool? = nil,
        filesWanted: [Int]? = nil,
        filesUnwanted: [Int]? = nil,
        priorityHigh: [Int]? = nil,
        priorityLow: [Int]? = nil,
        priorityNormal: [Int]? = nil,
        labels: [String]? = nil,
        bandwidthPriority: Int? = nil,
        peerLimit: Int? = nil
    ) {
        self.filename = filename
        self.metainfo = metainfo
        self.downloadDir = downloadDir
        self.paused = paused
        self.filesWanted = filesWanted
        self.filesUnwanted = filesUnwanted
        self.priorityHigh = priorityHigh
        self.priorityLow = priorityLow
        self.priorityNormal = priorityNormal
        self.labels = labels
        self.bandwidthPriority = bandwidthPriority
        self.peerLimit = peerLimit
    }

    enum CodingKeys: String, CodingKey {
        case filename
        case metainfo
        case downloadDir = "download_dir"
        case paused
        case filesWanted = "files_wanted"
        case filesUnwanted = "files_unwanted"
        case priorityHigh = "priority_high"
        case priorityLow = "priority_low"
        case priorityNormal = "priority_normal"
        case labels
        case bandwidthPriority = "bandwidth_priority"
        case peerLimit = "peer_limit"
    }
}

// MARK: - Convenience Initializers
extension AddTorrentRequest {
    /// Creates a request to add a torrent from a magnet link
    public static func magnetLink(_ link: String, downloadDir: String? = nil, paused: Bool = false) -> AddTorrentRequest {
        AddTorrentRequest(filename: link, downloadDir: downloadDir, paused: paused)
    }

    /// Creates a request to add a torrent from a .torrent file
    public static func torrentFile(_ fileData: Data, downloadDir: String? = nil, paused: Bool = false) -> AddTorrentRequest {
        let metainfo = fileData.base64EncodedString()
        return AddTorrentRequest(metainfo: metainfo, downloadDir: downloadDir, paused: paused)
    }

    /// Creates a request to add a torrent from a file URL
    public static func torrentURL(_ url: URL, downloadDir: String? = nil, paused: Bool = false) throws -> AddTorrentRequest {
        let data = try Data(contentsOf: url)
        return torrentFile(data, downloadDir: downloadDir, paused: paused)
    }
}
