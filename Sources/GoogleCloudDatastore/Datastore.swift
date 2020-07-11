import Foundation
import GRPC
import NIO
import OAuth2

public final class Datastore {

    let driver: Driver
    let eventLoop: EventLoop

    init(driver: Driver, eventLoop: EventLoop) {
        self.driver = driver
        self.eventLoop = eventLoop
    }
}
