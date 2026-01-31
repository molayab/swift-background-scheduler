//
//  iOSBackend.swift
//  TaskScheduler
//
//  Created by Mateo Olaya on 1/30/26.
//

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit
import BackgroundTasks

final class iOSBackend: Backend {
    func register(_ executor: any TaskExecutorInterface) {
        let appRefreshTaskIdentifier = "com.example.myapp.apprefresh"
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: appRefreshTaskIdentifier,
            using: nil
        ) { task in
            task.expirationHandler = {
                // Clean up work before the task expires
                executor.pause()
            }
            
            Task {
                // Execute the next scheduled task
                do { try await executor.justNext() }
                catch {
                    // Handle error if needed
                    print("Error executing task: \(error)")
                }
                
                // Indicate that the task is complete
                task.setTaskCompleted(success: true)
            }
        }
    }
    
    func unregister() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
}

#endif
