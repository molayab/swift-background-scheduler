import Foundation

/// Errors that can occur when accessing a ``SharedResource``.
public enum SharedResourceError: Swift.Error {
    /// Indicates that the requested resource was not found.
    case notFound
}

/// A simple actor-backed container for safely sharing a mutable value across tasks.
///
/// Use this to serialize access to a resource that needs to be read or replaced from multiple tasks.
public actor SharedResource<Resource: Sendable> {
    private var resource: Resource?

    /// Creates a new shared resource with an optional initial value.
    public init(resource: Resource? = nil) {
        self.resource = resource
    }

    /// Grants serialized access to the underlying resource for in-place mutation.
    public func access<T>(_ block: (inout Resource?) -> T) -> T {
        block(&resource)
    }
    
    /// Replaces the resource with a new value.
    public func override(_ newResource: Resource) {
        resource = newResource
    }
    
    /// Clears the resource, leaving it unset.
    public func clear() {
        resource = nil
    }
    
    /// Reads the resource or throws if it is unavailable.
    ///
    /// - Parameter defaultValue: Optional value to return when the resource is unset.
    /// - Throws: ``SharedResourceError/notFound`` when the resource is unset and no default is provided.
    public func read(
        defaultValue: Resource? = nil
    ) throws(SharedResourceError) -> Resource {
        if let resource {
            return resource
        } else if let defaultValue {
            return defaultValue
        } else {
            throw .notFound
        }
    }
}
