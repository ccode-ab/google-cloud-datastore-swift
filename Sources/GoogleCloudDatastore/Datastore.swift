import Foundation
import GRPC
import NIO
import OAuth2

public final class Datastore {

    let raw: Google_Datastore_V1_DatastoreClient
    let projectID: String

    private init(raw: Google_Datastore_V1_DatastoreClient, projectID: String) {
        self.raw = raw
        self.projectID = projectID

        Self.default = self
    }

    /// Default datastore. `nil` if bootstrap has not been called yet.
    public private(set) static var `default`: Datastore!

    // MARK: - Bootstrap

    private enum BootstrapError: Error {
        case noTokenProvider
        case tokenProviderFailed

        case invalidEmulatorHost
        case invalidEmulatorPort
    }

    /// Configuration for bootstrap.
    public struct Configuration {

        /// GCP project id.
        public let projectID: String

        /// Time limit for requests to the datastore. Default is 30 seconds.
        public let timeLimit: TimeLimit

        /// If not `nil`, the connection will be made insecure against a datastore emulator at the host.
        /// Can not be used to connect to production datastore. Default is `nil`.
        public let insecureHost: String?

        public init(projectID: String, timeLimit: TimeLimit = .timeout(.seconds(30)), insecureHost: String? = nil) {
            self.projectID = projectID
            self.timeLimit = timeLimit
            self.insecureHost = insecureHost
        }
    }

    /// Bootstrap the datastore. Authroizes and prepares connection to remote. See `bootstrap(configuration:,group:)` for more options.
    /// - Parameters:
    ///   - projectID: GCP project id to use.
    ///   - eventLoopGroup: Event loop group to use.
    /// - Returns: Future for datastore.
    public static func bootstrap(projectID: String, on eventLoopGroup: EventLoopGroup) -> EventLoopFuture<Datastore> {
        bootstrap(configuration: Configuration(projectID: projectID), group: eventLoopGroup)
    }

    /// Bootstrap the datastore. Authroizes and prepares connection to remote.
    /// - Parameters:
    ///   - configuration: Configuration to use.
    ///   - eventLoopGroup: Event loop group to use.
    /// - Returns: Future for datastore.
    @discardableResult
    public static func bootstrap(configuration: Configuration, group eventLoopGroup: EventLoopGroup) -> EventLoopFuture<Datastore> {

        // Emulator
        if let host = configuration.insecureHost ?? ProcessInfo.processInfo.environment["DATASTORE_EMULATOR_HOST"] {
            let promise = eventLoopGroup.next().makePromise(of: Datastore.self)
            do {
                promise.succeed(try bootstrapForEmulator(host: host, configuration: configuration, on: eventLoopGroup))
            } catch {
                promise.fail(error)
            }
            return promise.futureResult
        }

        // Production
        return bootstrapForProduction(configuration: configuration, on: eventLoopGroup)
    }

    private static func bootstrapForEmulator(host: String, configuration: Configuration, on eventLoopGroup: EventLoopGroup) throws -> Datastore {
        let components = host.components(separatedBy: ":") // TODO: Use URLComponents?
        guard components.count >= 2 else {
            throw BootstrapError.invalidEmulatorHost
        }
        guard let port = Int(components[1]) else {
            throw BootstrapError.invalidEmulatorPort
        }

        let channel = ClientConnection
            .insecure(group: eventLoopGroup)
            .connect(host: components[0], port: port)

        let callOptions = CallOptions(
            timeLimit: configuration.timeLimit
        )
        let client = Google_Datastore_V1_DatastoreClient(channel: channel, defaultCallOptions: callOptions)

        return Datastore(raw: client, projectID: configuration.projectID)
    }

    private static func bootstrapForProduction(configuration: Configuration, on eventLoopGroup: EventLoopGroup) -> EventLoopFuture<Datastore> {
        let promise = eventLoopGroup.next().makePromise(of: Datastore.self)

        guard let provider = DefaultTokenProvider(scopes: ["https://www.googleapis.com/auth/datastore"]) else {
            promise.fail(BootstrapError.noTokenProvider)
            return promise.futureResult
        }

        do {
            try provider.withToken { token, error in
                guard let token = token, let accessToken = token.AccessToken else {
                    promise.fail(error ?? BootstrapError.tokenProviderFailed)
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

                promise.succeed(Datastore(raw: client, projectID: configuration.projectID))
            }
        } catch {
            promise.fail(error)
        }

        return promise.futureResult
    }

    // MARK: - Shutdown

    public func shutdown() -> EventLoopFuture<Void> {
        raw.channel.close()
    }

    // MARK: - Client

    public func client(on eventLoop: EventLoop) -> Client {
        Client(datastore: self, eventLoop: eventLoop)
    }
}
