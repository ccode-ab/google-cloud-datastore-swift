import XCTest
@testable import GoogleCloudDatastore

final class DeleteTests: TetsCase {

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

            try client.put(user).wait()
            sleep(1)
        }

        // Test
        do {
            try client.delete(UserKey(id: id)).wait()
            sleep(1)
        }

        // Post-conditions
        do {
            let userMaybe: User? = try client.get(UserKey(id: id)).wait()
            XCTAssertNil(userMaybe, "User has not been deleted")
        }
    }
}
