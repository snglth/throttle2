import Foundation

/// Status codes for torrents as defined in Transmission RPC
///
/// The status field indicates what the torrent is currently doing.
public enum TorrentStatus: Int, Codable, Sendable {
    /// Torrent is stopped
    case stopped = 0

    /// Torrent is queued to verify local data
    case queuedToVerify = 1

    /// Torrent is verifying local data
    case verifying = 2

    /// Torrent is queued to download
    case queuedToDownload = 3

    /// Torrent is downloading
    case downloading = 4

    /// Torrent is queued to seed
    case queuedToSeed = 5

    /// Torrent is seeding
    case seeding = 6

    /// Human-readable description of the status
    public var description: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .queuedToVerify:
            return "Queued to Verify"
        case .verifying:
            return "Verifying"
        case .queuedToDownload:
            return "Queued to Download"
        case .downloading:
            return "Downloading"
        case .queuedToSeed:
            return "Queued to Seed"
        case .seeding:
            return "Seeding"
        }
    }

    /// Whether the torrent is actively transferring data
    public var isActive: Bool {
        switch self {
        case .downloading, .seeding:
            return true
        default:
            return false
        }
    }

    /// Whether the torrent is in a queue
    public var isQueued: Bool {
        switch self {
        case .queuedToVerify, .queuedToDownload, .queuedToSeed:
            return true
        default:
            return false
        }
    }
}
