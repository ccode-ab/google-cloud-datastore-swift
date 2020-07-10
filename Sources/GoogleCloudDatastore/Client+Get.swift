import GRPC
import NIO

public enum GetError: Error {
    case notFound
}

extension Client {

    fileprivate func getAll<Entity>(keys: [Entity.Key]) -> EventLoopFuture<[Result<Entity, Error>]> where Entity: GoogleCloudDatastore.Entity, Entity.Key: Key {
        let request = Google_Datastore_V1_LookupRequest.with {
            $0.projectID = projectID
            $0.keys = keys.map({ $0.raw })
        }

        return raw.lookup(request).response.map { response in
            var results = [Result<Entity, Error>]()
            results.reserveCapacity(response.found.count + response.missing.count)

            // TODO: Should we return the entries in the same order as the keys?

            for found in response.found {
                do {
                    results.append(.success(try Entity.init(raw: found.entity)))
                } catch {
                    results.append(.failure(error))
                }
            }
            for _ in response.missing {
                results.append(.failure(GetError.notFound))
            }

            return results
        }
    }
}

extension Key {

    public func get<Entity>(client: Client = .default) -> EventLoopFuture<Entity?> where Entity: GoogleCloudDatastore.Entity, Entity.Key == Self {
        client.getAll(keys: [self]).flatMapThrowing { (results: [Result<Entity, Error>]) -> Entity? in
            switch results[0] {
            case .success(let entity):
                return entity
            case .failure(let error as GetError) where error == .notFound:
                return nil
            case .failure(let error):
                throw error
            }
        }
    }
}

extension Array where Element: Key {

    public func getAll<Entity>(client: Client = .default) -> EventLoopFuture<[Result<Entity, Error>]> where Entity: GoogleCloudDatastore.Entity, Entity.Key == Element {
        client.getAll(keys: self)
    }
}
