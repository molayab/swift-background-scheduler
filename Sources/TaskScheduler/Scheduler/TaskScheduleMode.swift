import Foundation

/// Represents the scheduling mode for a task.
public enum TaskScheduleMode: Sendable {
    /// Execute the task immediately.
    case immediate
    /// Execute the task after a specified delay.
    case delayed(TimeInterval)
    /// Execute the task periodically at specified intervals.
    case periodic(TimeInterval)
}
