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
