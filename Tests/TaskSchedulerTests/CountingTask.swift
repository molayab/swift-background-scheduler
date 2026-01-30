//
//  CountingTask.swift
//  TaskScheduler
//
//  Created by Mateo Olaya on 1/30/26.
//

import Foundation
import TaskScheduler

actor Counter {
    private var value = 0

    func increment() { value += 1 }
    func get() -> Int { value }
}

struct CountingTask: ExecutableTask {
    let counter: Counter

    func execute() async throws {
        await counter.increment()
    }
}

func waitForCount(
    _ counter: Counter,
    expected: Int,
    timeoutSeconds: TimeInterval = 0.2
) async -> Bool {
    let deadline = Date().addingTimeInterval(timeoutSeconds)
    while Date() < deadline {
        if await counter.get() >= expected {
            return true
        }
        try? await Task.sleep(nanoseconds: 5_000_000)
    }
    return false
}
