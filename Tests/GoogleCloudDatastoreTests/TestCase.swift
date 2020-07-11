import NIO
import Foundation
import XCTest
@testable import GoogleCloudDatastore

class TetsCase: XCTestCase {

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    private(set) lazy var datastore = try! Datastore.bootstrap(configuration: .init(
        projectID: "testing",
        insecureHost: "localhost:8081"
    ), group: eventLoopGroup).wait()

    private(set) var client: Client!

    override func setUp() {
        super.setUp()

        client = datastore.client(on: eventLoopGroup.next())

        // Delete datastore test-entities
        let users = try! client.query(User.self).getAll().wait()
        try! client.deleteAll(users).wait()

        sleep(1)
    }
}
