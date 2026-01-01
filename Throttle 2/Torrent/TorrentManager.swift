//
//  TorrentManager.swift
//  Throttle 2
//
//  Created by Stephen Grigg on 20/2/2025.
//
import SwiftUI
import TransmissionRPC

// MARK: - Torrent Extensions for Compatibility
extension Torrent {
  // Note: addedDate and activityDate are now provided by the package
  // These extensions are kept for backward compatibility if needed

  var trackerStats: [[String: Any]]? {
    guard let stats = trackerStats else { return nil }
    // Convert JSONObject array to [String: Any] for compatibility
    return stats.map { jsonObject in
      var dict: [String: Any] = [:]
      for (key, value) in jsonObject {
        dict[key] = convertJSONValueToAny(value)
      }
      return dict
    }
  }

  private func convertJSONValueToAny(_ value: JSONValue) -> Any {
    switch value {
    case .null:
      return NSNull()
    case .bool(let bool):
      return bool
    case .int(let int):
      return int
    case .double(let double):
      return double
    case .string(let string):
      return string
    case .array(let array):
      return array.map { convertJSONValueToAny($0) }
    case .object(let object):
      var dict: [String: Any] = [:]
      for (key, val) in object {
        dict[key] = convertJSONValueToAny(val)
      }
      return dict
    }
  }
}

// MARK: - TorrentManager
@MainActor
class TorrentManager: ObservableObject {
  @Published var torrents: [Torrent] = []
  var fileCache: [String: [TorrentFile]] = []
  private var downloadingCount: Int = 0
  @Published var isLoading = false
  private var nextFull = 0

  private var session: TransmissionSession?
  var fetchTimer: Timer?
  @AppStorage("refreshRate") var refreshRate = 6

  private let standardFields: [TorrentField] = [
    .id, .name, .percentDone, .percentComplete, .status, .addedDate,
    .downloadedEver, .uploadedEver, .totalSize, .activityDate,
    .error, .errorString, .labels, .downloadDir, .hashString,
  ]

  private let fileFields: [TorrentField] = [.files, .fileStats]

  func updateBaseURL(_ url: URL, username: String? = nil, password: String? = nil) {
    print("Base Changed")
    session = TransmissionSession(
      baseURL: url,
      username: username,
      password: password
    )
    reset()
  }

  func reset() {
    print("manager reset")
    torrents = []
    fileCache = [:]
  }

  func getTorrentFiles(forHash hash: String) -> [TorrentFile] {
    return fileCache[hash] ?? []
  }

  func addTorrent(
    fileURL: URL? = nil, magnetLink: String? = nil, metainfo: String? = nil,
    downloadDir: String? = nil
  ) async throws -> (result: String, id: Int?) {
    guard let session = session else {
      throw NSError(
        domain: "TorrentManager", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Session not initialized"])
    }

    var request: AddTorrentRequest

    if let magnetLink = magnetLink {
      request = .magnetLink(magnetLink, downloadDir: downloadDir, paused: false)
    } else if let fileURL = fileURL {
      request = try .torrentURL(fileURL, downloadDir: downloadDir, paused: false)
    } else if let metainfo = metainfo {
      let data = Data(base64Encoded: metainfo) ?? Data()
      request = .torrentFile(data, downloadDir: downloadDir, paused: false)
    } else {
      return ("failed", nil)
    }

    do {
      let result = try await session.addTorrent(request)

      print("Debug - torrent-add request:")
      print("  - success: true")
      print("  - isDuplicate: \(result.isDuplicate)")
      print("  - torrent ID: \(result.id ?? -1)")

      if let id = result.id {
        return ("success", id)
      } else {
        print("  - Warning: No torrent ID found in response")
        return ("success", nil)
      }
    } catch {
      print("  - Error: \(error)")
      return ("failed", nil)
    }
  }

  func fetchTorrentDetails(id: Int) async throws -> Torrent? {
    guard let session = session else { return nil }

    let detailFields: [TorrentField] = standardFields + [
      .files, .fileStats, .uploadRatio, .trackerStats, .addedDate,
      .activityDate, .downloadedEver, .uploadedEver, .totalSize,
      .magnetLink, .torrentFile,
    ]

    return try await session.getTorrent(id: .id(id))
  }

  func getTorrentInfo(id: Int) async throws -> [Torrent] {
    guard let session = session else { return [] }

    let statusFields: [TorrentField] = [
      .id, .name, .status, .percentDone, .totalSize,
      .downloadedEver, .uploadedEver, .downloadDir,
      .errorString, .wanted,
    ]

    let response = try await session.getTorrents(
      fields: statusFields,
      ids: [.id(id)]
    )

    return response.torrents
  }

  func fetchUpdates(selectedId: Int? = nil, fullFetch: Bool = false) async throws {
    guard let session = session else { return }
    @AppStorage("overideFullFetch") var fullFetchAnyway = false

    defer { isLoading = false }

    var fieldsToFetch: [TorrentField] = []
    var firstFetch = fullFetch == true ? true : fileCache.isEmpty

    if fullFetchAnyway {
      firstFetch = true
      fullFetchAnyway = false
    }

    fieldsToFetch = firstFetch ? standardFields + [.files] : standardFields

    // Fetch torrents using the session
    let response = try await session.getTorrents(fields: fieldsToFetch, ids: nil)

    // Handle file caching
    if firstFetch && selectedId == nil {
      for torrent in response.torrents {
        if let hash = torrent.hashString {
          let files = torrent.files
          if !files.isEmpty {
            fileCache[hash] = files
          }
        }
      }
    }

    let torrentsToUpdate = response.torrents

    // Check for torrents with no file info
    let thisNoFiles = torrentsToUpdate.filter { $0.files.count == 0 }.count
    let thisDownloadingCount = torrentsToUpdate.filter { ($0.percentDone ?? 1) != 1 }.count

    if (thisDownloadingCount != downloadingCount || thisNoFiles > 0) && !fullFetch {
      fullFetchAnyway = true
    }

    downloadingCount = thisDownloadingCount
    torrents = torrentsToUpdate
  }

  func startPeriodicUpdates(selectedId: Int? = nil) {
    stopPeriodicUpdates()

    fetchTimer = Timer.scheduledTimer(withTimeInterval: Double(refreshRate), repeats: true) {
      [weak self] _ in
      Task {
        if let selectedId = selectedId {
          try? await self?.fetchUpdates(selectedId: selectedId)
        } else {
          try? await self?.fetchUpdates()
        }
      }
    }
  }

  func stopPeriodicUpdates() {
    fetchTimer?.invalidate()
    fetchTimer = nil
  }
}

// MARK: - Field Access Extensions
extension TorrentManager {
  func getFields(_ fields: [TorrentField]) async throws -> [Int: [String: Any]] {
    var requestFields = fields
    if !fields.contains(.id) {
      requestFields.append(.id)
    }

    try await fetchUpdates()

    var result: [Int: [String: Any]] = [:]
    for torrent in torrents {
      var torrentFields: [String: Any] = [:]
      for field in fields {
        if let value = torrent.fields[field.rawValue] {
          torrentFields[field.rawValue] = convertJSONValueToAny(value)
        }
      }
      if !torrentFields.isEmpty {
        result[torrent.id] = torrentFields
      }
    }

    return result
  }

