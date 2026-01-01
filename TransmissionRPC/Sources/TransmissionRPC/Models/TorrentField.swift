import Foundation

/// All available fields for torrent queries in Transmission RPC
///
/// These field names follow the snake_case convention introduced in Transmission 4.x (RPC version 18)
/// with JSON-RPC 2.0 support.
public enum TorrentField: String, Codable, CaseIterable, Sendable {
    // MARK: - Core Identification
    case id
    case name
    case hashString = "hash_string"

    // MARK: - Progress & Status
    case percentDone = "percent_done"
    case percentComplete = "percent_complete"
    case status
    case metadataPercentComplete = "metadata_percent_complete"
    case recheckProgress = "recheck_progress"

    // MARK: - Dates & Times
    case addedDate = "added_date"
    case activityDate = "activity_date"
    case doneDate = "done_date"
    case startDate = "start_date"
    case dateCreated = "date_created"
    case editDate = "edit_date"

    // MARK: - Size & Transfer
    case totalSize = "total_size"
    case sizeWhenDone = "size_when_done"
    case leftUntilDone = "left_until_done"
    case downloadedEver = "downloaded_ever"
    case uploadedEver = "uploaded_ever"
    case corruptEver = "corrupt_ever"
    case haveValid = "have_valid"
    case haveUnchecked = "have_unchecked"
    case desiredAvailable = "desired_available"

    // MARK: - Transfer Rates
    case rateDownload = "rate_download"
    case rateUpload = "rate_upload"
    case uploadRatio = "upload_ratio"

    // MARK: - Time Tracking
    case secondsDownloading = "seconds_downloading"
    case secondsSeeding = "seconds_seeding"
    case eta
    case etaIdle = "eta_idle"

    // MARK: - Error Information
    case error
    case errorString = "error_string"

    // MARK: - Files & Content
    case files
    case fileStats = "file_stats"
    case fileCount = "file_count"
    case downloadDir = "download_dir"
    case wanted
    case priorities
    case bytesCompleted = "bytes_completed"

    // MARK: - Torrent Metadata
    case comment
    case creator
    case torrentFile = "torrent_file"
    case magnetLink = "magnet_link"
    case primaryMimeType = "primary_mime_type"

    // MARK: - Pieces
    case pieceCount = "piece_count"
    case pieceSize = "piece_size"
    case pieces
    case availability

    // MARK: - Peers
    case peers
    case peersConnected = "peers_connected"
    case peersGettingFromUs = "peers_getting_from_us"
    case peersSendingToUs = "peers_sending_to_us"
    case peersFrom = "peers_from"
    case peerLimit = "peer_limit"
    case maxConnectedPeers = "max_connected_peers"

    // MARK: - Trackers
    case trackers
    case trackerStats = "tracker_stats"
    case trackerList = "tracker_list"

    // MARK: - Webseeds
    case webseeds
    case webseedsSendingToUs = "webseeds_sending_to_us"

    // MARK: - Limits & Priorities
    case bandwidthPriority = "bandwidth_priority"
    case downloadLimit = "download_limit"
    case downloadLimited = "download_limited"
    case uploadLimit = "upload_limit"
    case uploadLimited = "upload_limited"
    case honorsSessionLimits = "honors_session_limits"

    // MARK: - Seeding
    case seedIdleLimit = "seed_idle_limit"
    case seedIdleMode = "seed_idle_mode"
    case seedRatioLimit = "seed_ratio_limit"
    case seedRatioMode = "seed_ratio_mode"

    // MARK: - Queue
    case queuePosition = "queue_position"

    // MARK: - Sequential Download
    case sequentialDownload = "sequential_download"
    case sequentialDownloadFromPiece = "sequential_download_from_piece"

    // MARK: - Organization
    case labels
    case group

    // MARK: - Flags
    case isFinished = "is_finished"
    case isPrivate = "is_private"
    case isStalled = "is_stalled"

    // MARK: - Deprecated
    /// **DEPRECATED** - This field never worked correctly
    case manualAnnounceTime = "manual_announce_time"
}

extension TorrentField {
    /// Standard fields typically used for torrent list views
    public static let standardFields: [TorrentField] = [
        .id, .name, .percentDone, .percentComplete, .status,
        .addedDate, .downloadedEver, .uploadedEver, .totalSize,
        .activityDate, .error, .errorString, .labels,
        .downloadDir, .hashString
    ]

    /// Additional fields needed for detailed torrent views
    public static let detailFields: [TorrentField] = [
        .files, .fileStats, .uploadRatio, .trackerStats,
        .magnetLink, .torrentFile, .comment, .creator,
        .peers, .peersConnected, .rateDownload, .rateUpload
    ]

    /// All fields combined
    public static let allFields: [TorrentField] = TorrentField.allCases
}
