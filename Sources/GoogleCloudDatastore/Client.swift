import Foundation
import GRPC
import NIO
import OAuth2

public final class Client {

    let raw: Google_Datastore_V1_DatastoreClient
    let projectID: String

    private init(raw: Google_Datastore_V1_DatastoreClient, projectID: String) {
        self.raw = raw
        self.projectID = projectID

        Self.default = self
    }

    public private(set) static var `default`: Client!

    // MARK: - Make

    private enum MakeError: Error {
        case noTokenProvider
        case tokenProviderFailed
        case invalidDatastoreEmulatorHost
        case invalidDatastoreEmulatorHostPort
    }

    public struct Configuration {

        public let projectID: String
        public let timeLimit: TimeLimit
        public let insecureHost: String?

        public init(projectID: String, timeLimit: TimeLimit = .timeout(.seconds(30)), insecureHost: String? = nil) {
            self.projectID = projectID
            self.timeLimit = timeLimit
            self.insecureHost = insecureHost
        }
    }

    public static func make(projectID: String, group eventLoopGroup: EventLoopGroup) -> EventLoopFuture<Client> {
        make(configuration: Configuration(projectID: projectID), group: eventLoopGroup)
    }

    public static func make(configuration: Configuration, group eventLoopGroup: EventLoopGroup) -> EventLoopFuture<Client> {
        let promise = eventLoopGroup.next().makePromise(of: Client.self)

        // Emulator
        if let datastoreEmulatorHost = configuration.insecureHost ?? ProcessInfo.processInfo.environment["DATASTORE_EMULATOR_HOST"] {
            let components = datastoreEmulatorHost.components(separatedBy: ":") // TODO: Use URLComponents?
            guard components.count >= 2 else {
                promise.fail(MakeError.invalidDatastoreEmulatorHost)
                return promise.futureResult
            }
            guard let port = Int(components[1]) else {
                promise.fail(MakeError.invalidDatastoreEmulatorHostPort)
                return promise.futureResult
            }

            let channel = ClientConnection
                .insecure(group: eventLoopGroup)
                .connect(host: components[0], port: port)

            let callOptions = CallOptions(
                timeLimit: configuration.timeLimit
            )
            let client = Google_Datastore_V1_DatastoreClient(channel: channel, defaultCallOptions: callOptions)

            promise.succeed(Client(raw: client, projectID: configuration.projectID))
            return promise.futureResult
        }

        // Production
        guard let provider = DefaultTokenProvider(scopes: ["https://www.googleapis.com/auth/datastore"]) else {
            promise.fail(MakeError.noTokenProvider)
            return promise.futureResult
        }

        do {
            try provider.withToken { token, error in
                guard let token = token, let accessToken = token.AccessToken else {
                    promise.fail(error ?? MakeError.tokenProviderFailed)
                    return
                }

                let channel = ClientConnection
                    .secure(group: eventLoopGroup)
                    .connect(host: "datastore.googleapis.com", port: 443)

                let callOptions = CallOptions(
                    customMetadata: ["authorization": "Bearer \(accessToken)"],
                    timeLimit: configuration.timeLimit
                )
                let client = Google_Datastore_V1_DatastoreClient(channel: channel, defaultCallOptions: callOptions)

                promise.succeed(Client(raw: client, projectID: configuration.projectID))
            }
        } catch {
            promise.fail(error)
        }

        return promise.futureResult
    }
}
