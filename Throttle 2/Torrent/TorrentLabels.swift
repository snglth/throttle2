//
//  TorrentLabels.swift
//  Throttle 2
//
//  Created by Stephen Grigg on 21/2/2025.
//

import SwiftUI

extension Torrent {
  var labels: [String] {
    dynamicFields["labels"]?.value as? [String] ?? []
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
  struct LabelRequest: Codable {
    var method = "torrent-set"
    let arguments: Arguments

    struct Arguments: Codable {
      let ids: [Int]
      let labels: [String]
    }
  }

  func getLabels(_ torrent: Torrent) -> [String] {
    return torrent.dynamicFields["labels"]?.value as? [String] ?? []
  }

  func isStarred(_ torrent: Torrent) -> Bool {
    let labels = getLabels(torrent)
    return labels.contains("starred")
  }

  func toggleStar(for torrent: Torrent) async throws {
    var currentLabels = getLabels(torrent)
    let isCurrentlyStarred = currentLabels.contains("starred")

    // Prepare new labels array
    if isCurrentlyStarred {
      currentLabels.removeAll { $0 == "starred" }
    } else {
      currentLabels.append("starred")
    }

    var urlRequest = URLRequest(url: baseURL!)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let sessionId = sessionId {
      urlRequest.setValue(sessionId, forHTTPHeaderField: "X-Transmission-Session-Id")
    }

    let request = LabelRequest(arguments: .init(ids: [torrent.id], labels: currentLabels))
    let encoder = JSONEncoder()
    let requestData = try encoder.encode(request)
    urlRequest.httpBody = requestData

    let (data, httpResponse) = try await URLSession.shared.data(for: urlRequest)

    if let httpResponse = httpResponse as? HTTPURLResponse {
      if httpResponse.statusCode == 409 {
        if let newSessionId = httpResponse.allHeaderFields["X-Transmission-Session-Id"] as? String {
          sessionId = newSessionId
          return try await toggleStar(for: torrent)
        }
        throw TorrentOperationError.serverError("Session ID not found in 409 response")
      }
    }

    struct Response: Codable {
      let result: String
    }

    let response = try JSONDecoder().decode(Response.self, from: data)
    if response.result != "success" {
      // Update the local cache immediately
      throw TorrentOperationError.serverError("Failed to update labels")
    }
  }
}
