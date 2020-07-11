import XCTest
@testable import GoogleCloudDatastore

final class QueryTests: TetsCase {

    static var allTests: [(String, (QueryTests) -> () throws -> ())] = [
        ("testQueryAll", testQueryAll),
    ]

    func testQueryAll() throws {
        let id1 = ID.named("testQueryAll1")
        let id2 = ID.named("testQueryAll2")
        let email1 = "test1@ccode.se"
        let email2 = "test2@ccode.se"

        // Set up
        do {
            let user1 = User(id: id1)
            user1.email = email1

            let user2 = User(id: id2)
            user2.email = email2

            try datastore.putAll([user1, user2]).wait()
            sleep(1)
        }

        // Test
        do {
            let users = try datastore.query(User.self).getAll().wait()
            XCTAssertEqual(users.count, 2, "Number of uers in datastore is incorrect")

            let user1 = try XCTUnwrap(users.first, "User 1 does not exist")
            XCTAssertEqual(user1.email, email1, "User 1 email is incorrect")

            let user2 = try XCTUnwrap(users.last, "User 2 does not exist")
            XCTAssertEqual(user2.email, email2, "User 2 email is incorrect")
        }
    }

    func testQueryFilterComparable() throws {
        let id1 = ID.named("testQueryFilterComparable1")
        let id2 = ID.named("testQueryFilterComparable2")
        let email1 = "test1@ccode.se"
        let email2 = "test2@ccode.se"

        // Set up
        do {
            let user1 = User(id: id1)
            user1.email = email1

            let user2 = User(id: id2)
            user2.email = email2

            try datastore.putAll([user1, user2]).wait()
            sleep(1)
        }

        // Test
        do {
            let users = try datastore.query(User.self)
                .where(\.email, .equals(email2))
                .getAll()
                .wait()
            XCTAssertEqual(users.count, 1, "Number of uers in datastore is incorrect")

            let user2 = try XCTUnwrap(users.last, "User 2 does not exist")
            XCTAssertEqual(user2.email, email2, "User 2 email is incorrect")
        }
    }
}
