import Foundation

/// A protocol representing a task that can be executed asynchronously.
///
/// Conforming types must implement the `execute` method, which is called to run the task.
/// Keep task implementations lightweight to avoid blocking the scheduler. The OS may impose
/// time limits on task execution. When the time limit is exceeded, the task will be terminated and
/// not retried.
///
/// This tasks are often called using a background priority and take the minor priority when competing
/// with other system tasks.
///
/// # Usage Example
/// ```swift
/// struct MyTask: ExecutableTask {
///    func execute() async throws {
///       // Task implementation here
///    }
/// }
/// ```
public protocol ExecutableTask: Sendable {
    func execute() async throws
}
