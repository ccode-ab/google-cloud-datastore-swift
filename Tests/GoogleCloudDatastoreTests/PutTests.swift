import XCTest
@testable import GoogleCloudDatastore

final class PutTests: DatastoreTestCase {

    static var allTests: [(String, (PutTests) -> () throws -> ())] = [
        ("testPutNew", testPutNew),
    ]

    func testPutNew() throws {
        let id = ID.named("\(#function)")
        let email = "dev@ccode.se"

        // Test
        do {
            let user = User(id: id, namespace: .default)
            user.email = email

            try datastore.put(user).wait()
        }

        // Post-conditions
        do {
            let userMaybe: User? = try datastore.get(UserKey(id: id, namespace: .default)).wait()

            let user = try XCTUnwrap(userMaybe, "User does not exist after put")
            XCTAssertEqual(user.email, email, "User email is incorrect")
        }
    }
}