  func getField<T>(_ field: TorrentField) async throws -> [Int: T] {
    let results = try await getFields([field])

    var typedResults: [Int: T] = [:]
    for (id, fields) in results {
      if let value = fields[field.rawValue] as? T {
        typedResults[id] = value
      }
    }

    return typedResults
  }

  func getFiles(forHash hash: String) -> [TorrentFile]? {
    return fileCache[hash]
  }

  func getFields(_ fields: [TorrentField], forIds ids: [Int]) async throws -> [Int: [String: Any]] {
    var requestFields = fields
    if !fields.contains(.id) {
      requestFields.append(.id)
    }

    try await fetchUpdates()

    var result: [Int: [String: Any]] = [:]
    for torrent in torrents where ids.contains(torrent.id) {
      var torrentFields: [String: Any] = [:]
      for field in fields {
        if let value = torrent.fields[field.rawValue] {
          torrentFields[field.rawValue] = convertJSONValueToAny(value)
        }
      }
      if !torrentFields.isEmpty {
        result[torrent.id] = torrentFields
      }
    }

    return result
  }

  private func convertJSONValueToAny(_ value: JSONValue) -> Any {
    switch value {
    case .null:
      return NSNull()
    case .bool(let bool):
      return bool
    case .int(let int):
      return int
    case .double(let double):
      return double
    case .string(let string):
      return string
    case .array(let array):
      return array.map { convertJSONValueToAny($0) }
    case .object(let object):
      var dict: [String: Any] = [:]
      for (key, val) in object {
        dict[key] = convertJSONValueToAny(val)
      }
      return dict
    }
  }
}

// MARK: - Session Manager Extension
extension TorrentManager {
  func getSession() async throws -> [String: Any] {
    guard let session = session else {
      throw NSError(
        domain: "TransmissionClient", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Session not initialized"])
    }

    let info = try await session.getSessionInfo()

    // Convert to [String: Any] for compatibility
    var result: [String: Any] = [:]
    for (key, value) in info.fields {
      result[key] = convertJSONValueToAny(value)
    }
    return result
  }

  func getSession(fields: [String]) async throws -> [String: Any] {
    guard let session = session else {
      throw NSError(
        domain: "TransmissionClient", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Session not initialized"])
    }

    let info = try await session.getSessionInfo(fields: fields)

    var result: [String: Any] = [:]
    for field in fields {
      if let value = info.fields[field] {
        result[field] = convertJSONValueToAny(value)
      }
    }

    return result
  }

  func getSessionField<T>(_ field: String) async throws -> T? {
    let result = try await getSession(fields: [field])
    return result[field] as? T
  }

  func getDownloadDirectory() async throws -> String? {
    return try await getSessionField("download-dir")
  }

  func getSpeedLimits() async throws -> (up: Int?, down: Int?, upEnabled: Bool?, downEnabled: Bool?) {
    let fields = [
      "speed-limit-up",
      "speed-limit-down",
      "speed-limit-up-enabled",
      "speed-limit-down-enabled",
    ]

    let result = try await getSession(fields: fields)

    return (
      up: result["speed-limit-up"] as? Int,
      down: result["speed-limit-down"] as? Int,
      upEnabled: result["speed-limit-up-enabled"] as? Bool,
      downEnabled: result["speed-limit-down-enabled"] as? Bool
    )
  }
}
