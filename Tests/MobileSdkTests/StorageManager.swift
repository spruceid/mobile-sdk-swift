import XCTest
@testable import SpruceIDMobileSdk

final class StorageManagerTest: XCTestCase {
    func testStorage() throws {
        let sm = StorageManager()
        let key = "test_key"
        let value = Data("Some random string of text. 😎".utf8)

        XCTAssertNoThrow(try sm.add(key: key, value: value))

        let payload = try sm.get(key: key)

        XCTAssert(payload == value, "\(classForCoder):\(#function): Mismatch between stored & retrieved value.")

        XCTAssertNoThrow(try sm.remove(key: key))
    }
}
