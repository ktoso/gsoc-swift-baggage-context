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

/// `ContextValueContainerKey`s are used as keys in a `ContextValueContainers`. Their associated type `Value` guarantees type-safety.
/// To give your `ContextValueContainerKey` an explicit name you may override the `name` property.
///
/// In general, `ContextValueContainerKey`s should be `internal` or `private` to the part of a system using it.
///
/// All access to baggage items should be performed through an accessor computed property defined as shown below:
///
///     private enum TestIDKey: ContextValueContainer.Key {
///         typealias Value = String
///         static var name: String? { "test-id" }
///     }
///
///     extension ContextValueContainer {
///         /// This is some useful property documentation.
///         var testID: String? {
///             get {
///                 self[TestIDKey.self]
///             }
///             set {
///                 self[TestIDKey.self] = newValue
///             }
///         }
///     }
///
/// It is also generally considered appropriate to define a new protocol that conforms to `Context` that provides access to the property rather than forcing
/// access to underlying storage.
///
///     protocol LoggerContextCarrier: Context {
///         var logger: Logger { get }
///     }
public protocol ContextValueContainerKey {
    /// The type of `Value` uniquely identified by this key.
    associatedtype Value

    /// The human-readable name of this key.
    /// May be used as key during serialization of the baggage item.
    ///
    /// Defaults to `nil`.
    static var name: String? { get }
}

extension ContextValueContainerKey {
    public static var name: String? { return nil }
}

/// A type-erased `ContextValueContainerKey` used when iterating through the `ContextValueContainer` using its `forEach` method.
public struct AnyContextValueContainerKey {
    /// The key's type represented erased to an `Any.Type`.
    public let keyType: Any.Type

    private let _name: String?

    /// A human-readable String representation of the underlying key.
    /// If no explicit name has been set on the wrapped key the type name is used.
    public var name: String {
        return self._name ?? String(describing: self.keyType.self)
    }

    init<Key>(_ keyType: Key.Type) where Key: ContextValueContainerKey {
        self.keyType = keyType
        self._name = keyType.name
    }
}

extension AnyContextValueContainerKey: Hashable {
    public static func == (lhs: AnyContextValueContainerKey, rhs: AnyContextValueContainerKey) -> Bool {
        return ObjectIdentifier(lhs.keyType) == ObjectIdentifier(rhs.keyType)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.keyType))
    }
}
