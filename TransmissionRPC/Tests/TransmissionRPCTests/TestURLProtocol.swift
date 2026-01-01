import Foundation

final class TestURLProtocol: URLProtocol {
  struct Handler {
    var handle: (URLRequest) throws -> (HTTPURLResponse, Data)
  }

  private static var handlers: [Handler] = []
  private static let lock = NSLock()

  static func setHandlers(_ newHandlers: [Handler]) {
    lock.withLock {
      handlers = newHandlers
    }
  }

  static func clearHandlers() {
    lock.withLock {
      handlers.removeAll()
    }
  }

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    let handler: Handler? = Self.lock.withLock {
      guard !Self.handlers.isEmpty else { return nil }
      return Self.handlers.removeFirst()
    }

    guard let handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    do {
      let (response, data) = try handler.handle(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

private extension NSLock {
  func withLock<T>(_ body: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try body()
  }
}
