import Foundation

/// High-level actor for interacting with Transmission RPC
///
/// This actor provides type-safe methods for all Transmission RPC operations,
/// wrapping the low-level `TransmissionRPCClient` with a clean Swift API.
///
/// Example usage:
/// ```swift
/// let session = TransmissionSession(
///     configuration: TransmissionRPCClientConfiguration(
///         baseURL: URL(string: "http://localhost:9091/transmission/rpc")!
///     )
/// )
///
/// let torrents = try await session.getTorrents(
///     fields: TorrentField.standardFields,
///     ids: nil
/// )
/// ```
public actor TransmissionSession {
    private let client: TransmissionRPCClient

    /// Creates a new Transmission session
    ///
    /// - Parameters:
    ///   - configuration: Configuration for the RPC client
    ///   - urlSession: URLSession to use for requests (defaults to .shared)
    public init(
        configuration: TransmissionRPCClientConfiguration,
        urlSession: URLSession = .shared
    ) {
        self.client = TransmissionRPCClient(
            configuration: configuration,
            urlSession: urlSession
        )
    }

    /// Creates a new Transmission session with a base URL
    ///
    /// - Parameters:
    ///   - baseURL: Base URL for the Transmission RPC endpoint
    ///   - username: Optional username for authentication
    ///   - password: Optional password for authentication
    ///   - urlSession: URLSession to use for requests (defaults to .shared)
    public convenience init(
        baseURL: URL,
        username: String? = nil,
        password: String? = nil,
        urlSession: URLSession = .shared
    ) {
        let config = TransmissionRPCClientConfiguration(
            baseURL: baseURL,
            username: username,
            password: password
        )
        self.init(configuration: config, urlSession: urlSession)
    }
}

