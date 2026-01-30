import Foundation

/// Executes scheduled tasks using a provided TaskScheduler.
///
/// This class provides methods to execute tasks either one at a time or continuously in the background.
/// It allows for flexible task execution based on external triggers or ongoing processing needs.
public final class TaskExecutor {
    private let taskScheduler: TaskScheduler
    
    public init(taskScheduler: TaskScheduler) {
        self.taskScheduler = taskScheduler
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
    public func runContinuously() {
        let scheduler = self.taskScheduler
        Task(priority: .background) {
            while true {
                await scheduler.runNext()
            }
        }
    }
}
