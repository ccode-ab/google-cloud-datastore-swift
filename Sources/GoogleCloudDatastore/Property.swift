import Foundation
import SwiftProtobuf

public enum PropertyValueDecodeError: Error {
    case invalidType(_RawPropertyValue)
    case parse(Any)
}

public protocol PropertyValue: CustomDebugStringConvertible {

    init(_gcdValue: _RawPropertyValue) throws
    func _gcdValue() -> _RawPropertyValue

    static var emptyPropertyValue: Self { get }
}

public protocol _RawPropertyValue {}
extension Google_Datastore_V1_Value.OneOf_ValueType: _RawPropertyValue {}

protocol PropertyWrapperType: class, CustomDebugStringConvertible {

    var key: String { get }

    func set(newValue: Google_Datastore_V1_Value) throws
    func value() -> Google_Datastore_V1_Value
}

@propertyWrapper
public class Property<Element: PropertyValue>: PropertyWrapperType, CustomDebugStringConvertible {

    let key: String
    let excludeFromIndexes: Bool

    public var wrappedValue: Element

    public init(key: String, excludeFromIndexes: Bool = false, defaultValue: Element = .emptyPropertyValue) {
        self.key = key
        self.excludeFromIndexes = excludeFromIndexes
        self.wrappedValue = defaultValue
    }

    // MARK: - gRPC Encoding

    func value() -> Google_Datastore_V1_Value {
        Google_Datastore_V1_Value.with {
            $0.valueType = (wrappedValue._gcdValue() as! Google_Datastore_V1_Value.OneOf_ValueType)
        }
    }

    // MARK: - gRPC Decoding

    func set(newValue: Google_Datastore_V1_Value) throws {
        guard let valueType = newValue.valueType
            else { return }

        wrappedValue = try type(of: wrappedValue).init(_gcdValue: valueType)
    }
}

// MARK: - CustomDebugStringConvertible

extension Property {

    public var debugDescription: String {
        wrappedValue.debugDescription
    }
}

// MARK: - Extension for supported types

