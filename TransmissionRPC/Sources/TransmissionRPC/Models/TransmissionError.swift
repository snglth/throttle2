import Foundation

/// Errors that can occur when using TransmissionSession
public enum TransmissionError: Error {
    /// JSON-RPC error from the server
    case rpcError(JSONRPCError)

    /// Network or communication error
    case networkError(Error)

    /// Invalid or unexpected response format
    case invalidResponse(String)

    /// Requested torrent was not found
    case torrentNotFound(TorrentID)

    /// Invalid request parameters
    case invalidRequest(String)

    /// Decoding error
    case decodingError(DecodingError)
}

extension TransmissionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .rpcError(let error):
            return "RPC Error: \(error.message)"
        case .networkError(let error):
            return "Network Error: \(error.localizedDescription)"
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        case .torrentNotFound(let id):
            return "Torrent not found: \(id)"
        case .invalidRequest(let message):
            return "Invalid Request: \(message)"
        case .decodingError(let error):
            return "Decoding Error: \(error.localizedDescription)"
        }
    }
}
