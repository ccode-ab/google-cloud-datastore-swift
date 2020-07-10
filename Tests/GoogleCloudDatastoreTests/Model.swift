import XCTest
@testable import GoogleCloudDatastore

// Using `_Test_`-prefix for kinds just in case someone would run tests against production.
// Running tests deletes all data before test is executed.

let allKeyKinds: [String] = [
    "_Test_User",
    "_Test_Access",
]

// MARK: - User

struct UserKey: Key {

    let kind: String = "_Test_User"
    let id: ID
    let parent: Void
    let namespace: Namespace
}

final class User: Entity {

    typealias Key = UserKey

    var key: Key

    init(key: Key) {
        self.key = key
    }

    @Property(key: "Email")
    var email: String
}

// MARK: - Access

struct AccessKey: Key {

    let kind: String = "_Test_Access"
    let id: ID
    let parent: UserKey
    let namespace: Namespace
}

final class Access: Entity {

    typealias Key = AccessKey

    var key: Key

    init(key: Key) {
        self.key = key
    }
}
