//
//  iOSBackend.swift
//  TaskScheduler
//
//  Created by Mateo Olaya on 1/30/26.
//

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit
import SwiftUI
@preconcurrency import BackgroundTasks

public final class iOSBackend: Backend {
    public let identifier: String
    
    public init(identifier: String = "io.molayab.taskscheduler") {
        self.identifier = identifier
    }
    
    public func register(_ executor: any TaskExecutorInterface) {
        let capturedExecutor = executor
        let appRefreshTaskIdentifier = identifier
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: appRefreshTaskIdentifier,
            using: DispatchQueue.global()
        ) { task in
            Task { @Sendable in
                task.expirationHandler = {
                    Task { await capturedExecutor.pause() }
                }
                
                // Execute the next scheduled task
                do { try await capturedExecutor.justNext() }
                catch {
                    // Handle error if needed
                    print("Error executing task: \(error)")
                }
                
                // Indicate that the task is complete
                task.setTaskCompleted(success: true)
            }
        }
    }
    
    public func unregister() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    // Schedules a background app refresh task.
    public func submit(earliestBeginInterval: TimeInterval) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(
            timeIntervalSinceNow: earliestBeginInterval
        )
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}

extension WindowGroup {
    public func registerBackgroundSchedulerBackend(
        identifier: String,
        executor: any TaskExecutorInterface,
        phase: ScenePhase
    ) -> some Scene {
        self.onChange(of: phase, { _, newPhase in
            switch newPhase {
            case .background:
                scheduleAppRefresh(identifier: identifier)
            case .active:
                BGTaskScheduler
                    .shared
                    .cancelAllTaskRequests()
            case .inactive:
                break
            @unknown default:
                break
            }
        })
        .backgroundTask(.appRefresh(identifier), action: {
            await withTaskCancellationHandler(operation: {
                print("Background task started")
                try? await executor.justNext()
                print("Background task completed")
            }, onCancel: {
                print("Background task cancelled")
                Task { await executor.pause() }
            })
        })
    }
    
    private func scheduleAppRefresh(
        identifier: String
    ) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(
            timeIntervalSinceNow: 1 * 60
        ) // 1 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}

#endif

