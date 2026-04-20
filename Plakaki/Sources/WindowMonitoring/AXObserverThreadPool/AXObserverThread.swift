//
//  AXObserverThread.swift
//  Plakaki
//
//  Created by Andrey Marshak on 20/04/2026.
//

import Foundation

final class AXObserverThread: Thread, @unchecked Sendable {
    private var runLoop: CFRunLoop!
    private let ready = DispatchSemaphore(value: 0)

    func startAndWaitUntilReady() {
        start()
        ready.wait()
    }

    override func main() {
        let currentRunLoop = RunLoop.current
        runLoop = CFRunLoopGetCurrent()
        ready.signal()

        while !isCancelled {
            currentRunLoop.run(mode: .default, before: .distantFuture)
        }
    }

    func addSource(_ source: CFRunLoopSource) {
        perform(#selector(addSourceOnSelf(_:)), on: self, with: source, waitUntilDone: false)
    }

    @objc
    private func addSourceOnSelf(_ source: CFRunLoopSource) {
        CFRunLoopAddSource(runLoop, source, .defaultMode)
        CFRunLoopWakeUp(runLoop)
    }
}
