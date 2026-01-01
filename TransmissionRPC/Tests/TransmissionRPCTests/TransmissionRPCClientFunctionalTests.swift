import Foundation
import XCTest

@testable import TransmissionRPC

final class TransmissionRPCClientFunctionalTests: XCTestCase {
  private static func requestBody(_ request: URLRequest) throws -> Data {
    if let data = request.httpBody {
      return data
    }
    guard let stream = request.httpBodyStream else {
      throw XCTSkip("Request has no body or body stream")
    }

    stream.open()
    defer { stream.close() }

    var data = Data()
    let bufferSize = 16 * 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while stream.hasBytesAvailable {
      let read = stream.read(buffer, maxLength: bufferSize)
      if read < 0 {
        throw stream.streamError ?? URLError(.cannotDecodeRawData)
      }
      if read == 0 {
        break
      }
      data.append(buffer, count: read)
    }
    return data
  }

  private func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [TestURLProtocol.self]
    return URLSession(configuration: configuration)
  }

  private func makeClient(
    url: URL = URL(string: "http://example.com/transmission/rpc")!,
    credentials: TransmissionRPCCredentials? = nil
  ) -> TransmissionRPCClient {
    TransmissionRPCClient(
      configuration: .init(url: url, credentials: credentials),
      urlSession: makeSession()
    )
  }

  override func tearDown() {
    TestURLProtocol.clearHandlers()
    super.tearDown()
  }

  func testCSRF409RetryAndJSONRPCRequestFormat() async throws {
    struct SessionGetResult: Decodable, Equatable {
      let version: String
    }

    var firstRequestBody: JSONObject?
    var requestId: Int?

    TestURLProtocol.setHandlers([
      .init { request in
          XCTAssertNil(request.value(forHTTPHeaderField: TransmissionRPCClient.sessionIdHeaderField))
          XCTAssertEqual(request.httpMethod, "POST")

          let body = try Self.requestBody(request)
          let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
          XCTAssertEqual(json?["jsonrpc"] as? String, "2.0")
          XCTAssertEqual(json?["method"] as? String, "session_get")
          XCTAssertNotNil(json?["id"])
          requestId = json?["id"] as? Int

          if let params = json?["params"] as? [String: Any] {
            let paramsData = try JSONSerialization.data(withJSONObject: params)
            firstRequestBody = try JSONDecoder().decode(JSONObject.self, from: paramsData)
          } else {
            XCTFail("Missing params object")
          }

          let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 409,
            httpVersion: nil,
            headerFields: [TransmissionRPCClient.sessionIdHeaderField: "sess-123"]
          )!
          return (response, Data("csrf".utf8))
      },
      .init { request in
          XCTAssertEqual(
            request.value(forHTTPHeaderField: TransmissionRPCClient.sessionIdHeaderField),
            "sess-123"
          )

          let body = try Self.requestBody(request)
          let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
          XCTAssertEqual(json?["jsonrpc"] as? String, "2.0")
          XCTAssertEqual(json?["method"] as? String, "session_get")
          XCTAssertEqual(json?["id"] as? Int, requestId)

          let id = try XCTUnwrap(requestId)
          let responseBody: [String: Any] = [
            "jsonrpc": "2.0",
            "result": ["version": "4.1.0"],
            "id": id,
          ]
          let responseData = try JSONSerialization.data(withJSONObject: responseBody)
          let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
          return (response, responseData)
      },
    ])

    let client = makeClient()
    let params: JSONObject = ["fields": .array([.string("version")])]
    let result: SessionGetResult = try await client.call(
      method: "session_get",
      params: params
    )

    XCTAssertEqual(result, .init(version: "4.1.0"))
    XCTAssertEqual(firstRequestBody?["fields"], .array([.string("version")]))
  }

  func testBasicAuthHeaderIsSent() async throws {
    struct AnyResult: Decodable {
      let ok: Bool
    }

    TestURLProtocol.setHandlers([
      .init { request in
          XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic dTpw")

          let body = try Self.requestBody(request)
          let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
          let id = try XCTUnwrap(json?["id"] as? Int)

          let responseBody: [String: Any] = [
            "jsonrpc": "2.0",
            "result": ["ok": true],
            "id": id,
          ]
          let responseData = try JSONSerialization.data(withJSONObject: responseBody)
          let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
          return (response, responseData)
      }
    ])

    let client = makeClient(credentials: .init(username: "u", password: "p"))
    let params: JSONObject = ["fields": .array([])]
    let result: AnyResult = try await client.call(method: "session_get", params: params)
    XCTAssertTrue(result.ok)
  }

  func testRPCErrorIsThrownAndDecoded() async throws {
    TestURLProtocol.setHandlers([
      .init { request in
          let body = try Self.requestBody(request)
          let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
          let id = try XCTUnwrap(json?["id"] as? Int)

          let responseBody: [String: Any] = [
            "jsonrpc": "2.0",
            "error": [
              "code": 7,
              "message": "HTTP error from backend service",
              "data": [
                "errorString": "Couldn't test port: No Response (0)",
                "result": ["ipProtocol": "ipv6"],
              ],
            ],
            "id": id,
          ]
          let responseData = try JSONSerialization.data(withJSONObject: responseBody)
          let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
          return (response, responseData)
      }
    ])

    let client = makeClient()
    do {
      let params: JSONObject = ["ipProtocol": .string("ipv6")]
      let _: JSONObject = try await client.call(method: "port_test", params: params)
      XCTFail("Expected error")
    } catch let TransmissionRPCClientError.rpcError(error) {
      XCTAssertEqual(error.code, 7)
      XCTAssertEqual(error.message, "HTTP error from backend service")
      XCTAssertEqual(error.data?.errorString, "Couldn't test port: No Response (0)")
      XCTAssertEqual(error.data?.result?["ipProtocol"], .string("ipv6"))
    }
  }

  func testNotificationAccepts204() async throws {
    TestURLProtocol.setHandlers([
      .init { request in
          let body = try Self.requestBody(request)
          let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
          XCTAssertNil(json?["id"])

          let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
          return (response, Data())
      }
    ])

    let client = makeClient()
    let params: JSONObject = ["fields": .array([.string("version")])]
    try await client.notify(method: "session_get", params: params)
  }
}
