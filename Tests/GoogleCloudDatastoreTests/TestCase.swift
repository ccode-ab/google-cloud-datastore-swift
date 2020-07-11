import NIO
import Foundation
import XCTest
@testable import GoogleCloudDatastore

class TetsCase: XCTestCase {

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    private(set) lazy var driver = try! Driver.bootstrap(configuration: .init(
        projectID: "testing",
        insecureHost: "localhost:8081"
    ), group: eventLoopGroup).wait()

    private(set) var datastore: Datastore!

    override func setUp() {
        super.setUp()

        datastore = driver.datastore(on: eventLoopGroup.next())

        // Delete datastore test-entities
        let users = try! datastore.query(User.self).getAll().wait()
        try! datastore.deleteAll(users).wait()

        sleep(1)
    }
}
