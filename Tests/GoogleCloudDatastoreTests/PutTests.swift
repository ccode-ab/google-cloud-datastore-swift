import XCTest
@testable import GoogleCloudDatastore

final class PutTests: TetsCase {

    static var allTests: [(String, (PutTests) -> () throws -> ())] = [
        ("testPutNew", testPutNew),
    ]

    func testPutNew() throws {
        let id = ID.named("\(#function)")
        let email = "dev@ccode.se"

        // Test
        do {
            let user = User(id: id)
            user.email = email

            try user.put().wait()
        }

        // Post-conditions
        do {
            let userMaybe: User? = try UserKey(id: id).get().wait()

            let user = try XCTUnwrap(userMaybe, "User does not exist after put")
            XCTAssertEqual(user.email, email, "User email is incorrect")
        }
    }
}
