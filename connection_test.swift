#!/usr/bin/env swift

import Foundation

// Simple test to verify our connection counter and notification system
class ConnectionTest {
  static func test() async {
    print("🧪 Testing GlobalConnectionSemaphore...")

    // Test 1: Set up semaphore
    await GlobalConnectionSemaphore.shared.setSemaphore(for: "test-server", maxConnections: 2)

    let status1 = await GlobalConnectionSemaphore.shared.getStatus()
    print("✅ Initial status: \(status1)")

    // Test 2: Acquire connections
    print("\n📥 Acquiring first connection...")
    await GlobalConnectionSemaphore.shared.acquireConnection()

    let status2 = await GlobalConnectionSemaphore.shared.getStatus()
    print("✅ After first acquire: \(status2)")

    print("\n📥 Acquiring second connection...")
    await GlobalConnectionSemaphore.shared.acquireConnection()

    let status3 = await GlobalConnectionSemaphore.shared.getStatus()
    print("✅ After second acquire: \(status3)")

    // Test 3: Try to acquire third connection (should block)
    print("\n📥 Trying to acquire third connection (should wait)...")
    Task {
      await GlobalConnectionSemaphore.shared.acquireConnection()
      print("✅ Third connection acquired!")
    }

    // Give it a moment to show it's waiting
    try? await Task.sleep(nanoseconds: 1_000_000_000)

    let status4 = await GlobalConnectionSemaphore.shared.getStatus()
    print("✅ Status while waiting: \(status4)")

    // Test 4: Release one connection
    print("\n📤 Releasing first connection...")
    await GlobalConnectionSemaphore.shared.releaseConnection()

    // Give it a moment for the waiting connection to be acquired
    try? await Task.sleep(nanoseconds: 500_000_000)

    let status5 = await GlobalConnectionSemaphore.shared.getStatus()
    print("✅ Final status: \(status5)")

    print("\n🎉 Test completed!")
  }
}

Task {
  await ConnectionTest.test()
  exit(0)
}

RunLoop.main.run()
