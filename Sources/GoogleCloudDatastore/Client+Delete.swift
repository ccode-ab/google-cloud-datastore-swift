import GRPC
import NIO

extension Client {

    /// Deletes the entities for the given keys.
    /// - Parameter keys: Keys representing the entities to delete.
    /// - Returns: Future result.
    public func deleteAll<Key>(_ keys: [Key]) -> EventLoopFuture<Void> where Key: GoogleCloudDatastore.Key {
        let request = Google_Datastore_V1_CommitRequest.with {
            $0.projectID = datastore.projectID
            $0.mutations = keys.map { key in
                Google_Datastore_V1_Mutation.with {
                    $0.operation = .delete(key.raw)
                }
            }
            $0.mode = .nonTransactional
        }

        return datastore.raw
            .commit(request)
            .response
            .hop(to: eventLoop)
            .map { _ in () }
    }

    /// Deletes the entity for the given key.
    /// - Parameter key: Key representing the entity to delete.
    /// - Returns: Future result.
    public func delete<Key>(_ key: Key) -> EventLoopFuture<Void> where Key: GoogleCloudDatastore.Key {
        deleteAll([key])
    }

    /// Deletes the given entities.
    /// - Parameter entities: Entities to delete.
    /// - Returns: Future result.
    public func deleteAll<Entity>(_ entities: [Entity]) -> EventLoopFuture<Void> where Entity: GoogleCloudDatastore.Entity, Entity.Key: GoogleCloudDatastore.Key {
        deleteAll(entities.map({ $0.key}))
    }

    /// Deletes the given entity.
    /// - Parameter entity: Entity to delete.
    /// - Returns: Future result.
    public func delete<Entity>(_ entity: Entity) -> EventLoopFuture<Void> where Entity: GoogleCloudDatastore.Entity, Entity.Key: GoogleCloudDatastore.Key {
        delete(entity.key)
    }
}
