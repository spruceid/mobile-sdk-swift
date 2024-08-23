// GenericJSON implementation based on https://github.com/iwill/generic-json-swift
import Foundation

public enum GenericJSON {
    case string(String)
    case number(Double)
    case object([String:GenericJSON])
    case array([GenericJSON])
    case bool(Bool)
    case null
}

extension GenericJSON: Codable {
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case let .array(array):
            try c.encode(array)
        case let .object(object):
            try c.encode(object)
        case let .string(string):
            try c.encode(string)
        case let .number(number):
            try c.encode(number)
        case let .bool(bool):
            try c.encode(bool)
        case .null:
            try c.encodeNil()
        }
    }
    
    public func toString() -> String {
        switch self {
        case .string(let str):
            return str
        case .number(let num):
            return num.debugDescription
        case .bool(let bool):
            return bool.description
        case .null:
            return "null"
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            return try! String(data: encoder.encode(self), encoding: .utf8)!
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let object = try? c.decode([String: GenericJSON].self) {
            self = .object(object)
        } else if let array = try? c.decode([GenericJSON].self) {
            self = .array(array)
        } else if let string = try? c.decode(String.self) {
            self = .string(string)
        } else if let bool = try? c.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? c.decode(Double.self) {
            self = .number(number)
        } else if c.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
            )
        }
    }
}

extension GenericJSON: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .string(let str):
            return str.debugDescription
        case .number(let num):
            return num.debugDescription
        case .bool(let bool):
            return bool.description
        case .null:
            return "null"
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            return try! String(data: encoder.encode(self), encoding: .utf8)!
        }
    }
}

public extension GenericJSON {
    var dictValue: [String: GenericJSON]? {
        if case .object(let value) = self {
            return value
        }
        return nil
    }
    var arrayValue: [GenericJSON]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }
    subscript(index: Int) -> GenericJSON? {
        if case .array(let arr) = self, arr.indices.contains(index) {
            return arr[index]
        }
        return nil
    }

    subscript(key: String) -> GenericJSON? {
        if case .object(let dict) = self {
            return dict[key]
        }
        return nil
    }
    
    subscript(dynamicMember member: String) -> GenericJSON? {
        return self[member]
    }

    subscript(keyPath keyPath: String) -> GenericJSON? {
        return queryKeyPath(keyPath.components(separatedBy: "."))
    }
    
    func queryKeyPath<T>(_ path: T) -> GenericJSON? where T: Collection, T.Element == String {
        guard case .object(let object) = self else {
            return nil
        }
        guard let head = path.first else {
            return nil
        }
        guard let value = object[head] else {
            return nil
        }
        let tail = path.dropFirst()
        return tail.isEmpty ? value : value.queryKeyPath(tail)
    }
    
}
