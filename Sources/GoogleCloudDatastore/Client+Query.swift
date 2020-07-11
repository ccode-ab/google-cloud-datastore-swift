import Foundation
import NIO

// MARK: - Query

public struct Query<Entity: GoogleCloudDatastore.Entity> {

    let client: Client
    let namespace: Namespace

    var mirrorableEntity: Entity
    var filters: [Google_Datastore_V1_PropertyFilter] = []

    var orders: [Google_Datastore_V1_PropertyOrder] = []

    /// The sort direction.
    public enum OrderDirection {

        /// Ascending order.
        case ascending

        /// Descending order.
        case descending
    }
}

extension Client {

    public func query<Entity>(_ type: Entity.Type, namespace: Namespace = .default) -> Query<Entity> where Entity: GoogleCloudDatastore.Entity, Entity.Key: GoogleCloudDatastore.Key {
        Query(client: self, namespace: namespace, mirrorableEntity: Entity.init(key: .emptyPropertyValue))
    }
}

// MARK: File-private

extension Query where Entity.Key: GoogleCloudDatastore.Key {

    fileprivate func rawKey<Value>(key: ReferenceWritableKeyPath<Entity, Value>) -> String where Value: PropertyValue {
        mirrorableEntity[keyPath: key] = Value._gcdtc
        defer { mirrorableEntity[keyPath: key] = Value.emptyPropertyValue }

        for child in Mirror(reflecting: mirrorableEntity).children {
            if let value = child.value as? Property<Value>, value.wrappedValue == Value._gcdtc {
                return value.key
            }
        }

        fatalError("KeyPath is not in Entity")
    }
}

// MARK: Filter

public protocol FilterOperationComparableType {}
extension Bool: FilterOperationComparableType {}
extension Int64: FilterOperationComparableType {}
extension Double: FilterOperationComparableType {}
extension String: FilterOperationComparableType {}
extension Date: FilterOperationComparableType {}
extension Data: FilterOperationComparableType {}

public enum FilterOperationComparable<Value: FilterOperationComparableType> {

    /// Less than: `<`
    case lessThan(Value)

    /// Less than or equal: `<=`
    case lessThanOrEqual(Value)

    /// Greater than: `>`
    case greaterThan(Value)

    /// Greater than or equal: `>=`
    case greaterThanOrEqual(Value)

    /// Equal: `==`
    case equals(Value)
}

public enum FilterOperationSequence<Value: FilterOperationComparableType> {

    /// Contains
    case contains(Value)
}

public protocol FilterOperationKeyableType {}

public enum FilterOperationKeyable<Value: FilterOperationKeyableType> {

    /// Has ancestor.
    case hasAncestor(Value)
}

extension Query where Entity.Key: GoogleCloudDatastore.Key {

    public func `where`<Value>(_ key: ReferenceWritableKeyPath<Entity, Value>, _ operation: FilterOperationComparable<Value>) -> Query where Value: PropertyValue {
        var query = self
        query.filters.append(.with {
            $0.property = .with {
                $0.name = rawKey(key: key)
            }
            switch operation {
            case .lessThan(let value):
                $0.op = .lessThan
                $0.value = .with { $0.valueType = (value._gcdValue() as! Google_Datastore_V1_Value.OneOf_ValueType) }

            case .lessThanOrEqual(let value):
                $0.op = .lessThanOrEqual
                $0.value = .with { $0.valueType = (value._gcdValue() as! Google_Datastore_V1_Value.OneOf_ValueType) }

            case .greaterThan(let value):
                $0.op = .greaterThan
                $0.value = .with { $0.valueType = (value._gcdValue() as! Google_Datastore_V1_Value.OneOf_ValueType) }

            case .greaterThanOrEqual(let value):
                $0.op = .greaterThanOrEqual
                $0.value = .with { $0.valueType = (value._gcdValue() as! Google_Datastore_V1_Value.OneOf_ValueType) }

            case .equals(let value):
                $0.op = .equal
                $0.value = .with { $0.valueType = (value._gcdValue() as! Google_Datastore_V1_Value.OneOf_ValueType) }
            }
        })
        return query
    }

    public func `where`<Value>(_ key: ReferenceWritableKeyPath<Entity, [Value]>, _ operation: FilterOperationSequence<Value>) -> Query where Value: PropertyValue {
        var query = self
        query.filters.append(.with {
            $0.property = .with {
                $0.name = rawKey(key: key)
            }
            switch operation {
            case .contains(let value):
                $0.op = .equal
                $0.value = .with { $0.valueType = (value._gcdValue() as! Google_Datastore_V1_Value.OneOf_ValueType) }
            }
        })
        return query
    }

    public func `where`<Value>(_ key: ReferenceWritableKeyPath<Entity, Value>, _ operation: FilterOperationKeyable<Value>) -> Query where Value: Key {
        var query = self
        query.filters.append(.with {
            $0.property = .with {
                $0.name = rawKey(key: key)
            }
            switch operation {
            case .hasAncestor(let key):
                $0.op = .hasAncestor
                $0.value = .with { $0.valueType = (key._gcdValue() as! Google_Datastore_V1_Value.OneOf_ValueType) }
            }
        })
        return query
    }
}

// MARK: - Order

extension Query where Entity.Key: GoogleCloudDatastore.Key {

    public func sort<Value>(_ key: ReferenceWritableKeyPath<Entity, Value>, direction: OrderDirection) -> Query where Value: PropertyValue {
        var query = self
        query.orders.append(Google_Datastore_V1_PropertyOrder.with {
            $0.property = .with {
                $0.name = rawKey(key: key)
            }
            switch direction {
            case .ascending: $0.direction = .ascending
            case .descending: $0.direction = .descending
            }
        })
        return query
    }
}

// MARK: - Execution

extension Query where Entity.Key: GoogleCloudDatastore.Key {

    public func getAll(limit: Int32? = nil) -> EventLoopFuture<[Entity]> {
        let request = Google_Datastore_V1_RunQueryRequest.with {
            $0.projectID = client.datastore.projectID
            $0.partitionID = .with {
                $0.namespaceID = namespace.rawValue
            }
            $0.queryType = .query(.with {
                $0.projection = [] // TODO: Implement projection
                $0.kind = [.with {
                    $0.name = Entity.Key.kind
                }]
                if !filters.isEmpty {
                    $0.filter = .with {
                        $0.filterType = .compositeFilter(.with {
                            $0.op = .and
                            $0.filters = filters.map { filter in
                                Google_Datastore_V1_Filter.with {
                                    $0.propertyFilter = filter
                                }
                            }
                        })
                    }
                }
                $0.order = orders
                $0.distinctOn = [] // TODO: Implement distinct on
//                $0.startCursor = // TODO: Implement cursor support
//                $0.endCursor =
//                $0.offset =
                if let limit = limit {
                    $0.limit = .with {
                        $0.value = limit
                    }
                }
            })
        }

        return client.datastore.raw
            .runQuery(request)
            .response
            .hop(to: client.eventLoop)
            .flatMapThrowing {
                try $0.batch.entityResults.map { try Entity.init(raw: $0.entity) }
            }
    }

    public func get() -> EventLoopFuture<Entity?>  {
        getAll(limit: 1).map { $0.first }
    }
}
