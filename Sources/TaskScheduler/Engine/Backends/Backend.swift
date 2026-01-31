//
//  Backend.swift
//  TaskScheduler
//
//  Created by Mateo Olaya on 1/30/26.
//

public protocol Backend {
    func register(_ executor: any TaskExecutorInterface)
    func unregister()
}
