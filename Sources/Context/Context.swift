public protocol Context {
    static var background: Context { get }
    static func TODO(_ reason: StaticString?, function: StaticString, file: StaticString, line: UInt) -> Context
    
    subscript<Key: ContextValueContainerKey>(_ key: Key.Type) -> Key.Value? { get set }
    
    func forEach(_ body: (AnyContextValueContainerKey, Any) throws -> Void) rethrows
}

// MARK: Default implementations

extension Context {
    public static var background: Context { return EmptyContext.background }
    
    public static func TODO(_ reason: StaticString?, function: StaticString, file: StaticString, line: UInt) -> Context {
        return EmptyContext.TODO(reason, function: function, file: file, line: line)
    }
    
    public subscript<Key: ContextValueContainerKey>(_ key: Key.Type) -> Key.Value? {
        get { return nil }
        set { }
    }
    
    public func forEach(_ body: (AnyContextValueContainerKey, Any) throws -> Void) rethrows { }
}

// MARK: EmptyContext base implementation

public struct EmptyContext {
    private let todo: Optional<TODOLocation>
    
    internal init(todo: TODOLocation? = nil) { self.todo = todo }
}

// MARK: EmptyContext Context conformance

extension EmptyContext: Context {
    public static var background: Context { return EmptyContext() }
    
    public static func TODO(_ reason: StaticString?, function: StaticString, file: StaticString, line: UInt) -> Context {
        let todo = _ContextValueContainer.TODO(reason, function: function, file: file, line: line)[TODOKey.self]!
        return EmptyContext(todo: todo)
    }
    
    public subscript<Key: ContextValueContainerKey>(key: Key.Type) -> Key.Value? {
        get { return nil }
        set { }
    }
    
    public func forEach(_ body: (AnyContextValueContainerKey, Any) throws -> Void) rethrows {
        guard let todo = self.todo else { return }
        try body(.init(TODOKey.self), todo)
    }
}
