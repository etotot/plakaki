//
//  A11yPermissionManager.swift
//  Plakaki
//
//  Created by Andrey Marshak on 18/04/2026.
//

@preconcurrency import ApplicationServices
import Dependencies
import Foundation

struct AxPermissionManager: Sendable {
    var checkAxStatus: @Sendable (_ triggerPrompt: Bool) -> Bool
    var openSystemSettings: @Sendable () -> Void
}

extension AxPermissionManager: DependencyKey {
    static var liveValue: Self {
        return Self(
            checkAxStatus: { (triggerPrompt: Bool) -> Bool in
                let promptKey: String = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
                let options: CFDictionary = [promptKey: triggerPrompt] as CFDictionary
                let trusted: Bool = AXIsProcessTrustedWithOptions(options)

                return trusted
            },
            openSystemSettings: {
                fatalError("Not implemented")
            }
        )
    }
}

extension DependencyValues {
    var axPermissionManager: AxPermissionManager {
        get { self[AxPermissionManager.self] }
        set { self[AxPermissionManager.self] = newValue }
    }
}
