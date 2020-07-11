import GRPC
import NIO

extension Client {

    /// Lookups the entities for the given keys.
    /// - Parameter keys: Keys representing the entities to lookup.
    /// - Returns: Future result with entities. Entities that was not found is `nil`.
    public func getAll<Entity>(_ keys: [Entity.Key]) -> EventLoopFuture<[Entity?]> where Entity: GoogleCloudDatastore.Entity, Entity.Key: Key {
        let request = Google_Datastore_V1_LookupRequest.with {
            $0.projectID = datastore.projectID
            $0.keys = keys.map({ $0.raw })
        }

        return datastore.raw
            .lookup(request)
            .response
            .hop(to: eventLoop)
            .flatMapThrowing { response in
                var results = [Entity?]()
                results.reserveCapacity(keys.count)

                for key in keys {
                    if let raw = response.found.first(where: { $0.entity.key.path.last!.idType == key.id.raw }) {
                        results.append(try Entity.init(raw: raw.entity))
                    } else {
                        results.append(nil)
                    }
                }

                return results
            }
    }

    /// Lookups the entitiy for the given key.
    /// - Parameter key: Key representing the entity to lookup.
    /// - Returns: Future result with the entity or `nil` if the entitiy was not found.
    public func get<Entity>(_ key: Entity.Key) -> EventLoopFuture<Entity?> where Entity: GoogleCloudDatastore.Entity, Entity.Key: Key {
        getAll([key]).map { $0[0] }
    }
}
