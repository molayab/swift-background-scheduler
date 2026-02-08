# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the library
swift build

# Run all tests
swift test

# Run a single test by name
swift test --filter "TaskSchedulerSuite/immediateTaskRunsOnNext"

# Run a test suite
swift test --filter "TaskSchedulerSuite"
swift test --filter "TaskSchedulerStressSuite"
```

This is an SPM package (Swift 6.2, iOS 17+, macOS 10.15+). No external dependencies.

## Testing

Tests use **Swift Testing** (`@Suite`, `@Test` macros from `import Testing`), **not** XCTest. Key conventions:

- Tests are in `Tests/TaskSchedulerTests/`
- `CountingTask` + `Counter` actor are shared test helpers for verifying task execution counts
- `waitForCount(_:expected:timeoutSeconds:)` provides async polling with a 200ms default timeout for signal-driven tests
- Tests create fresh `TaskScheduler()` instances rather than using the singleton, to isolate state

## Architecture

Actor-based task scheduling library with signal-driven execution.

### Flow: Schedule → Signal → Execute

1. **Schedule**: `TaskScheduler` (a `@globalActor`) queues tasks into three internal lists — immediate, delayed, and periodic
2. **Signal**: `TaskExecutorSignal` wraps an `AsyncStream<Void>` that wakes the executor. Created via factory methods: `.manualTrigger()`, `.timerTrigger(every:)`, or `.customDrivenTrigger(usingBackend:)`
3. **Execute**: `TaskExecutor` runs `for await _ in signal.stream()` in a `.background` priority `Task`, calling `scheduler.runNext()` on each signal. It self-triggers when pending tasks remain

### Key types

| Type | Kind | Role |
|------|------|------|
| `TaskScheduler` | `@globalActor actor` | Singleton queue manager. Three queues: execution, delayed, periodic |
| `ExecutableTask` | `protocol: Sendable` | Single method: `execute() async throws` |
| `TaskScheduleMode` | `enum` | `.immediate`, `.delayed(TimeInterval)`, `.periodic(TimeInterval)` |
| `TaskExecutor` | `final class: Sendable` | Lifecycle control: `justNext()`, `runContinuously()`, `resume()`, `pause()` |
| `TaskExecutorSignal` | `final class: Sendable` | AsyncStream-based wakeup mechanism |
| `Backend` | `protocol` | Platform-specific triggers: `register(_:)` / `unregister()` |
| `SharedResource<T>` | `actor` | Generic thread-safe mutable state container |

### Platform backends

- **`iOSBackend`**: Uses `BGTaskScheduler` from Apple's `BackgroundTasks` framework. Integrates via `WindowGroup.registerBackgroundSchedulerBackend()` SwiftUI modifier
- **`MacOSBackend`**: Uses `NSBackgroundActivityScheduler` with a 15-minute interval

### Concurrency model

- All shared state is protected by actors (`TaskScheduler` global actor, `SharedResource<T>`)
- `TaskExecutor` manages its lifecycle state via `SharedResource<TaskExecutorState>` (`.idle` / `.running` / `.paused`)
- No callbacks — fully async/await with structured concurrency
- All public types conform to `Sendable`
