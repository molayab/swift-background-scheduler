# TaskScheduler

![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017+%20|%20macOS%2010.15+-blue.svg)
![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-green.svg)

A lightweight, actor-based task scheduler for Swift. Schedule immediate, delayed, or periodic work and execute it through a signal-driven executor — no busy waiting, no polling.

Built on Swift concurrency (actors, async/await, `AsyncStream`) with full `Sendable` conformance. Works with iOS `BackgroundTasks`, macOS `NSBackgroundActivityScheduler`, SwiftUI, server-side Swift, or any async context.

## Platform Requirements

- iOS 17+
- macOS 10.15+
- Swift 6.2+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/molayab/swift-background-scheduler.git", branch: "master")
]
```

Then add `TaskScheduler` as a dependency of your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["TaskScheduler"]
)
```

## Quick Start

### 1. Define a task

Conform to `ExecutableTask` — a single-method `Sendable` protocol:

```swift
import TaskScheduler

struct PrintTask: ExecutableTask {
    let message: String

    func execute() async throws {
        print(message)
    }
}
```

### 2. Schedule and run

```swift
let scheduler = TaskScheduler.shared
let signal = TaskExecutorSignal.timerTrigger(every: 1.0)
let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: signal)

await executor.resume()

await scheduler.schedule(task: PrintTask(message: "Hello now"), mode: .immediate)
await scheduler.schedule(task: PrintTask(message: "Hello in 2s"), mode: .delayed(2))
await scheduler.schedule(task: PrintTask(message: "Hello every 5s"), mode: .periodic(5))
```

## Architecture

```
Schedule                    Signal                      Execute
┌──────────────────┐   ┌──────────────────────┐   ┌──────────────────┐
│  TaskScheduler   │   │ TaskExecutorSignal   │   │  TaskExecutor    │
│  (@globalActor)  │◄──│ (AsyncStream<Void>)  │◄──│  (Sendable)      │
│                  │   │                      │   │                  │
│ - immediate queue│   │ .manualTrigger()     │   │ .justNext()      │
│ - delayed queue  │   │ .timerTrigger(every:)│   │ .runContinuously()│
│ - periodic queue │   │ .customDrivenTrigger()│   │ .resume() / .pause()│
└──────────────────┘   └──────────────────────┘   └──────────────────┘
```

1. **TaskScheduler** queues tasks into three lists (immediate, delayed, periodic). It is a `@globalActor` — all queue access is serialized.
2. **TaskExecutorSignal** wraps an `AsyncStream<Void>`. Each `.yield()` wakes the executor. No CPU is consumed while idle.
3. **TaskExecutor** awaits the signal stream in a `.background`-priority `Task`, calling `scheduler.runNext()` on each signal. When pending tasks remain, it re-triggers itself automatically.

## Scheduling Modes

| Mode | Description |
|------|-------------|
| `.immediate` | Runs on the next executor cycle |
| `.delayed(TimeInterval)` | Runs once after the specified seconds elapse |
| `.periodic(TimeInterval)` | Runs repeatedly at the given interval |

```swift
await scheduler.schedule(task: myTask, mode: .immediate)
await scheduler.schedule(task: myTask, mode: .delayed(2))
await scheduler.schedule(task: myTask, mode: .periodic(10))
```

## Signal Types

### Manual trigger

Fire on demand — useful when you want explicit control over when work runs:

```swift
let signal = TaskExecutorSignal.manualTrigger()
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: signal)
await executor.resume()

await TaskScheduler.shared.schedule(task: myTask, mode: .immediate)
signal.trigger() // wake the executor
```

### Timer trigger

Wake the executor at a fixed interval:

```swift
let signal = TaskExecutorSignal.timerTrigger(every: 0.5)
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: signal)
await executor.resume()
```

### Custom backend trigger

Connect the executor to a platform-specific or custom backend:

```swift
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: .manualTrigger())
await executor.resume()

let signal = TaskExecutorSignal.customDrivenTrigger(
    usingBackend: myBackend,
    withExecutor: executor
)
```

## Platform Backends

The library ships with built-in backends for Apple platforms:

- **macOS** — `MacOSBackend` uses `NSBackgroundActivityScheduler` (15-minute repeating interval).
- **iOS/tvOS/watchOS** — `iOSBackend` integrates with Apple's `BackgroundTasks` framework via a SwiftUI `WindowGroup` modifier (work in progress).

## Custom Backends

Conform to the `Backend` protocol to create your own trigger source (push notifications, WebSockets, file-system events, etc.):

```swift
final class PushBackend: Backend {
    private var executor: (any TaskExecutorInterface)?

    func register(_ executor: any TaskExecutorInterface) {
        self.executor = executor
    }

    func unregister() {
        executor = nil
    }

    // Call this when a push arrives
    func onPushReceived() {
        Task { try? await executor?.justNext() }
    }
}
```

Wire it up:

```swift
let scheduler = TaskScheduler.shared
let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: .manualTrigger())
await executor.resume()

let backend = PushBackend()
TaskExecutorSignal.customDrivenTrigger(
    usingBackend: backend,
    withExecutor: executor
)

await scheduler.schedule(task: myTask, mode: .immediate)
backend.onPushReceived()
```

## Executor Lifecycle

`TaskExecutor` has three states: **idle**, **running**, and **paused**.

```swift
let executor = TaskExecutor(taskScheduler: .shared, taskSignal: signal)

// Start continuous execution
await executor.resume()

// Pause — the executor stops processing after the current task
await executor.pause()

// Or run a single task on demand without starting the loop
try await executor.justNext()
```

## Example App

The repository includes a demo iOS app (`BackgroundApp`) in the parent workspace that shows how to integrate `TaskScheduler` with SwiftUI, SwiftData, and iOS background tasks. See the [workspace README](https://github.com/molayab/swift-molayab-playground) for setup instructions.

## Contributing

Contributions are welcome! Please open issues or pull requests on the [GitHub repository](https://github.com/molayab/swift-background-scheduler).