extension Optional: PropertyValue where Wrapped: PropertyValue {

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public static var emptyPropertyValue: Wrapped? {
        nil
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public func _gcdValue() -> _RawPropertyValue {
        switch self {
        case .none:
            return Google_Datastore_V1_Value.OneOf_ValueType.nullValue(.nullValue)
        case .some(let value):
            return value._gcdValue()
        }
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public init(_gcdValue: _RawPropertyValue) throws {
        switch _gcdValue as! Google_Datastore_V1_Value.OneOf_ValueType {
        case .nullValue:
            self = .none
        default:
            self = .some(try Wrapped.init(_gcdValue: _gcdValue))
        }
    }
}

extension Array: PropertyValue where Element: PropertyValue {

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public static var emptyPropertyValue: [Element] {
        []
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public func _gcdValue() -> _RawPropertyValue {
        Google_Datastore_V1_Value.OneOf_ValueType.arrayValue(Google_Datastore_V1_ArrayValue.with {
            $0.values = map { value in
                Google_Datastore_V1_Value.with {
                    $0.valueType = (value._gcdValue() as! Google_Datastore_V1_Value.OneOf_ValueType)
                }
            }
        })
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public init(_gcdValue: _RawPropertyValue) throws {
        switch _gcdValue as! Google_Datastore_V1_Value.OneOf_ValueType {
        case .nullValue:
            self = []
        case .arrayValue(let array):
            self = try array.values.map { try Element.init(_gcdValue: $0.valueType!) }
        default:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        }
    }
}

extension Bool: PropertyValue {

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public static var emptyPropertyValue: Bool {
        false
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public func _gcdValue() -> _RawPropertyValue {
        Google_Datastore_V1_Value.OneOf_ValueType.booleanValue(self)
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public init(_gcdValue: _RawPropertyValue) throws {
        switch _gcdValue as! Google_Datastore_V1_Value.OneOf_ValueType {
        case .nullValue:
            self = false
        case .booleanValue(let boolean):
            self = boolean
        case .integerValue(let integer):
            self = integer > 0
        case .doubleValue(let double):
            self = double > 0
        case .stringValue(let string):
            self = string != "" && string != "0" && string != "false" && string != "FALSE" && string != "False"
        case .timestampValue(let value):
            self = value.seconds > 0
        case .keyValue:
            self = true
        case .arrayValue(let array):
            self = !array.values.isEmpty
        case .blobValue:
            fatalError("blobValue for Int64 has not been implemented yet")
        case .entityValue:
            self = true
        case .geoPointValue:
            self = true
        }
    }

    public var debugDescription: String {
        self ? "true" : "false"
    }
}

extension Int64: PropertyValue {

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public static var emptyPropertyValue: Int64 {
        0
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public func _gcdValue() -> _RawPropertyValue {
        Google_Datastore_V1_Value.OneOf_ValueType.integerValue(self)
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public init(_gcdValue: _RawPropertyValue) throws {
        switch _gcdValue as! Google_Datastore_V1_Value.OneOf_ValueType {
        case .nullValue:
            self = 0
        case .booleanValue(let boolean):
            self = boolean ? 1 : 0
        case .integerValue(let integer):
            self = integer
        case .doubleValue(let double):
            self = Int64(double)
        case .stringValue(let string):
            if let parsed = Int64(string) {
                self = parsed
            } else {
                throw PropertyValueDecodeError.parse(string)
            }
        case .timestampValue(let value):
            self = value.seconds
        case .keyValue(let key):
            self = key.path.last!.id
        case .arrayValue(let array):
            self = Int64(array.values.count)
        case .blobValue:
            fatalError("blobValue for Int64 has not been implemented yet")
        case .entityValue:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        case .geoPointValue:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        }
    }

    public var debugDescription: String {
        String(self)
    }
}

extension Double: PropertyValue {

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public static var emptyPropertyValue: Double {
        0
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public func _gcdValue() -> _RawPropertyValue {
        Google_Datastore_V1_Value.OneOf_ValueType.doubleValue(self)
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public init(_gcdValue: _RawPropertyValue) throws {
        switch _gcdValue as! Google_Datastore_V1_Value.OneOf_ValueType {
        case .nullValue:
            self = 0
        case .booleanValue(let boolean):
            self = boolean ? 1 : 0
        case .integerValue(let integer):
            self = Double(integer)
        case .doubleValue(let double):
            self = double
        case .stringValue(let string):
            if let parsed = Double(string) {
                self = parsed
            } else {
                throw PropertyValueDecodeError.parse(string)
            }
        case .timestampValue(let value):
            self = value.date.timeIntervalSince1970
        case .keyValue(let key):
            self = Double(key.path.last!.id)
        case .arrayValue(let array):
            self = Double(array.values.count)
        case .blobValue:
            fatalError("blobValue for Int64 has not been implemented yet")
        case .entityValue:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        case .geoPointValue:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        }
    }
}

extension String: PropertyValue {

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public static var emptyPropertyValue: String {
        ""
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public func _gcdValue() -> _RawPropertyValue {
        Google_Datastore_V1_Value.OneOf_ValueType.stringValue(self)
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public init(_gcdValue: _RawPropertyValue) throws {
        switch _gcdValue as! Google_Datastore_V1_Value.OneOf_ValueType {
        case .nullValue:
            self = ""
        case .booleanValue(let boolean):
            self = boolean ? "true" : "false"
        case .integerValue(let integer):
            self = String(integer)
        case .doubleValue(let double):
            self = String(double)
        case .stringValue(let string):
            self = string
        case .timestampValue(let value):
            self = String(value.date.timeIntervalSince1970)
        case .keyValue(let key):
            self = "\(key)"
        case .arrayValue(let array):
            self = "\(array)"
        case .blobValue(let data):
            self = "\(data)"
        case .entityValue(let entity):
            self = "\(entity)"
        case .geoPointValue(let geoPoint):
            self = "\(geoPoint.latitude):\(geoPoint.longitude)"
        }
    }
}

extension Date: PropertyValue {

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public static var emptyPropertyValue: Date {
        Date(timeIntervalSince1970: 0)
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public func _gcdValue() -> _RawPropertyValue {
        Google_Datastore_V1_Value.OneOf_ValueType.timestampValue(Google_Protobuf_Timestamp(date: self))
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public init(_gcdValue: _RawPropertyValue) throws {
        switch _gcdValue as! Google_Datastore_V1_Value.OneOf_ValueType {
        case .nullValue:
            self = Date(timeIntervalSince1970: 0)
        case .booleanValue:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        case .integerValue(let integer):
            self = Date(timeIntervalSince1970: TimeInterval(integer))
        case .doubleValue(let double):
            self = Date(timeIntervalSince1970: double)
        case .stringValue(let string):
            if let parsed = Double(string) {
                self = Date(timeIntervalSince1970: parsed)
            } else {
                throw PropertyValueDecodeError.parse(string)
            }
        case .timestampValue(let value):
            self = value.date
        case .keyValue:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        case .arrayValue:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        case .blobValue:
            fatalError("blobValue for Int64 has not been implemented yet")
        case .entityValue:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        case .geoPointValue:
            throw PropertyValueDecodeError.invalidType(_gcdValue)
        }
    }
}

extension Data: PropertyValue {

    public static var emptyPropertyValue: Data {
        Data()
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public func _gcdValue() -> _RawPropertyValue {
        Google_Datastore_V1_Value.OneOf_ValueType.blobValue(self)
    }

    /// Default implementation of `PropertyValue`. Do not overwrite or call directly.
    public init(_gcdValue: _RawPropertyValue) throws {
        switch _gcdValue as! Google_Datastore_V1_Value.OneOf_ValueType {
        case .nullValue:
            self = Data()
        case .booleanValue:
            fatalError("booleanValue for Int64 has not been implemented yet")
        case .integerValue:
            fatalError("integerValue for Int64 has not been implemented yet")
        case .doubleValue:
            fatalError("doubleValue for Int64 has not been implemented yet")
        case .stringValue:
            fatalError("stringValue for Int64 has not been implemented yet")
        case .timestampValue:
            fatalError("timestampValue for Int64 has not been implemented yet")
        case .keyValue:
            fatalError("keyValue for Int64 has not been implemented yet")
        case .arrayValue:
            fatalError("arrayValue for Int64 has not been implemented yet")
        case .blobValue(let data):
            self = data
        case .entityValue:
            fatalError("entityValue for Int64 has not been implemented yet")
        case .geoPointValue:
            fatalError("geoPointValue for Int64 has not been implemented yet")
        }
    }
}
