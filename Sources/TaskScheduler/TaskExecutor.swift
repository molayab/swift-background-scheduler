import Foundation

public enum TaskExecutorState: Sendable {
    case idle
    case running
    case paused
}

enum SharedResourceError: Swift.Error {
    case notFound
}

public final class TaskSignal: Sendable {
    public static func timerTrigger(
        every timeInterval: TimeInterval,
        repeats: Bool = true
    ) -> TaskSignal {
        let signal = TaskSignal()
        Timer.scheduledTimer(
            withTimeInterval: timeInterval,
            repeats: repeats,
            block: { timer in
                signal.trigger()
            })
        return signal
    }

    private let _stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    public init() {
        var continuation: AsyncStream<Void>.Continuation!
        self._stream = AsyncStream<Void> { continuation = $0 }
        self.continuation = continuation
    }

    public func stream() -> AsyncStream<Void> {
        _stream
    }

    public func trigger() {
        continuation.yield(())
    }
}

internal actor SharedResource<Resource: Sendable> {
    private var resource: Resource?

    init(resource: Resource? = nil) {
        self.resource = resource
    }

    func access<T>(_ block: (inout Resource?) -> T) -> T {
        block(&resource)
    }
    
    func override(_ newResource: Resource) {
        resource = newResource
    }
    
    func clear() {
        resource = nil
    }
    
    func read(
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

/// Executes scheduled tasks using a provided TaskScheduler.
///
/// This class provides methods to execute tasks either one at a time or continuously in the background.
/// It allows for flexible task execution based on external triggers or ongoing processing needs.
public final class TaskExecutor: Sendable {
    private let taskScheduler: TaskScheduler
    private let state = SharedResource<TaskExecutorState>(resource: .idle)
    private let taskSignal: TaskSignal
    
    public init(
        taskScheduler: TaskScheduler,
        taskSignal: TaskSignal
    ) {
        self.taskScheduler = taskScheduler
        self.taskSignal = taskSignal
    }

    /// Executes the next scheduled task.
    ///
    /// This method is useful to run task based on external triggers, like user actions or system events.
    /// It will execute one task from the scheduler's queue.
    public func justNext() async {
        await taskScheduler.runNext()
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
                for await _ in taskSignal.stream() {
                    if try await executorState.read() != .running { break }
                    await scheduler.runNext()
                }
            } catch SharedResourceError.notFound {
                print("TaskExecutor state not found. Stopping execution.")
            } catch {
                print("Unexpected error: \(error). Stopping execution.")
            }
        }
        return task
    }
    
    @discardableResult
    public func resume() async -> Task<Void, Never> {
        await state.override(.running)
        return runContinuously()
    }
    
    public func resumeAndWait() async {
        let task = await resume()
        await task.value
    }
    
    public func pause() async {
        await state.override(.paused)
    }
}
