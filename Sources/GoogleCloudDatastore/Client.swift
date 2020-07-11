import Foundation
import GRPC
import NIO
import OAuth2

public final class Client {

    let datastore: Datastore
    let eventLoop: EventLoop

    init(datastore: Datastore, eventLoop: EventLoop) {
        self.datastore = datastore
        self.eventLoop = eventLoop
    }
}
