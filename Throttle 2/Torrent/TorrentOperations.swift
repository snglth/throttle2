//
//  TorrentOperations.swift
//  Throttle 2
//
//  Created by Stephen Grigg on 21/2/2025.
//
import SwiftUI
import TransmissionRPC

// MARK: - Additional Operations Extension
extension TorrentManager {
  enum TorrentOperationError: Error {
    case invalidResponse
    case multipleIdsForRename
    case serverError(String)
    case sessionNotInitialized
  }

  /// Deletes one or more torrents with optional local data deletion
  /// - Parameters:
  ///   - ids: Array of torrent IDs to delete
  ///   - deleteLocalData: Whether to also delete the downloaded files
  /// - Returns: True if deletion was successful
  func deleteTorrents(ids: [Int], deleteLocalData: Bool) async throws -> Bool {
    guard let session = session else {
      throw TorrentOperationError.sessionNotInitialized
    }

    do {
      let torrentIDs = ids.map { TorrentID.id($0) }
      try await session.removeTorrents(ids: torrentIDs, deleteLocalData: deleteLocalData)

      // Trigger a refresh to update the torrents list
      try? await fetchUpdates()

      return true
    } catch {
      print("Delete torrents error: \(error)")
      return false
    }
  }

  /// Moves one or more torrents to a new location
  /// - Parameters:
  ///   - ids: Array of torrent IDs to move
  ///   - location: New location path
  ///   - move: If true, physically move files. If false, just update the location
  /// - Returns: True if move was successful
  func moveTorrents(ids: [Int], to location: String, move: Bool = true) async throws -> Bool {
    guard let session = session else {
      throw TorrentOperationError.sessionNotInitialized
    }

    do {
      let torrentIDs = ids.map { TorrentID.id($0) }
      try await session.setLocation(ids: torrentIDs, location: location, move: move)
      return true
    } catch {
      print("Move torrents error: \(error)")
      return false
    }
  }

  /// Renames a path within a torrent
  /// - Parameters:
  ///   - ids: Single torrent ID (array must contain exactly one ID)
  ///   - path: Path to the file or folder to rename
  ///   - newName: New name for the file or folder
  /// - Returns: Tuple containing the old path, new name, and torrent ID if successful
  func renamePath(ids: [Int], path: String, newName: String) async throws -> (
    path: String, name: String, id: Int
  ) {
    // Verify we only have one ID as required by the API
    guard ids.count == 1 else {
      throw TorrentOperationError.multipleIdsForRename
    }

    guard let session = session else {
      throw TorrentOperationError.sessionNotInitialized
    }

    let torrentID = TorrentID.id(ids[0])
    let result = try await session.renamePath(id: torrentID, path: path, newName: newName)

    // Refresh torrent data to update files and name
    try? await fetchUpdates()

    return (result.path, result.name, ids[0])
  }

  /// Stops one or more torrents.
  /// - Parameter ids: Array of torrent IDs to stop
  /// - Returns: True if the stop operation was successful
  func stopTorrents(ids: [Int]) async throws -> Bool {
    guard let session = session else {
      throw TorrentOperationError.sessionNotInitialized
    }

    do {
      let torrentIDs = ids.map { TorrentID.id($0) }
      try await session.stopTorrents(ids: torrentIDs)
      try? await fetchUpdates()
      return true
    } catch {
      print("Stop torrents error: \(error)")
      return false
    }
  }

  /// Starts one or more torrents.
  /// - Parameter ids: Array of torrent IDs to start
  /// - Returns: True if the start operation was successful
  func startTorrents(ids: [Int]) async throws -> Bool {
    guard let session = session else {
      throw TorrentOperationError.sessionNotInitialized
    }

    do {
      let torrentIDs = ids.map { TorrentID.id($0) }
      try await session.startTorrents(ids: torrentIDs)
      try? await fetchUpdates()
      return true
    } catch {
      print("Start torrents error: \(error)")
      return false
    }
  }

  /// Reannounces one or more torrents.
  /// - Parameter ids: Array of torrent IDs to reannounce
  /// - Returns: True if the reannounce operation was successful
  func reannounceTorrents(ids: [Int]) async throws -> Bool {
    guard let session = session else {
      throw TorrentOperationError.sessionNotInitialized
    }

    do {
      let torrentIDs = ids.map { TorrentID.id($0) }
      try await session.reannounceTorrents(ids: torrentIDs)
      try? await fetchUpdates()
      return true
    } catch {
      print("Reannounce torrents error: \(error)")
      return false
    }
  }

  /// Verifies one or more torrents.
  /// - Parameter ids: Array of torrent IDs to verify
  /// - Returns: True if the verify operation was successful
  func verifyTorrents(ids: [Int]) async throws -> Bool {
    guard let session = session else {
      throw TorrentOperationError.sessionNotInitialized
    }

    do {
      let torrentIDs = ids.map { TorrentID.id($0) }
      try await session.verifyTorrents(ids: torrentIDs)
      try? await fetchUpdates()
      return true
    } catch {
      print("Verify torrents error: \(error)")
      return false
    }
  }
}
