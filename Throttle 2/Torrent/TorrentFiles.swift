import SwiftUI
import TransmissionRPC

extension TorrentManager {
  func setTorrentFiles(id: Int, wanted: [Int]?, unwanted: [Int]?) async throws {
    guard let session = session else {
      throw TorrentOperationError.sessionNotInitialized
    }

    print("📝 Setting files for torrent \(id)")
    print("   Wanted: \(wanted?.count ?? 0) files")
    print("   Unwanted: \(unwanted?.count ?? 0) files")

    // Create the changes
    var changes = TorrentChanges()
    changes.filesWanted = wanted
    changes.filesUnwanted = unwanted

    // Send the torrent-set request
    try await session.setTorrent(ids: [.id(id)], changes: changes)

    print("✅ File selection updated, fetching new state")

    // Fetch the updated torrent state
    let fields: [TorrentField] = [.id, .files, .wanted, .percentDone, .fileStats]
    let response = try await session.getTorrents(fields: fields, ids: [.id(id)])

    print("📥 Got updated torrent data")
    if let torrent = response.torrents.first {
      print("   Fields received: \(torrent.fields.keys.joined(separator: ", "))")
      let filesCount = torrent.files.count
      print("   Files count: \(filesCount)")
    }
  }
}
