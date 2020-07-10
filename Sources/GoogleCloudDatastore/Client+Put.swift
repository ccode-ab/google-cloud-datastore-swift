import GRPC
import NIO

extension Client {

    fileprivate func putAll<Entity>(entities: [Entity]) -> EventLoopFuture<Void> where Entity: GoogleCloudDatastore.Entity, Entity.Key: Key {
        let request = Google_Datastore_V1_CommitRequest.with {
            $0.projectID = projectID
            $0.mutations = entities.map { entity in
                Google_Datastore_V1_Mutation.with {
                    $0.operation = .upsert(entity.raw as! Google_Datastore_V1_Entity)
                }
            }
            $0.mode =  .nonTransactional
        }

        return raw.commit(request).response.map { response in
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
}

extension Entity where Key: GoogleCloudDatastore.Key {

    public func put(client: Client = .default) -> EventLoopFuture<Void> {
        client.putAll(entities: [self])
    }
}

extension Array where Element: Entity, Element.Key: GoogleCloudDatastore.Key {

    public mutating func putAll(client: Client = .default) -> EventLoopFuture<Void> {
        client.putAll(entities: self)
    }
}
