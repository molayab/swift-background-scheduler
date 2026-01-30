//
//  MacOSBackend.swift
//  TaskScheduler
//
//  Created by Mateo Olaya on 1/30/26.
//

#if os(macOS)

import AppKit

@available(macOS 10.15, *)
final class MacOSBackend: Backend {
    private let nativeScheduler = NSBackgroundActivityScheduler(
        identifier: "com.example.myapp.backgroundactivity"
    )
    
    func register(_ executor: any TaskExecutorInterface) {
        nativeScheduler.repeats = true
        nativeScheduler.interval = 60 * 15 // 15 minutes
        nativeScheduler.tolerance = 60 // 1 minute
        nativeScheduler.schedule { completion in
            Task {
                do { try await executor.justNext() }
                catch {
                    // Handle error if needed
                    print("Error executing task: \(error)")
                }
                
                completion(.finished)
            }
        }
    }
    
    func unregister() {
        nativeScheduler.invalidate()
    }
}

#endif
