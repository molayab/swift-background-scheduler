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

extension WindowGroup {
    public func registerBackgroundSchedulerBackend(
        identifier: String,
        executor: any TaskExecutorInterface,
        phase: ScenePhase
    ) -> some Scene {
//        self.onChange(of: phase, { _, newPhase in
//            switch newPhase {
//            case .background:
//                scheduleAppRefresh(identifier: identifier)
//            case .active:
//                BGTaskScheduler
//                    .shared
//                    .cancelAllTaskRequests()
//            case .inactive:
//                break
//            @unknown default:
//                break
//            }
//        })
        self
//        .backgroundTask(.appRefresh(identifier), action: {
//            await withTaskCancellationHandler(operation: {
//                print("Background task started")
//                // try? await executor.justNext()
//                print("Background task completed")
//            }, onCancel: {
//                print("Background task cancelled")
//                // Task { await executor.pause() }
//            })
//        })
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

