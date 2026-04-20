//
//  AXObserverThreadPool.swift
//  Plakaki
//
//  Created by Andrey Marshak on 20/04/2026.
//

import Dependencies
import Foundation

protocol AXObserverThreadPool: Sendable {
    func thread(for pid: pid_t) -> AXObserverThread
}

struct SingleAXObserverThreadPool: AXObserverThreadPool {
    private let thread: AXObserverThread = {
        let thread = AXObserverThread()
        thread.startAndWaitUntilReady()
        return thread
    }()

    func thread(for _: pid_t) -> AXObserverThread {
        thread
    }
}

private enum AXObserverThreadPoolKey: DependencyKey {
    static let liveValue: AXObserverThreadPool = SingleAXObserverThreadPool()
}

extension DependencyValues {
    var axObserverThreadPool: AXObserverThreadPool {
        get { self[AXObserverThreadPoolKey.self] }
        set { self[AXObserverThreadPoolKey.self] = newValue }
    }
}
