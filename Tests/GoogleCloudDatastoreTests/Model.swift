import XCTest
@testable import GoogleCloudDatastore

// Using `Testttt`-prefix for kinds just in case someone would run tests against production.
// Running tests deletes all data before test is executed.

// MARK: - User

struct UserKey: Key {

    typealias Entity = User

    static let kind: String = "TesttttUser"
    let id: ID
    let parent: Void
    let namespace: Namespace
}

final class User: Entity {

    var key: UserKey

    init(key: UserKey) {
        self.key = key
    }

    @Property(key: "Email")
    var email: String
}

// MARK: - Access

struct AccessKey: Key {

    typealias Entity = Access

    static let kind: String = "TesttttAccess"
    let id: ID
    let parent: UserKey
    let namespace: Namespace
}

final class Access: Entity {

    var key: AccessKey

    init(key: AccessKey) {
        self.key = key
    }
}
