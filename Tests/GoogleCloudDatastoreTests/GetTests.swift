import XCTest
@testable import GoogleCloudDatastore

final class GetTests: DatastoreTestCase {

    static var allTests: [(String, (GetTests) -> () throws -> ())] = [
        ("testFound", testFound),
        ("testNotFound", testNotFound),
    ]

    func testFound() throws {
        let id = ID.named("\(#function)")
        let email = "dev@ccode.se"

        // Pre-conditions
        do {
            let user: User? = try datastore.get(UserKey(id: id, namespace: .default)).wait()
            XCTAssertNil(user, "User should not exist before test")
        }

        // Set up
        do {
            let user = User(id: id, namespace: .default)
            user.email = email

            try datastore.put(user).wait()
        }

        // Test
        do {
            let userMaybe: User? = try datastore.get(UserKey(id: id, namespace: .default)).wait()

            let user = try XCTUnwrap(userMaybe, "User does not exist")
            XCTAssertEqual(user.email, email, "User email is incorrect")
        }
    }

    func testNotFound() throws {
        let id = ID.named("\(#function)")

        // Test
        do {
            let userMaybe: User? = try datastore.get(UserKey(id: id, namespace: .default)).wait()
            XCTAssertNil(userMaybe, "User should not exist")
        }
    }
}
