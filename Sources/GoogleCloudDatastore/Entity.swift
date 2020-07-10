public protocol Entity: class, CustomDebugStringConvertible {

    associatedtype Key

    var key: Key { get set }

    init(key: Key)

    init(raw: _RawEntity) throws
    var raw: _RawEntity { get }
}

public protocol _RawEntity {}
extension Google_Datastore_V1_Entity: _RawEntity {}

// MARK: - Convenience

extension Entity where Key: GoogleCloudDatastore.Key, Key.Parent == Void {

    public init(id: ID = .incomplete, namespace: Namespace = .default) {
        self.init(key: Key.init(id: id, parent: (), namespace: namespace))
    }
}

extension Entity where Key: GoogleCloudDatastore.Key, Key.Parent: GoogleCloudDatastore.Key {

    public init(id: ID = .incomplete, parent: Key.Parent, namespace: Namespace = .default) {
        self.init(key: Key.init(id: id, parent: parent, namespace: namespace))
    }
}

// MARK: - gRPC Encoding

extension Entity where Key: GoogleCloudDatastore.Key {

    public var raw: _RawEntity {
        var properties = [String: Google_Datastore_V1_Value]()

        for child in Mirror(reflecting: self).children {
            guard let property = child.value as? PropertyWrapperType
                else { continue }

            properties[property.key] = property.value()
        }

        return Google_Datastore_V1_Entity.with {
            $0.key = key.raw
            $0.properties = properties
        }
    }
}

// MARK: - gRPC Decoding

extension Entity where Key: GoogleCloudDatastore.Key {

    public init(raw: _RawEntity) throws {
        let raw = raw as! Google_Datastore_V1_Entity

        self.init(key: Key.init(raw: raw.key))

        for child in Mirror(reflecting: self).children {
            guard let valueSetter = child.value as? PropertyWrapperType
                else { continue }

            guard let property = raw.properties[valueSetter.key]
                else { continue }

            try valueSetter.set(newValue: property)
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension Entity {

    public var debugDescription: String {
        var result = "\(type(of: self))("

        for child in Mirror(reflecting: self).children {
            let label = child.label ?? "?"
            if let wrapper = child.value as? PropertyWrapperType {
                result += "\(label.dropFirst()): \(wrapper.debugDescription), "
            } else {
                result += "\(label): \(child.value), "
            }
        }

        return result.dropLast(2) + ")"
    }
}
