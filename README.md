## TaskScheduler

A lightweight, actor-based and protocol-oriented task scheduler built in pure Swift, ready for all platforms. Schedule immediate, delayed, or periodic work and execute it via a signal-driven executor (no busy waiting).

You can use it with BackgroundTasks, SwiftUI, server-side Swift, or any Swift concurrency context.

### Features

- Immediate, delayed, and periodic scheduling modes.
- Global actor (`TaskScheduler`) for safe task queuing.
- Signal-driven execution using `AsyncStream` via `TaskExecutorSignal`.
- Simple API surface with `ExecutableTask` protocol.


### Installation

This can be added via Swift Package Manager.

### Quick Start

Define a task:

```swift
import TaskScheduler

struct PrintTask: ExecutableTask {
    let message: String

    func execute() async throws {
        print(message)
    }
}
```

Schedule and run:

```swift
import TaskScheduler

let scheduler = TaskScheduler.shared

// Use a timer-backed signal to wake the executor periodically.
let signal = TaskExecutorSignal.timerTrigger(every: 1.0)
let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: signal)

// Start the executor.
    await executor.resume()

// Schedule tasks.
await scheduler.schedule(task: PrintTask(message: "Hello now"), mode: .immediate)
await scheduler.schedule(task: PrintTask(message: "Hello in 2s"), mode: .delayed(2))
await scheduler.schedule(task: PrintTask(message: "Hello every 5s"), mode: .periodic(5))

// Trigger a run immediately (optional if you already have a timer signal).
signal.trigger()
```

### Scheduling Modes

```swift
TaskScheduleMode.immediate
TaskScheduleMode.delayed(2)   // seconds
TaskScheduleMode.periodic(10) // seconds
```

### Triggering Execution Without Busy Waiting

`TaskExecutor` listens to an `AsyncStream` produced by `TaskExecutorSignal`. Whenever you call `signal.trigger()`, the executor wakes and processes the next tasks.

Example: trigger on demand (e.g., after scheduling a task):

```swift
let signal = TaskExecutorSignal()
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: signal)

Task { await executor.resume() }

await TaskScheduler.shared.schedule(task: PrintTask(message: "Run on trigger"), mode: .immediate)
signal.trigger()
```

Example: trigger periodically with a timer:

```swift
let signal = TaskExecutorSignal.timerTrigger(every: 0.5)
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: signal)
Task { await executor.resume() }
```

#### System-Driven Backends

`TaskExecutorSignal.systemDrivenTrigger(executor:)` connects the executor to platform backends and also provides a safe fallback timer trigger.

Use case: run work when the system grants background time.

```swift
let scheduler = TaskScheduler.shared
let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: .manualTrigger())

Task { await executor.resume() }

let signal = TaskExecutorSignal.systemDrivenTrigger(executor: executor)
```

**Built-in backends**

- iOS/tvOS/watchOS: `iOSBackend` uses system background scheduling (BackgroundModes) to trigger work.
- macOS: `MacOSBackend` registers for macOS power-efficient background events.
- Other platforms: falls back to `executor.runContinuously()`.

#### Custom Backend

You can plug in your own backend by conforming to `Backend` and registering your executor. Use this when you have an app-specific trigger (push, sockets, file events, etc.).

Example backend that triggers when you call `notify()`:

```swift
final class ManualBackend: Backend {
    private var executor: TaskExecutorInterface?

    func register(_ executor: TaskExecutorInterface) {
        self.executor = executor
    }

    func notify() {
        Task { _ = await executor?.runNext() }
    }
}

let scheduler = TaskScheduler.shared
let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: .manualTrigger())
Task { await executor.resume() }

let backend = ManualBackend()

// Register the backend with the executor
TaskExecutorSignal.customDrivenTrigger(
    usingBackend: backend,
    withExecutor: executor // executor is directly called by your backend.
)

await scheduler.schedule(task: PrintTask(message: "Custom backend"), mode: .immediate)

// Call your backend to perform next task
backend.notify()
```

### Example App

An example app target is included. It demonstrates creating a scheduler and executor, then running tasks.

### Contributing

Contributions are welcome! Please open issues or pull requests on the GitHub repository.

#### Thanks

Thanks to the Swift community for inspiration and ideas on concurrency and task scheduling.

