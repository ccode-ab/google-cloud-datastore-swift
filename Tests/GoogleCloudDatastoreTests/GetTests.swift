import XCTest
@testable import GoogleCloudDatastore

final class GetTests: TetsCase {

    static var allTests: [(String, (GetTests) -> () throws -> ())] = [
        ("testFound", testFound),
        ("testNotFound", testNotFound),
    ]

    func testFound() throws {
        let id = ID.named("\(#function)")
        let email = "dev@ccode.se"

        // Pre-conditions
        do {
            let user: User? = try UserKey(id: id).get().wait()
            XCTAssertNil(user, "User should not exist before test")
        }

        // Set up
        do {
            let user = User(id: id)
            user.email = email

            try user.put().wait()
        }

        // Test
        do {
            let userMaybe: User? = try UserKey(id: id).get().wait()

            let user = try XCTUnwrap(userMaybe, "User does not exist")
            XCTAssertEqual(user.email, email, "User email is incorrect")
        }
    }

    func testNotFound() throws {
        let id = ID.named("\(#function)")

        // Test
        do {
            let userMaybe: User? = try UserKey(id: id).get().wait()
            XCTAssertNil(userMaybe, "User should not exist")
        }
    }
}
