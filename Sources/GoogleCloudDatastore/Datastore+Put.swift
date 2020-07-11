import GRPC
import NIO

extension Datastore {

    /// Creates or updates given entities.  Also updates the key for entities where the key is incomplete.
    /// - Parameter entities: Entities to create or update.
    /// - Returns: Future result.
    public func putAll<Entity>(_ entities: [Entity]) -> EventLoopFuture<Void> where Entity: GoogleCloudDatastore.Entity, Entity.Key: Key {
        let request = Google_Datastore_V1_CommitRequest.with {
            $0.projectID = driver.projectID
            $0.mutations = entities.map { entity in
                Google_Datastore_V1_Mutation.with {
                    $0.operation = .upsert(entity.raw as! Google_Datastore_V1_Entity)
                }
            }
            $0.mode = .nonTransactional
        }

        return driver.raw
            .commit(request)
            .response
            .hop(to: eventLoop)
            .map { response in
                for (index, result) in response.mutationResults.enumerated() {
                    guard result.hasKey
                        else { continue }

                    let entity = entities[index]
                    entity.key = type(of: entity.key).init(
                        id: ID(raw: result.key.path.last!.idType!),
                        parent: entity.key.parent,
                        namespace: entity.key.namespace
                    )
                }
            }
    }

    /// Creates or updates given entity.  Also updates the key if the entity's  key is incomplete.
    /// - Parameter entity: Entity to create or update.
    /// - Returns: Future result.
    public func put<Entity>(_ entity: Entity) -> EventLoopFuture<Void> where Entity: GoogleCloudDatastore.Entity, Entity.Key: Key {
        putAll([entity])
    }
}
