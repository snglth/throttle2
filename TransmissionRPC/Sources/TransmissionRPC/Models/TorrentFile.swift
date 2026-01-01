import Foundation

/// Represents a file within a torrent
///
/// This structure contains information about an individual file in a multi-file torrent,
/// including its name, size, and download progress.
public struct TorrentFile: Codable, Identifiable, Sendable {
    /// The file's path within the torrent
    public let name: String

    /// Total size of the file in bytes
    public let length: Int64

    /// Number of bytes completed for this file
    public let bytesCompleted: Int64

    /// The piece index where this file begins (optional, available in detailed queries)
    public let beginPiece: Int?

    /// The piece index where this file ends (optional, available in detailed queries)
    public let endPiece: Int?

    /// Unique identifier for the file (uses name as ID since file paths are unique within a torrent)
    public var id: String { name }

    /// Download progress as a value between 0 and 1
    public var progress: Double {
        length > 0 ? Double(bytesCompleted) / Double(length) : 0
    }

    /// Whether the file download is complete
    public var isComplete: Bool {
        bytesCompleted >= length
    }

    public init(
        name: String,
        length: Int64,
        bytesCompleted: Int64,
        beginPiece: Int? = nil,
        endPiece: Int? = nil
    ) {
        self.name = name
        self.length = length
        self.bytesCompleted = bytesCompleted
        self.beginPiece = beginPiece
        self.endPiece = endPiece
    }

    enum CodingKeys: String, CodingKey {
        case name
        case length
        case bytesCompleted = "bytes_completed"
        case beginPiece = "begin_piece"
        case endPiece = "end_piece"
    }
}

/// Statistics for a file within a torrent
///
/// This structure contains the non-constant properties of a file, such as whether it's
/// wanted for download and its priority.
public struct TorrentFileStat: Codable, Sendable {
    /// Number of bytes completed for this file
    public let bytesCompleted: Int64

    /// Whether this file is wanted for download
    public let wanted: Bool

    /// Download priority for this file (typically -1, 0, or 1)
    public let priority: Int

    public init(bytesCompleted: Int64, wanted: Bool, priority: Int) {
        self.bytesCompleted = bytesCompleted
        self.wanted = wanted
        self.priority = priority
    }

    enum CodingKeys: String, CodingKey {
        case bytesCompleted = "bytes_completed"
        case wanted
        case priority
    }
}
