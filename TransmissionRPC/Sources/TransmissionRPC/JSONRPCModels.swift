import Foundation

struct JSONRPCRequest<Params: Encodable>: Encodable {
  let jsonrpc: String
  let params: Params?
  let method: String
  let id: Int?

  init(method: String, params: Params?, id: Int?) {
    self.jsonrpc = "2.0"
    self.method = method
    self.params = params
    self.id = id
  }
}

public struct JSONRPCErrorData: Sendable, Decodable, Equatable {
  public let errorString: String?
  public let result: JSONObject?
}

public struct JSONRPCError: Sendable, Decodable, Equatable, Error {
  public let code: Int
  public let message: String
  public let data: JSONRPCErrorData?
}

struct JSONRPCResponse<Result: Decodable>: Decodable {
  let jsonrpc: String
  let result: Result?
  let error: JSONRPCError?
  let id: Int?
}

