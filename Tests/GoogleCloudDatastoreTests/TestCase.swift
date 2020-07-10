import NIO
import Foundation
import XCTest
@testable import GoogleCloudDatastore

class TetsCase: XCTestCase {

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    private(set) lazy var client = try! Client.make(configuration: .init(
        projectID: "testing",
        insecureHost: "localhost:8081"
        ), group: eventLoopGroup).wait()

    override func setUp() {
        super.setUp()

        // Warmup default client
        _ = client

        // Clean up datastore all test-entities
        let users = User.query().getAll()

        // TODO: Implement
    }
}
