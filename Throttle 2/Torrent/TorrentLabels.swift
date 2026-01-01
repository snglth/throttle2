//
//  TorrentLabels.swift
//  Throttle 2
//
//  Created by Stephen Grigg on 21/2/2025.
//

import SwiftUI
import TransmissionRPC

extension Torrent {
  var labels: [String] {
    // Use the built-in labels property from the package if available
    if let labelsArray = arrayValue(for: .labels)?.compactMap({ value in
      if case .string(let string) = value { return string }
      return nil
    }) {
      return labelsArray
    }
    return []
  }

  var nonStarredLabels: [String] {
    labels.filter { $0 != "starred" }
  }
}

struct TorrentLabelsPillsView: View {
  let labels: [String]

  private var normalizedLabels: [String] {
    var seen: Set<String> = []
    return labels
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .filter { seen.insert($0).inserted }
  }

  var body: some View {
    let labels = normalizedLabels
    if !labels.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          ForEach(labels, id: \.self) { label in
            Text(label)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .padding(.horizontal, 8)
              .padding(.vertical, 2)
              .background(Color.secondary.opacity(0.12))
              .clipShape(Capsule())
          }
        }
      }
      .scrollClipDisabledIfAvailable()
      .accessibilityLabel("Labels")
    }
  }
}

private extension View {
  @ViewBuilder
  func scrollClipDisabledIfAvailable() -> some View {
    if #available(iOS 17.0, macOS 14.0, *) {
      self.scrollClipDisabled()
    } else {
      self
    }
  }
}

extension TorrentManager {
  func getLabels(_ torrent: Torrent) -> [String] {
    return torrent.labels
  }

  func isStarred(_ torrent: Torrent) -> Bool {
    let labels = getLabels(torrent)
    return labels.contains("starred")
  }

  func toggleStar(for torrent: Torrent) async throws {
    guard let session = session else {
      throw TorrentOperationError.sessionNotInitialized
    }

    var currentLabels = getLabels(torrent)
    let isCurrentlyStarred = currentLabels.contains("starred")

    // Prepare new labels array
    if isCurrentlyStarred {
      currentLabels.removeAll { $0 == "starred" }
    } else {
      currentLabels.append("starred")
    }

    // Use the session to set labels
    let changes = TorrentChanges(labels: currentLabels)
    try await session.setTorrent(ids: [.id(torrent.id)], changes: changes)

    // Refresh the torrent list
    try? await fetchUpdates()
  }
}
