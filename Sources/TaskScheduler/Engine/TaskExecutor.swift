import Foundation

/// Represents the runtime state of a task executor.
public enum TaskExecutorState: Sendable {
    case idle
    case running
    case paused
}

/// A test-friendly interface for driving task execution.
public protocol TaskExecutorInterface: Sendable {
    /// The task scheduler used by the executor.
    var taskScheduler: TaskScheduler { get }
    
    /// Executes the next scheduled task, if any.
    func justNext() async throws
    
    /// Starts a background loop that reacts to signals and runs tasks.
    func runContinuously() -> Task<Void, Never>
    
    /// Sets the executor to running and returns the background task.
    @discardableResult
    func resume() async -> Task<Void, Never>
    
    /// Resumes execution and awaits the background task.
    func resumeAndWait() async
    
    /// Pauses execution.
    func pause() async
}

/// Executes scheduled tasks using a provided TaskScheduler.
///
/// This class provides methods to execute tasks either one at a time or continuously in the background.
/// It allows for flexible task execution based on external triggers or ongoing processing needs.
public final class TaskExecutor: Sendable, TaskExecutorInterface {
    public let taskScheduler: TaskScheduler
    private let state = SharedResource<TaskExecutorState>(resource: .idle)
    private let taskSignal: TaskExecutorSignal?
    
    public init(
        taskScheduler: TaskScheduler,
        taskSignal: TaskExecutorSignal? = nil
    ) {
        self.taskScheduler = taskScheduler
        self.taskSignal = taskSignal
    }

    /// Executes the next scheduled task.
    ///
    /// This method is useful to run task based on external triggers, like user actions or system events.
    /// It will execute one task from the scheduler's queue.
    public func justNext() async throws {
        try await taskScheduler.runNext()
    }
    
    /// Continuously runs scheduled tasks in the background.
    ///
    /// This method starts an infinite loop that continuously checks for and executes scheduled tasks.
    /// It is designed to run in a background task to avoid blocking the main thread.
    public func runContinuously() -> Task<Void, Never> {
        let scheduler = taskScheduler
        let executorState = state
        
        let task = Task(priority: .background) {
            do {
                guard let taskSignal else { return }
                for await _ in taskSignal.stream() {
                    if try await executorState.read() != .running { break }
                    do {
                        try await scheduler.runNext()
                    } catch {
                        print("Error executing task: \(error). Continuing execution.")
                    }
                }
            } catch SharedResourceError.notFound {
                print("TaskExecutor state not found. Stopping execution.")
            } catch {
                print("Unexpected error: \(error). Stopping execution.")
            }
        }
        return task
    }
    
    /// Resumes task execution.
    ///
    /// This method sets the executor's state to running and starts continuous task execution.
    /// - Returns: A Task that represents the continuous execution of tasks.
    @discardableResult
    public func resume() async -> Task<Void, Never> {
        await state.override(.running)
        return runContinuously()
    }
    
    /// Resumes task execution and waits for it to complete.
    public func resumeAndWait() async {
        let task = await resume()
        await task.value
    }
    
    /// Pauses task execution.
    public func pause() async {
        await state.override(.paused)
    }
}
