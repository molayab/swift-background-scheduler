import TaskScheduler
import Foundation

@available(macOS 10.15, *)
@main struct MyApp {
    static func main() async {
        let scheduler = TaskScheduler.shared
        let taskSignal = TaskExecutorSignal.timerTrigger(every: 1) // Check every second
        
        let executor = TaskExecutor(
            taskScheduler: scheduler,
            taskSignal: taskSignal
        )

        struct SampleTask: ExecutableTask {
            var payload: String
            
            func execute() async throws {
                print(
        """
        > Executing Sample Task \(Date().timeIntervalSince1970) - Payload: \(payload)
        """
                )
            }
        }

        await scheduler.schedule(
            task: SampleTask(payload: "Inmediate Task"),
            mode: .immediate
        )

        await scheduler.schedule(
            task: SampleTask(payload: "Delayed Task"),
            mode: .delayed(5)
        )

        await scheduler.schedule(
            task: SampleTask(payload: "Another Delayed Task"),
            mode: .delayed(10)
        )
        
        await scheduler.schedule(
            task: SampleTask(payload: "Periodic Task"),
            mode: .periodic(60) // Every 60 seconds
        )

        await executor.resumeAndWait()
    }
}


