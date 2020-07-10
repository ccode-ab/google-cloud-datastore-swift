import XCTest
@testable import GoogleCloudDatastore

// Using `Testttt`-prefix for kinds just in case someone would run tests against production.
// Running tests deletes all data before test is executed.

// MARK: - User

struct UserKey: Key {

    static let kind: String = "TesttttUser"
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

    static let kind: String = "TesttttAccess"
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
