import Testing
@testable import TaskScheduler
import Foundation

@Suite("TaskScheduler Stress Tests")
struct TaskSchedulerStressSuite {
    @Test("Immediate load drains the queue")
    func immediateLoadDrainsQueue() async throws {
        let scheduler = TaskScheduler()
        let counter = Counter()
        let total = 1_000

        for _ in 0..<total {
            await scheduler.schedule(
                task: CountingTask(counter: counter),
                mode: .immediate
            )
        }

        try await runNextTimes(scheduler, times: total)

        #expect(await counter.get() == total)
    }

    @Test("Mixed immediate and delayed load drains")
    func mixedImmediateAndDelayedLoadDrains() async throws {
        let scheduler = TaskScheduler()
        let counter = Counter()
        let immediateTotal = 300
        let delayedTotal = 300

        for _ in 0..<immediateTotal {
            await scheduler.schedule(
                task: CountingTask(counter: counter),
                mode: .immediate
            )
        }

        for _ in 0..<delayedTotal {
            await scheduler.schedule(
                task: CountingTask(counter: counter),
                mode: .delayed(0.01)
            )
        }

        try await runNextTimes(scheduler, times: immediateTotal)
        try? await Task.sleep(nanoseconds: 20_000_000)

        // First tick enqueues the delayed tasks once their deadline passes.
        try await scheduler.runNext()
        try await runNextTimes(scheduler, times: delayedTotal)

        #expect(await counter.get() == immediateTotal + delayedTotal)
    }

    private func runNextTimes(
        _ scheduler: TaskScheduler,
        times: Int
    ) async throws {
        for _ in 0..<times {
            try await scheduler.runNext()
        }
    }
}
