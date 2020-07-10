public struct Namespace: RawRepresentable, Equatable {

    public typealias RawValue = String

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    public var rawValue: RawValue

    public static let `default` = Namespace(rawValue: "")
}
