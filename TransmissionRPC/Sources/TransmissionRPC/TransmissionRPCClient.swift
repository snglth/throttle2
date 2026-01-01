import Foundation

public struct TransmissionRPCCredentials: Sendable, Equatable {
  public let username: String
  public let password: String

  public init(username: String, password: String) {
    self.username = username
    self.password = password
  }
}

public struct TransmissionRPCClientConfiguration: Sendable {
  public let url: URL
  public var credentials: TransmissionRPCCredentials?
  public var additionalHeaders: [String: String]
  public var maxCSRFRefreshAttempts: Int

  public init(
    url: URL,
    credentials: TransmissionRPCCredentials? = nil,
    additionalHeaders: [String: String] = [:],
    maxCSRFRefreshAttempts: Int = 1
  ) {
    self.url = url
    self.credentials = credentials
    self.additionalHeaders = additionalHeaders
    self.maxCSRFRefreshAttempts = maxCSRFRefreshAttempts
  }
}

public enum TransmissionRPCClientError: Sendable, Error, Equatable {
  case invalidHTTPResponse
  case httpStatus(Int)
  case missingSessionIdHeader
  case invalidJSONRPCVersion(String)
  case responseIdMismatch(expected: Int, actual: Int?)
  case missingResult
  case rpcError(JSONRPCError)
}

public actor TransmissionRPCClient {
  public static let sessionIdHeaderField = "X-Transmission-Session-Id"

  private let configuration: TransmissionRPCClientConfiguration
  private let urlSession: URLSession
  private var sessionId: String?
  private var nextRequestId: Int = 1

  public init(configuration: TransmissionRPCClientConfiguration, urlSession: URLSession = .shared) {
    self.configuration = configuration
    self.urlSession = urlSession
  }

  public func call<Result: Decodable>(method: String) async throws -> Result {
    try await call(method: method, params: Optional<JSONObject>.none)
  }

  public func call<Result: Decodable, Params: Encodable>(
    method: String,
    params: Params
  ) async throws -> Result {
    try await call(method: method, params: Optional(params))
  }

  public func call<Result: Decodable, Params: Encodable>(
    method: String,
    params: Params?
  ) async throws -> Result {
    let requestId = nextRequestId
    nextRequestId += 1

    let requestBody = JSONRPCRequest(method: method, params: params, id: requestId)
    return try await sendRequest(requestBody: requestBody, requestId: requestId)
  }

  public func notify<Params: Encodable>(method: String, params: Params? = nil) async throws {
    let requestBody = JSONRPCRequest(method: method, params: params, id: Optional<Int>.none)
    _ = try await sendRawRequest(requestBody: requestBody, requestId: nil, expectsBody: false)
  }

  private func sendRequest<Result: Decodable, Params: Encodable>(
    requestBody: JSONRPCRequest<Params>,
    requestId: Int
  ) async throws -> Result {
    let data = try await sendRawRequest(requestBody: requestBody, requestId: requestId, expectsBody: true)
    let decoded = try JSONDecoder().decode(JSONRPCResponse<Result>.self, from: data)

    guard decoded.jsonrpc == "2.0" else {
      throw TransmissionRPCClientError.invalidJSONRPCVersion(decoded.jsonrpc)
    }
    guard decoded.id == requestId else {
      throw TransmissionRPCClientError.responseIdMismatch(expected: requestId, actual: decoded.id)
    }
    if let error = decoded.error {
      throw TransmissionRPCClientError.rpcError(error)
    }
    guard let result = decoded.result else {
      throw TransmissionRPCClientError.missingResult
    }
    return result
  }

  private func sendRawRequest<Params: Encodable>(
    requestBody: JSONRPCRequest<Params>,
    requestId: Int?,
    expectsBody: Bool
  ) async throws -> Data {
    let encoder = JSONEncoder()
    let bodyData = try encoder.encode(requestBody)

    var attempt = 0
    while true {
      var request = URLRequest(url: configuration.url)
      request.httpMethod = "POST"
      request.httpBody = bodyData
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.setValue("application/json", forHTTPHeaderField: "Accept")

      if let sessionId {
        request.setValue(sessionId, forHTTPHeaderField: Self.sessionIdHeaderField)
      }
      if let credentials = configuration.credentials {
        request.setValue(basicAuthorizationHeader(credentials), forHTTPHeaderField: "Authorization")
      }
      for (header, value) in configuration.additionalHeaders {
        request.setValue(value, forHTTPHeaderField: header)
      }

      let (data, response) = try await urlSession.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw TransmissionRPCClientError.invalidHTTPResponse
      }

      if httpResponse.statusCode == 409 {
        guard let newSessionId = httpResponse.allHeaderFields[Self.sessionIdHeaderField] as? String else {
          throw TransmissionRPCClientError.missingSessionIdHeader
        }
        sessionId = newSessionId
        attempt += 1
        if attempt > configuration.maxCSRFRefreshAttempts {
          throw TransmissionRPCClientError.httpStatus(409)
        }
        continue
      }

      if httpResponse.statusCode == 204, expectsBody == false {
        return Data()
      }

      guard httpResponse.statusCode == 200 else {
        throw TransmissionRPCClientError.httpStatus(httpResponse.statusCode)
      }

      if expectsBody == false {
        return Data()
      }

      return data
    }
  }

  private func basicAuthorizationHeader(_ credentials: TransmissionRPCCredentials) -> String {
    let raw = "\(credentials.username):\(credentials.password)"
    let encoded = Data(raw.utf8).base64EncodedString()
    return "Basic \(encoded)"
  }
}

