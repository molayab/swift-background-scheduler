import Testing
@testable import TaskScheduler
import Foundation

@Suite("TaskScheduler Tests")
struct TaskSchedulerSuite {
    @Test("Immediate task runs on next tick")
    func immediateTaskRunsOnNext() async throws {
        let scheduler = TaskScheduler()
        let counter = Counter()

        await scheduler.schedule(
            task: CountingTask(counter: counter),
            mode: .immediate
        )

        try await scheduler.runNext()

        #expect(await counter.get() == 1)
    }

    @Test("Delayed task runs after delay")
    func delayedTaskRunsAfterDelay() async throws {
        let scheduler = TaskScheduler()
        let counter = Counter()

        await scheduler.schedule(
            task: CountingTask(counter: counter),
            mode: .delayed(0.02)
        )

        try await scheduler.runNext()
        #expect(await counter.get() == 0)

        try? await Task.sleep(nanoseconds: 30_000_000)

        try await scheduler.runNext()
        try await scheduler.runNext()

        #expect(await counter.get() == 1)
    }

    @Test("Periodic task runs on subsequent ticks")
    func periodicTaskRunsOnSubsequentTicks() async throws {
        let scheduler = TaskScheduler()
        let counter = Counter()

        await scheduler.schedule(
            task: CountingTask(counter: counter),
            mode: .periodic(0.02)
        )

        try await scheduler.runNext()
        try await scheduler.runNext()

        #expect(await counter.get() == 1)

        try? await Task.sleep(nanoseconds: 30_000_000)

        try await scheduler.runNext()
        try await scheduler.runNext()

        #expect(await counter.get() == 2)
    }

    @Test("Executor runs when signaled")
    func executorRunsWhenSignaled() async throws {
        let scheduler = TaskScheduler()
        let counter = Counter()
        let signal = TaskExecutorSignal()
        let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: signal)

        let task = await executor.resume()

        await scheduler.schedule(
            task: CountingTask(counter: counter),
            mode: .immediate
        )

        signal.trigger()

        let didRun = await waitForCount(counter, expected: 1)
        #expect(didRun)

        task.cancel()
        await executor.pause()
    }

    @Test("Executor justNext runs a scheduled task")
    func executorJustNextRunsImmediateTask() async throws {
        let scheduler = TaskScheduler()
        let counter = Counter()
        let signal = TaskExecutorSignal()
        let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: signal)

        await scheduler.schedule(
            task: CountingTask(counter: counter),
            mode: .immediate
        )

        try await executor.justNext()

        #expect(await counter.get() == 1)
    }

    @Test("Executor pause stops execution on signal")
    func executorPausePreventsRunOnSignal() async throws {
        let scheduler = TaskScheduler()
        let counter = Counter()
        let signal = TaskExecutorSignal()
        let executor = TaskExecutor(taskScheduler: scheduler, taskSignal: signal)

        let task = await executor.resume()

        await scheduler.schedule(
            task: CountingTask(counter: counter),
            mode: .immediate
        )

        await executor.pause()
        signal.trigger()

        let didRun = await waitForCount(counter, expected: 1)
        #expect(!didRun)

        task.cancel()
    }
}
