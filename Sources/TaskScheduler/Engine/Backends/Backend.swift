//
//  Backend.swift
//  TaskScheduler
//
//  Created by Mateo Olaya on 1/30/26.
//

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol Backend {
    func register(_ executor: any TaskExecutorInterface)
    func unregister()
}
