import Foundation

/// Changes to apply to one or more torrents via torrent-set
///
/// All properties are optional - only the specified properties will be changed.
public struct TorrentChanges: Codable, Sendable {
    /// Bandwidth priority
    public var bandwidthPriority: Int?

    /// Maximum download speed in kB/s
    public var downloadLimit: Int?

    /// Whether to honor the download limit
    public var downloadLimited: Bool?

    /// Indices of files to not download
    public var filesUnwanted: [Int]?

    /// Indices of files to download
    public var filesWanted: [Int]?

    /// Bandwidth group name
    public var group: String?

    /// Whether to honor session upload limits
    public var honorsSessionLimits: Bool?

    /// Labels for the torrent
    public var labels: [String]?

    /// New location for the torrent's content
    public var location: String?

    /// Maximum number of connected peers
    public var peerLimit: Int?

    /// Indices of high-priority files
    public var priorityHigh: [Int]?

    /// Indices of low-priority files
    public var priorityLow: [Int]?

    /// Indices of normal-priority files
    public var priorityNormal: [Int]?

    /// Position in the queue
    public var queuePosition: Int?

    /// Seeding inactivity limit in minutes
    public var seedIdleLimit: Int?

    /// Seeding inactivity mode
    public var seedIdleMode: Int?

    /// Seeding ratio limit
    public var seedRatioLimit: Double?

    /// Seeding ratio mode
    public var seedRatioMode: Int?

    /// Whether to download pieces sequentially
    public var sequentialDownload: Bool?

    /// Piece index to start from when sequential download is enabled
    public var sequentialDownloadFromPiece: Int?

    /// Tracker list (one URL per line, blank line between tiers)
    public var trackerList: String?

    /// Maximum upload speed in kB/s
    public var uploadLimit: Int?

    /// Whether to honor the upload limit
    public var uploadLimited: Bool?

    public init(
        bandwidthPriority: Int? = nil,
        downloadLimit: Int? = nil,
        downloadLimited: Bool? = nil,
        filesUnwanted: [Int]? = nil,
        filesWanted: [Int]? = nil,
        group: String? = nil,
        honorsSessionLimits: Bool? = nil,
        labels: [String]? = nil,
        location: String? = nil,
        peerLimit: Int? = nil,
        priorityHigh: [Int]? = nil,
        priorityLow: [Int]? = nil,
        priorityNormal: [Int]? = nil,
        queuePosition: Int? = nil,
        seedIdleLimit: Int? = nil,
        seedIdleMode: Int? = nil,
        seedRatioLimit: Double? = nil,
        seedRatioMode: Int? = nil,
        sequentialDownload: Bool? = nil,
        sequentialDownloadFromPiece: Int? = nil,
        trackerList: String? = nil,
        uploadLimit: Int? = nil,
        uploadLimited: Bool? = nil
    ) {
        self.bandwidthPriority = bandwidthPriority
        self.downloadLimit = downloadLimit
        self.downloadLimited = downloadLimited
        self.filesUnwanted = filesUnwanted
        self.filesWanted = filesWanted
        self.group = group
        self.honorsSessionLimits = honorsSessionLimits
        self.labels = labels
        self.location = location
        self.peerLimit = peerLimit
        self.priorityHigh = priorityHigh
        self.priorityLow = priorityLow
        self.priorityNormal = priorityNormal
        self.queuePosition = queuePosition
        self.seedIdleLimit = seedIdleLimit
        self.seedIdleMode = seedIdleMode
        self.seedRatioLimit = seedRatioLimit
        self.seedRatioMode = seedRatioMode
        self.sequentialDownload = sequentialDownload
        self.sequentialDownloadFromPiece = sequentialDownloadFromPiece
        self.trackerList = trackerList
        self.uploadLimit = uploadLimit
        self.uploadLimited = uploadLimited
    }

    enum CodingKeys: String, CodingKey {
        case bandwidthPriority = "bandwidth_priority"
        case downloadLimit = "download_limit"
        case downloadLimited = "download_limited"
        case filesUnwanted = "files_unwanted"
        case filesWanted = "files_wanted"
        case group
        case honorsSessionLimits = "honors_session_limits"
        case labels
        case location
        case peerLimit = "peer_limit"
        case priorityHigh = "priority_high"
        case priorityLow = "priority_low"
        case priorityNormal = "priority_normal"
        case queuePosition = "queue_position"
        case seedIdleLimit = "seed_idle_limit"
        case seedIdleMode = "seed_idle_mode"
        case seedRatioLimit = "seed_ratio_limit"
        case seedRatioMode = "seed_ratio_mode"
        case sequentialDownload = "sequential_download"
        case sequentialDownloadFromPiece = "sequential_download_from_piece"
        case trackerList = "tracker_list"
        case uploadLimit = "upload_limit"
        case uploadLimited = "upload_limited"
    }
}

// MARK: - Convenience Methods
extension TorrentChanges {
    /// Creates changes to set labels
    public static func setLabels(_ labels: [String]) -> TorrentChanges {
        TorrentChanges(labels: labels)
    }

    /// Creates changes to move a torrent to a new location
    public static func setLocation(_ location: String) -> TorrentChanges {
        TorrentChanges(location: location)
    }

    /// Creates changes to set wanted files
    public static func setWantedFiles(_ fileIndices: [Int]) -> TorrentChanges {
        TorrentChanges(filesWanted: fileIndices)
    }

    /// Creates changes to set unwanted files
    public static func setUnwantedFiles(_ fileIndices: [Int]) -> TorrentChanges {
        TorrentChanges(filesUnwanted: fileIndices)
    }
}
