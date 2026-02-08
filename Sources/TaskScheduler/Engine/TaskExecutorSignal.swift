import Foundation

/// A lightweight signal used by a task executor to wake up and run work.
public protocol TaskExecutorSignalInterface: Sendable {
    /// Returns the stream of trigger events consumed by the executor.
    func stream() -> AsyncStream<Void>
    /// Fires a single trigger event.
    func trigger()
}

public final class TaskExecutorSignal: Sendable {
    /// Creates a signal that fires on a timer.
    /// - Parameters:
    ///   - timeInterval: Time between triggers, in seconds.
    ///   - repeats: Whether the timer should repeat.
    /// - Returns: A signal that triggers on each timer tick.
    public static func timerTrigger(
        every timeInterval: TimeInterval,
        repeats: Bool = true
    ) -> TaskExecutorSignal {
        let signal = TaskExecutorSignal()
        Timer.scheduledTimer(
            withTimeInterval: timeInterval,
            repeats: repeats,
            block: { _ in
                signal.trigger()
            }
        )
        return signal
    }
    
    /// Creates a signal that is driven by a custom backend.
    /// - Parameters:
    ///   - backend: The backend responsible for triggering the executor.
    ///   - executor: The task executor to register for custom triggers.
    /// - Returns: A signal that triggers based on custom backend events.
    public static func customDrivenTrigger(
        usingBackend backend: any Backend,
        withExecutor executor: any TaskExecutorInterface
    ) -> TaskExecutorSignal {
        backend.register(executor)
        return TaskExecutorSignal.manualTrigger()
    }
    
    /// Creates a manual trigger signal.
    public static func manualTrigger() -> TaskExecutorSignal {
        TaskExecutorSignal()
    }

    private let streamValue: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    /// Creates a new manual signal that can be triggered on demand.
    public init() {
        var continuation: AsyncStream<Void>.Continuation!
        self.streamValue = AsyncStream<Void> { continuation = $0 }
        self.continuation = continuation
    }

    /// Returns the stream of trigger events consumed by the executor.
    public func stream() -> AsyncStream<Void> {
        streamValue
    }

    /// Fires a single trigger event.
    public func trigger() {
        continuation.yield(())
    }
}
