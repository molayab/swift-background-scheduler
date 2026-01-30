# TaskScheduler

A lightweight, actor-based and protocol-oriented task scheduler built in pure Swift, ready for all platforms. Schedule immediate, delayed, or periodic work and execute it via a signal-driven executor (no busy waiting).

You can use it with BackgroundTasks, SwiftUI, server-side Swift, or any Swift concurrency context.

## Features

- Immediate, delayed, and periodic scheduling modes.
- Global actor (`TaskScheduler`) for safe task queuing.
- Signal-driven execution using `AsyncStream` via `ExecutorTaskSignal`.
- Simple API surface with `ExecutableTask` protocol.


## Installation

This can be added via Swift Package Manager.

## Quick Start

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
let signal = TaskSignal.timerTrigger(every: 1.0)
let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: signal)

// Start the executor.
Task {
    await executor.resume()
}

// Schedule tasks.
await scheduler.schedule(task: PrintTask(message: "Hello now"), mode: .immediate)
await scheduler.schedule(task: PrintTask(message: "Hello in 2s"), mode: .delayed(2))
await scheduler.schedule(task: PrintTask(message: "Hello every 5s"), mode: .periodic(5))

// Trigger a run immediately (optional if you already have a timer signal).
signal.trigger()
```

## Scheduling Modes

```swift
TaskScheduleMode.immediate
TaskScheduleMode.delayed(2)   // seconds
TaskScheduleMode.periodic(10) // seconds
```

## Triggering Execution Without Busy Waiting

`TaskExecutor` listens to an `AsyncStream` produced by `ExecutorTaskSignal`. Whenever you call `signal.trigger()`, the executor wakes and processes the next tasks.

Example: trigger on demand (e.g., after scheduling a task):

```swift
let signal = TaskSignal()
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: signal)

Task { await executor.resume() }

await TaskScheduler.shared.schedule(task: PrintTask(message: "Run on trigger"), mode: .immediate)
signal.trigger()
```

Example: trigger periodically with a timer:

```swift
let signal = TaskSignal.timerTrigger(every: 0.5)
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: signal)
Task { await executor.resume() }
```

## Executing One Task Manually

If you want to execute a single task on demand, call `justNext()`:

```swift
await executor.justNext()
```

## Example App

An example app target is included. It demonstrates creating a scheduler and executor, then running tasks.

## Concurrency Notes

- `TaskScheduler` is a global actor; schedule tasks via `await` calls.
- `TaskExecutor` is `Sendable` and safe to use across tasks.
- The executor only runs when signaled; no active waiting loop.

## License

MIT

## Contributing

Contributions are welcome! Please open issues or pull requests on the GitHub repository.

## Thanks

Thanks to the Swift community for inspiration and ideas on concurrency and task scheduling.
