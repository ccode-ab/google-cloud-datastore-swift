import GRPC
import NIO

extension Client {

    fileprivate func deleteAll<Key>(keys: [Key]) -> EventLoopFuture<Void> where Key: GoogleCloudDatastore.Key {
        let request = Google_Datastore_V1_CommitRequest.with {
            $0.projectID = projectID
            $0.mutations = keys.map { key in
                Google_Datastore_V1_Mutation.with {
                    $0.operation = .delete(key.raw)
                }
            }
            $0.mode = .nonTransactional
        }

        return raw.commit(request).response.map { _ in () }
    }
}

extension Key {

    /// Deletes the entity for the given key.
    /// - Parameter client: The client to use for operation.
    /// - Returns: Future result.
    public func delete(client: Client = .default) -> EventLoopFuture<Void> {
        client.deleteAll(keys: [self])
    }
}

extension Array where Element: Key {

    /// Deletes the entities for the given keys.
    /// - Parameter client: The client to use for operation.
    /// - Returns: Future result.
    public func deleteAll(client: Client = .default) -> EventLoopFuture<Void> {
        client.deleteAll(keys: self)
    }
}