// MARK: - Torrent Accessors
extension TransmissionSession {
    /// Retrieves torrents from Transmission
    ///
    /// - Parameters:
    ///   - fields: Array of fields to retrieve for each torrent
    ///   - ids: Optional array of torrent IDs to retrieve. If nil, returns all torrents.
    ///   - format: Response format (objects or table, defaults to objects)
    /// - Returns: Response containing array of torrents and optionally removed torrent IDs
    public func getTorrents(
        fields: [TorrentField],
        ids: [TorrentID]? = nil,
        format: String = "objects"
    ) async throws -> TorrentResponse {
        struct Request: Encodable {
            let fields: [String]
            let ids: [TorrentID]?
            let format: String
        }

        let fieldNames = fields.map { $0.rawValue }
        let request = Request(fields: fieldNames, ids: ids, format: format)

        do {
            let response: TorrentResponse = try await client.call(
                method: "torrent_get",
                params: request
            )
            return response
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch let error as DecodingError {
            throw TransmissionError.decodingError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }

    /// Retrieves a single torrent with detailed information
    ///
    /// - Parameter id: The torrent ID
    /// - Returns: The torrent, or nil if not found
    public func getTorrent(id: TorrentID) async throws -> Torrent? {
        let response = try await getTorrents(
            fields: TorrentField.allFields,
            ids: [id]
        )
        return response.torrents.first
    }

    /// Retrieves recently active torrents
    ///
    /// - Parameter fields: Array of fields to retrieve
    /// - Returns: Response containing recently active torrents and removed torrent IDs
    public func getRecentlyActiveTorrents(
        fields: [TorrentField]
    ) async throws -> TorrentResponse {
        try await getTorrents(fields: fields, ids: [.recentlyActive])
    }
}

// MARK: - Torrent Mutators
extension TransmissionSession {
    /// Adds a new torrent to Transmission
    ///
    /// - Parameter request: Request containing torrent data and options
    /// - Returns: Result indicating whether torrent was added or was duplicate
    public func addTorrent(
        _ request: AddTorrentRequest
    ) async throws -> AddTorrentResult {
        do {
            let result: AddTorrentResult = try await client.call(
                method: "torrent_add",
                params: request
            )
            return result
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch let error as DecodingError {
            throw TransmissionError.decodingError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }

    /// Modifies properties of one or more torrents
    ///
    /// - Parameters:
    ///   - ids: Array of torrent IDs to modify. Empty array means all torrents.
    ///   - changes: Changes to apply to the torrents
    public func setTorrent(
        ids: [TorrentID],
        changes: TorrentChanges
    ) async throws {
        struct Request: Encodable {
            let ids: [TorrentID]
            let changes: TorrentChanges

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: DynamicCodingKeys.self)

                // Encode ids
                try container.encode(ids, forKey: DynamicCodingKeys(stringValue: "ids")!)

                // Encode changes fields directly into the container
                let changesEncoder = JSONEncoder()
                let changesData = try changesEncoder.encode(changes)
                let changesDict = try JSONDecoder().decode(
                    [String: JSONValue].self,
                    from: changesData
                )

                for (key, value) in changesDict {
                    guard let codingKey = DynamicCodingKeys(stringValue: key) else { continue }
                    try container.encode(value, forKey: codingKey)
                }
            }

            private struct DynamicCodingKeys: CodingKey {
                var stringValue: String
                var intValue: Int?

                init?(stringValue: String) {
                    self.stringValue = stringValue
                    self.intValue = nil
                }

                init?(intValue: Int) {
                    return nil
                }
            }
        }

        let request = Request(ids: ids, changes: changes)

        do {
            struct EmptyResponse: Decodable {}
            let _: EmptyResponse = try await client.call(
                method: "torrent_set",
                params: request
            )
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }

    /// Removes one or more torrents
    ///
    /// - Parameters:
    ///   - ids: Array of torrent IDs to remove
    ///   - deleteLocalData: Whether to delete downloaded files
    public func removeTorrents(
        ids: [TorrentID],
        deleteLocalData: Bool = false
    ) async throws {
        struct Request: Encodable {
            let ids: [TorrentID]
            let deleteLocalData: Bool

            enum CodingKeys: String, CodingKey {
                case ids
                case deleteLocalData = "delete_local_data"
            }
        }

        let request = Request(ids: ids, deleteLocalData: deleteLocalData)

        do {
            struct EmptyResponse: Decodable {}
            let _: EmptyResponse = try await client.call(
                method: "torrent_remove",
                params: request
            )
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }

    /// Renames a file or directory in a torrent
    ///
    /// - Parameters:
    ///   - id: The torrent ID
    ///   - path: Current path of the file or directory
    ///   - newName: New name (just the name, not the full path)
    /// - Returns: The new path and name
    public func renamePath(
        id: TorrentID,
        path: String,
        newName: String
    ) async throws -> (path: String, name: String) {
        struct Request: Encodable {
            let ids: [TorrentID]
            let path: String
            let name: String
        }

        struct Response: Decodable {
            let path: String
            let name: String
        }

        let request = Request(ids: [id], path: path, name: newName)

        do {
            let response: Response = try await client.call(
                method: "torrent_rename_path",
                params: request
            )
            return (path: response.path, name: response.name)
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch let error as DecodingError {
            throw TransmissionError.decodingError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }

    /// Moves one or more torrents to a new location
    ///
    /// - Parameters:
    ///   - ids: Array of torrent IDs to move
    ///   - location: New download directory path
    ///   - move: If true, physically move files. If false, just update the path.
    public func setLocation(
        ids: [TorrentID],
        location: String,
        move: Bool = true
    ) async throws {
        struct Request: Encodable {
            let ids: [TorrentID]
            let location: String
            let move: Bool
        }

        let request = Request(ids: ids, location: location, move: move)

        do {
            struct EmptyResponse: Decodable {}
            let _: EmptyResponse = try await client.call(
                method: "torrent_set_location",
                params: request
            )
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }
}

// MARK: - Torrent Actions
extension TransmissionSession {
    /// Starts one or more torrents
    ///
    /// - Parameter ids: Array of torrent IDs to start. Empty array means all torrents.
    public func startTorrents(ids: [TorrentID]) async throws {
        try await performTorrentAction(method: "torrent_start", ids: ids)
    }

    /// Starts one or more torrents immediately (ignoring queue position)
    ///
    /// - Parameter ids: Array of torrent IDs to start
    public func startTorrentsNow(ids: [TorrentID]) async throws {
        try await performTorrentAction(method: "torrent_start_now", ids: ids)
    }

    /// Stops one or more torrents
    ///
    /// - Parameter ids: Array of torrent IDs to stop. Empty array means all torrents.
    public func stopTorrents(ids: [TorrentID]) async throws {
        try await performTorrentAction(method: "torrent_stop", ids: ids)
    }

    /// Verifies one or more torrents
    ///
    /// - Parameter ids: Array of torrent IDs to verify. Empty array means all torrents.
    public func verifyTorrents(ids: [TorrentID]) async throws {
        try await performTorrentAction(method: "torrent_verify", ids: ids)
    }

    /// Re-announces one or more torrents to trackers
    ///
    /// - Parameter ids: Array of torrent IDs to reannounce. Empty array means all torrents.
    public func reannounceTorrents(ids: [TorrentID]) async throws {
        try await performTorrentAction(method: "torrent_reannounce", ids: ids)
    }

    /// Helper method to perform torrent actions
    private func performTorrentAction(method: String, ids: [TorrentID]) async throws {
        struct Request: Encodable {
            let ids: [TorrentID]
        }

        let request = Request(ids: ids)

        do {
            struct EmptyResponse: Decodable {}
            let _: EmptyResponse = try await client.call(
                method: method,
                params: request
            )
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }
}

// MARK: - Session Methods
extension TransmissionSession {
    /// Retrieves session information
    ///
    /// - Parameter fields: Optional array of specific fields to retrieve. If nil, returns all fields.
    /// - Returns: Session information
    public func getSessionInfo(fields: [String]? = nil) async throws -> SessionInfo {
        struct Request: Encodable {
            let fields: [String]?
        }

        let request = fields.map { Request(fields: $0) }

        do {
            let info: SessionInfo = try await client.call(
                method: "session_get",
                params: request
            )
            return info
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch let error as DecodingError {
            throw TransmissionError.decodingError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }

    /// Sets session properties
    ///
    /// - Parameter settings: Settings to update
    public func setSessionSettings(_ settings: [String: JSONValue]) async throws {
        do {
            struct EmptyResponse: Decodable {}
            let _: EmptyResponse = try await client.call(
                method: "session_set",
                params: settings
            )
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }

    /// Retrieves session statistics
    ///
    /// - Returns: Session statistics
    public func getSessionStats() async throws -> SessionInfo {
        do {
            let stats: SessionInfo = try await client.call(
                method: "session_stats",
                params: JSONObject?.none
            )
            return stats
        } catch let error as JSONRPCError {
            throw TransmissionError.rpcError(error)
        } catch let error as DecodingError {
            throw TransmissionError.decodingError(error)
        } catch {
            throw TransmissionError.networkError(error)
        }
    }
}
