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

/// `BaggageKey`s are used as keys in a `Baggage`. Their associated type `Value` guarantees type-safety.
/// To give your `BaggageKey` an explicit name you may override the `name` property.
///
/// In general, `BaggageKey`s should be `internal` or `private` to the part of a system using it.
///
/// All access to baggage items should be performed through an accessor computed property defined as shown below:
///
///     /// The Key type should be internal (or private).
///     enum TestIDKey: Baggage.Key {
///         typealias Value = String
///         static var nameOverride: String? { "test-id" }
///     }
///
///     extension Baggage {
///         /// This is some useful property documentation.
///         public internal(set) var testID: String? {
///             get {
///                 self[TestIDKey.self]
///             }
///             set {
///                 self[TestIDKey.self] = newValue
///             }
///         }
///     }
///
/// This pattern allows library authors fine-grained control over which values may be set, and which only get by end-users.
public protocol BaggageKey {
    /// The type of `Value` uniquely identified by this key.
    associatedtype Value

    /// Configures the policy related to values stored using this key.
    ///
    /// This can be used to ensure that a value should never be logged automatically by a logger associated to a context.
    ///
    /// Summary:
    /// - `public` - items are accessible by other modules via `baggage.forEach` and direct key lookup,
    ///    and will be logged by the `DefaultContext` `logger.
    /// - `publicExceptLogging` - items are accessible by other modules via `baggage.forEach` and direct key lookup,
    ///    however will NOT be logged by the `DefaultContext` `logger.
    /// - `private` - items are NOT accessible by other modules via `baggage.forEach` nor are they logged by default.
    ///    The only way to gain access to a private baggage item is through it's key or accessor, which means that
    ///    access is controlled using Swift's native access control mechanism, i.e. a `private`/`internal` `Key` and `set` accessor,
    ///    will result in a baggage item that may only be set by the owning module, but read by anyone via the (`public`) accessor.
    static var access: BaggageAccessPolicy { get }

    /// The human-readable name of this key.
    /// This name will be used instead of the type name when a value is printed.
    ///
    /// It MAY also be picked up by an instrument (from Swift Tracing) which serializes baggage items and e.g. used as
    /// header name for carried metadata. Though generally speaking header names are NOT required to use the nameOverride,
    /// and MAY use their well known names for header names etc, as it depends on the specific transport and instrument used.
    ///
    /// For example, a baggage key representing the W3C "trace-state" header may want to return "trace-state" here,
    /// in order to achieve a consistent look and feel of this baggage item throughout logging and tracing systems.
    ///
    /// Defaults to `nil`.
    static var nameOverride: String? { get }
}

extension BaggageKey {
    public static var nameOverride: String? { return nil }
}

/// Configures the policy related to values stored using this key.
///
/// This can be used to ensure that a value should never be logged automatically by a logger associated to a context.
///
/// Summary:
/// - `public` - items are accessible by other modules via `baggage.forEach` and direct key lookup,
///    and will be logged by the `DefaultContext` `logger.
/// - `publicExceptLogging` - items are accessible by other modules via `baggage.forEach` and direct key lookup,
///    however will NOT be logged by the `DefaultContext` `logger.
/// - `private` - items are NOT accessible by other modules via `baggage.forEach` nor are they logged by default.
///    The only way to gain access to a private baggage item is through it's key or accessor, which means that
///    access is controlled using Swift's native access control mechanism, i.e. a `private`/`internal` `Key` and `set` accessor,
///    will result in a baggage item that may only be set by the owning module, but read by anyone via the (`public`) accessor.
public enum BaggageAccessPolicy: Hashable {
    /// Access to this baggage item is NOT restricted.
    /// This baggage item will be listed when `baggage.forEach` is invoked, and thus modules other than the defining
    /// module may gain access to it and potentially log or pass it to other parts of the system.
    ///
    /// Note that this can happen regardless of the key being declared private or internal.
    ///
    /// ### Example
    /// When module `A` defines `AKey` and keeps it `private`, any other module still may call `baggage.forEach`
    case `public`

    /// Access to this baggage item is NOT restricted, however the `DefaultContext` (and any other well-behaved context)
    /// MUST NOT log this baggage item.
    ///
    /// This policy can be useful if some user sensitive value must be carried in baggage context, however it should never
    /// appear in log statements. While usually such items should not be put into baggage, we offer this mode as a way of
    /// threading through a system values which should not be logged nor pollute log statements.
    case publicExceptLogging

    /// Access to this baggage item is RESTRICTED and can only be performed by a direct subscript lookup into the baggage.
    ///
    /// This effectively restricts the access to the baggage item, to any party which has access to the associated
    /// `BaggageKey`. E.g. if the baggage key is defined internal or private, and the `set` accessor is also internal or
    /// private, no other module would be able to modify this baggage once it was set on a baggage context.
    case `private`
}

/// A type-erased `BaggageKey` used when iterating through the `Baggage` using its `forEach` method.
public struct AnyBaggageKey {
    /// The key's type represented erased to an `Any.Type`.
    let keyType: Any.Type

    /// A human-readable String representation of the underlying key.
    /// If no explicit name has been set on the wrapped key the type name is used.
    public var name: String {
        return self._nameOverride ?? String(describing: self.keyType.self)
    }

    private let _nameOverride: String?

    public let access: BaggageAccessPolicy

    init<Key>(_ keyType: Key.Type) where Key: BaggageKey {
        self.keyType = keyType
        self._nameOverride = keyType.nameOverride
        self.access = keyType.access
    }
}

extension AnyBaggageKey: Hashable {
    public static func == (lhs: AnyBaggageKey, rhs: AnyBaggageKey) -> Bool {
        return ObjectIdentifier(lhs.keyType) == ObjectIdentifier(rhs.keyType)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.keyType))
    }
}

extension AnyBaggageKey: CustomStringConvertible {
    public var description: String {
        return "AnyBaggageKey(\(self.name), access: \(self.access))"
    }
}
