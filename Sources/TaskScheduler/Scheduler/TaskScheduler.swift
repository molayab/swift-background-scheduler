import Foundation

public protocol TaskSchedulerInterface {
    func schedule(
        task: ExecutableTask,
        mode: TaskScheduleMode
    ) async throws
    
    func runNext() async throws
}

@globalActor
public actor TaskScheduler: TaskSchedulerInterface {
    public typealias DelayedTask = (ExecutableTask, executeAt: Date)
    public typealias PeriodicTask = (
        ExecutableTask,
        interval: TimeInterval,
        lastExecuted: Date?
    )
    
    public static let shared = TaskScheduler()
    
    private var executionQueue: [ExecutableTask] = []
    private var delayedTasks: [DelayedTask] = []
    private var periodicTasks: [PeriodicTask] = []
    
    /// Runs the next scheduled task based on its mode.
    public func runNext() async throws {
        // Execute immediate tasks first
        try await execute()
        
        // Schedule delayed tasks if their time has come
        scheduleDelayedTasks()
        
        // Schedule periodic tasks
        schedulePeriodicTasks()
    }
    
    /// Schedules a task with the specified mode.
    ///
    /// - Parameters:
    ///   - task: The task to be scheduled.
    ///   - mode: The scheduling mode for the task.
    public func schedule(
        task: ExecutableTask,
        mode: TaskScheduleMode
    ) async {
        switch mode {
        case .immediate:
            executionQueue.append(task)
        case let .delayed(timeInterval):
            delayedTasks.append(
                (task, Date().addingTimeInterval(timeInterval))
            )
        case .periodic(let timeInterval):
            periodicTasks.append(
                (task, timeInterval, nil)
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Executes the next task in the execution queue.
    private func execute() async throws {
        guard !executionQueue.isEmpty else { return }
        let task = executionQueue.removeFirst()
        try await task.execute()
    }
    
    /// Schedules delayed tasks that are due for execution.
    private func scheduleDelayedTasks(now: Date = Date()) {
        delayedTasks.removeAll { (task, executeAt) in
            if now >= executeAt {
                executionQueue.append(task)
                return true
            }
            return false
        }
    }

    /// Schedules periodic tasks based on their intervals.
    private func schedulePeriodicTasks(now: Date = Date()) {
        for i in 0..<periodicTasks.count {
            let (task, interval, lastExecuted) = periodicTasks[i]
            if let lastExecuted = lastExecuted {
                if now.timeIntervalSince(lastExecuted) >= interval {
                    executionQueue.append(task)
                    periodicTasks[i].lastExecuted = now
                }
            } else {
                executionQueue.append(task)
                periodicTasks[i].lastExecuted = now
            }
        }
    }
}
