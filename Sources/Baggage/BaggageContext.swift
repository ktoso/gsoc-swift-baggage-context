//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Baggage Context open source project
//
// Copyright (c) 2020 Moritz Lang and the Swift Baggage Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A `BaggageContext` is a heterogeneous storage type with value semantics for keyed values in a type-safe
/// fashion. Its values are uniquely identified via `BaggageContextKey`s. These keys also dictate the type of
/// value allowed for a specific key-value pair through their associated type `Value`.
///
/// ## Subscript access
/// You may access the stored values by subscripting with a key type conforming to `BaggageContextKey`.
///
///     enum TestIDKey: BaggageContextKey {
///       typealias Value = String
///     }
///
///     var baggage = BaggageContext()
///     // set a new value
///     baggage[TestIDKey.self] = "abc"
///     // retrieve a stored value
///     baggage[TestIDKey.self] ?? "default"
///     // remove a stored value
///     baggage[TestIDKey.self] = nil
///
/// ## Convenience extensions
///
/// Libraries may also want to provide an extension, offering the values that users are expected to reach for
/// using the following pattern:
///
///     extension BaggageContextProtocol {
///       var testID: TestIDKey.Value {
///         get {
///           self[TestIDKey.self]
///         } set {
///           self[TestIDKey.self] = newValue
///         }
///       }
///     }
public struct BaggageContext: BaggageContextProtocol {
    private var _storage = [AnyBaggageContextKey: ValueContainer]()

    /// Create an empty `BaggageContext`.
    public init() {}

    public subscript<Key: BaggageContextKey>(_ key: Key.Type) -> Key.Value? {
        get {
            return self._storage[AnyBaggageContextKey(key)]?.forceUnwrap(key)
        } set {
            self._storage[AnyBaggageContextKey(key)] = newValue.map {
                ValueContainer(value: $0)
            }
        }
    }

    public func forEach(_ callback: (AnyBaggageContextKey, Any) -> Void) {
        self._storage.forEach { key, container in
            callback(key, container.value)
        }
    }

    private struct ValueContainer {
        let value: Any

        func forceUnwrap<Key: BaggageContextKey>(_ key: Key.Type) -> Key.Value {
            return self.value as! Key.Value
        }
    }
}

extension BaggageContext: CustomStringConvertible {
    public var description: String {
        return "\(type(of: self).self)(keys: \(self._storage.map { $0.key.name }))"
    }
}

public protocol BaggageContextProtocol {
    /// Provides type-safe access to the baggage's values.
    ///
    /// Rather than using this subscript directly, users are encouraged to offer a convenience accessor to their values,
    /// using the following pattern:
    ///
    ///     extension BaggageContextProtocol {
    ///       var testID: TestIDKey.Value {
    ///         get {
    ///           self[TestIDKey.self]
    ///         } set {
    ///           self[TestIDKey.self] = newValue
    ///         }
    ///       }
    ///     }
    subscript<Key: BaggageContextKey>(_ key: Key.Type) -> Key.Value? { get set }

    /// Iterates over the baggage context's contents invoking the callback one-by one.
    ///
    /// - Parameter callback: invoked with the type erased key and value stored for the key in this baggage.
    func forEach(_ callback: (AnyBaggageContextKey, Any) -> Void)
}

// ==== ------------------------------------------------------------------------
// MARK: Baggage keys

/// `BaggageContextKey`s are used as keys in a `BaggageContext`. Their associated type `Value` gurantees type-safety.
/// To give your `BaggageContextKey` an explicit name you may override the `name` property.
public protocol BaggageContextKey {
    /// The type of `Value` uniquely identified by this key.
    associatedtype Value

    /// The human-readable name of this key. Defaults to `nil`.
    static var name: String? { get }
}

extension BaggageContextKey {
    public static var name: String? { return nil }
}

public struct AnyBaggageContextKey {
    public let keyType: Any.Type

    private let _name: String?

    /// A human-readable String representation of the underlying key.
    /// If no explicit name has been set on the wrapped key the type name is used.
    public var name: String {
        return self._name ?? String(describing: self.keyType.self)
    }

    public init<Key>(_ keyType: Key.Type) where Key: BaggageContextKey {
        self.keyType = keyType
        self._name = keyType.name
    }
}

extension AnyBaggageContextKey: Hashable {
    public static func == (lhs: AnyBaggageContextKey, rhs: AnyBaggageContextKey) -> Bool {
        return ObjectIdentifier(lhs.keyType) == ObjectIdentifier(rhs.keyType)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.keyType))
    }
}
