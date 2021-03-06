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
///     var context = BaggageContext.background
///     // set a new value
///     context[TestIDKey.self] = "abc"
///     // retrieve a stored value
///     context[TestIDKey.self] ?? "default"
///     // remove a stored value
///     context[TestIDKey.self] = nil
///
/// ## Convenience extensions
///
/// Libraries may also want to provide an extension, offering the values that users are expected to reach for
/// using the following pattern:
///
///     extension BaggageContextProtocol {
///       var testID: TestIDKey.Value? {
///         get {
///           self[TestIDKey.self]
///         } set {
///           self[TestIDKey.self] = newValue
///         }
///       }
///     }
public struct BaggageContext: BaggageContextProtocol {
    private var _storage = [AnyBaggageContextKey: Any]()

    /// Internal on purpose, please use `TODO` or `.background` to create an "empty" context,
    /// which carries more meaning to other developers why an empty context was used.
    init() {}

    public subscript<Key: BaggageContextKey>(_ key: Key.Type) -> Key.Value? {
        get {
            guard let value = self._storage[AnyBaggageContextKey(key)] else { return nil }
            // safe to force-cast as this subscript is the only way to set a value.
            return (value as! Key.Value)
        } set {
            self._storage[AnyBaggageContextKey(key)] = newValue
        }
    }

    public func forEach(_ body: (AnyBaggageContextKey, Any) throws -> Void) rethrows {
        try self._storage.forEach { key, value in
            try body(key, value)
        }
    }
}

extension BaggageContext: CustomStringConvertible {
    /// A context's description prints only keys of the contained values.
    /// This is in order to prevent spilling a lot of detailed information of carried values accidentally.
    ///
    /// `BaggageContext`s are not intended to be printed "raw" but rather inter-operate with tracing, logging and other systems,
    /// which can use the `forEach` function providing access to its underlying values.
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
    ///       var testID: TestIDKey.Value? {
    ///         get {
    ///           self[TestIDKey.self]
    ///         } set {
    ///           self[TestIDKey.self] = newValue
    ///         }
    ///       }
    ///     }
    subscript<Key: BaggageContextKey>(_ key: Key.Type) -> Key.Value? { get set }

    /// Calls the given closure on each key/value pair in the `BaggageContext`.
    ///
    /// - Parameter body: A closure invoked with the type erased key and value stored for the key in this baggage.
    func forEach(_ body: (AnyBaggageContextKey, Any) throws -> Void) rethrows
}

// ==== ------------------------------------------------------------------------
// MARK: Baggage keys

/// `BaggageContextKey`s are used as keys in a `BaggageContext`. Their associated type `Value` guarantees type-safety.
/// To give your `BaggageContextKey` an explicit name you may override the `name` property.
///
/// In general, `BaggageContextKey`s should be `internal` to the part of a system using it. It is strongly recommended to do
/// convenience extensions on `BaggageContextProtocol`, using the keys directly is considered an anti-pattern.
///
///     extension BaggageContextProtocol {
///       var testID: TestIDKey.Value? {
///         get {
///           self[TestIDKey.self]
///         } set {
///           self[TestIDKey.self] = newValue
///         }
///       }
///     }
public protocol BaggageContextKey {
    /// The type of `Value` uniquely identified by this key.
    associatedtype Value

    /// The human-readable name of this key. Defaults to `nil`.
    static var name: String? { get }
}

extension BaggageContextKey {
    public static var name: String? { return nil }
}

/// A type-erased `BaggageContextKey` used when iterating through the `BaggageContext` using its `forEach` method.
public struct AnyBaggageContextKey {
    /// The key's type represented erased to an `Any.Type`.
    public let keyType: Any.Type

    private let _name: String?

    /// A human-readable String representation of the underlying key.
    /// If no explicit name has been set on the wrapped key the type name is used.
    public var name: String {
        return self._name ?? String(describing: self.keyType.self)
    }

    init<Key>(_ keyType: Key.Type) where Key: BaggageContextKey {
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

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Background BaggageContext

extension BaggageContextProtocol {
    /// An empty baggage context intended as the "root" or "initial" baggage context background processing tasks, or as the "root" baggage context.
    ///
    /// It is never canceled, has no values, and has no deadline.
    /// It is typically used by the main function, initialization, and tests, and as the top-level Context for incoming requests.
    ///
    /// ### Usage in frameworks and libraries
    /// This function is really only intended to be used frameworks and libraries, at the "top-level" where a request's,
    /// message's or task's processing is initiated. For example, a framework handling requests, should create an empty
    /// context when handling a request only to immediately populate it with useful trace information extracted from e.g.
    /// request headers.
    ///
    /// ### Usage in applications
    /// Application code should never have to create an empty context during the processing lifetime of any request,
    /// and only should create contexts if some processing is performed in the background - thus the naming of this property.
    ///
    /// Usually, a framework such as an HTTP server or similar "request handler" would already provide users
    /// with a context to be passed along through subsequent calls.
    ///
    /// If unsure where to obtain a context from, prefer using `.TODO("Not sure where I should get a context from here?")`,
    /// such that other developers are informed that the lack of context was not done on purpose, but rather because either
    /// not being sure where to obtain a context from, or other framework limitations -- e.g. the outer framework not being
    /// context aware just yet.
    public static var background: BaggageContext {
        return BaggageContext()
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: "TO DO" BaggageContext

extension BaggageContextProtocol {
    /// A baggage context intended as a placeholder until a real value can be passed through a function call.
    ///
    /// It should ONLY be used while prototyping or when the passing of the proper context is not yet possible,
    /// e.g. because an external library did not pass it correctly and has to be fixed before the proper context
    /// can be obtained where the TO-DO is currently used.
    ///
    /// ### Crashing on TO-DO context creation
    /// You may set the `BAGGAGE_CRASH_TODOS` variable while compiling a project in order to make calls to this function crash
    /// with a fatal error, indicating where a to-do baggage context was used. This comes in handy when wanting to ensure that
    /// a project never ends up using with code initially was written as "was lazy, did not pass context", yet the
    /// project requires context passing to be done correctly throughout the application. Similar checks can be performed
    /// at compile time easily using linters (not yet implemented), since it is always valid enough to detect a to-do context
    /// being passed as illegal and warn or error when spotted.
    ///
    /// - Parameters:
    ///   - reason: Informational reason for developers, why a placeholder context was used instead of a proper one,
    /// - Returns: Empty "to-do" baggage context which should be eventually replaced with a carried through one, or `background`.
    public static func TODO(_ reason: StaticString? = "", function: String = #function, file: String = #file, line: UInt = #line) -> BaggageContext {
        var context = BaggageContext.background
        #if BAGGAGE_CRASH_TODOS
        fatalError("BAGGAGE_CRASH_TODOS: at \(file):\(line) (function \(function)), reason: \(reason)")
        #else
        context[TODOKey.self] = .init(file: file, line: line)
        return context
        #endif
    }
}

internal enum TODOKey: BaggageContextKey {
    typealias Value = TODOLocation
    static var name: String? {
        return "todo"
    }
}

/// Carried automatically by a "to do" baggage context.
/// It can be used to track where a context originated and which "to do" context must be fixed into a real one to avoid this.
public struct TODOLocation {
    let file: String
    let line: UInt
}
