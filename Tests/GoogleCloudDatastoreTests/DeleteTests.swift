import XCTest
@testable import GoogleCloudDatastore

final class DeleteTests: DatastoreTestCase {

    static var allTests: [(String, (DeleteTests) -> () throws -> ())] = [
        ("testDeleteExisting", testDeleteExisting),
    ]

    func testDeleteExisting() throws {
        let id = ID.named("testDeleteExisting1")
        let email = "dev@ccode.se"

        // Set up
        do {
            let user = User(id: id)
            user.email = email

            try datastore.put(user).wait()
            sleep(1)
        }

        // Test
        do {
            try datastore.delete(UserKey(id: id)).wait()
            sleep(1)
        }

        // Post-conditions
        do {
            let userMaybe: User? = try datastore.get(UserKey(id: id)).wait()
            XCTAssertNil(userMaybe, "User has not been deleted")
        }
    }
}
