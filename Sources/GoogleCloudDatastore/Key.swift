public protocol Key: Equatable, PropertyValue {

    associatedtype Parent

    static var kind: String { get }
    var id: ID { get }
    var parent: Parent { get }
    var namespace: Namespace { get }

    init(id: ID, parent: Parent, namespace: Namespace)

    init(rawElements: inout [_RawKeyElement], namespace: Namespace)
    func _makeRaw(elements: inout [_RawKeyElement])
}

public protocol _RawKeyElement {}
extension Google_Datastore_V1_Key.PathElement: _RawKeyElement {}

// MARK: - Convenience

extension Key where Parent == Void {

    public init(id: ID, namespace: Namespace = .default) {
        self.init(id: id, parent: (), namespace: namespace)
    }
}

extension Key where Parent: Key {

    public init(id: ID, parent: Parent) {
        self.init(id: id, parent: parent, namespace: .default)
    }
}

// MARK: - Equatable

extension Key where Parent == Void {

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.namespace == rhs.namespace
    }
}

// MARK: - gRPC Encoding

extension Key {

    init(raw: Google_Datastore_V1_Key) {
        var elements: [_RawKeyElement] = raw.path
        self.init(rawElements: &elements, namespace: Namespace(rawValue: raw.partitionID.namespaceID))
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public func _gcdValue() -> _RawPropertyValue {
        Google_Datastore_V1_Value.OneOf_ValueType.keyValue(raw)
    }
}

extension Key where Parent == Void {

    public init(rawElements: inout [_RawKeyElement], namespace: Namespace) {
        let element = rawElements[0] as! Google_Datastore_V1_Key.PathElement

        self.init(
            id: ID(raw: element.idType),
            parent: (),
            namespace: namespace
        )
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public static var emptyPropertyValue: Self {
        Self.init(id: .incomplete, parent: (), namespace: .default)
    }
}

extension Key where Parent: Key {

    public init(rawElements: inout [_RawKeyElement], namespace: Namespace) {
        let element = rawElements.removeLast() as! Google_Datastore_V1_Key.PathElement

        self.init(
            id: ID(raw: element.idType),
            parent: Parent.init(rawElements: &rawElements, namespace: namespace),
            namespace: namespace
        )
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public static var emptyPropertyValue: Self {
        Self.init(id: .incomplete, parent: Parent.emptyPropertyValue, namespace: .default)
    }
}

// MARK: - gRPC Decoding

extension Key {

    fileprivate var rawElement: Google_Datastore_V1_Key.PathElement {
        Google_Datastore_V1_Key.PathElement.with {
            $0.kind = Self.kind
            $0.idType = id.raw
        }
    }

    var raw: Google_Datastore_V1_Key {
        var pathElements = [_RawKeyElement]()
        _makeRaw(elements: &pathElements)

        return Google_Datastore_V1_Key.with {
            $0.path = pathElements as! [Google_Datastore_V1_Key.PathElement]
            $0.partitionID = Google_Datastore_V1_PartitionId.with {
                $0.namespaceID = namespace.rawValue
            }
        }
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    init(_gcdValue: _RawPropertyValue) throws {
        switch (_gcdValue as! Google_Datastore_V1_Value.OneOf_ValueType) {
        case .keyValue(let key):
            self.init(raw: key)
        default:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        }
    }
}

extension Key where Parent == Void {

    public func _makeRaw(elements: inout [_RawKeyElement]) {
        elements.insert(rawElement, at: 0)
    }
}

extension Key where Parent: Key {

    public func _makeRaw(elements: inout [_RawKeyElement]) {
        elements.insert(rawElement, at: 0)
        parent._makeRaw(elements: &elements)
    }
}

// MARK: - CustomDebugStringConvertible

extension Key where Parent == Void {

    public var debugDescription: String {
        "/\(namespace.rawValue):\(Self.kind):\(id)"
    }
}

extension Key where Parent: Key {

    public var debugDescription: String {
        "\(parent.debugDescription)\(Self.kind)"
    }
}
