//
//  AXPermissionManager.swift
//  Plakaki
//
//  Created by Andrey Marshak on 18/04/2026.
//

@preconcurrency import ApplicationServices
import Dependencies
import Foundation

struct AXPermissionManager {
    var checkAxStatus: @Sendable (_ triggerPrompt: Bool) -> Bool
    var openSystemSettings: @Sendable () -> Void
}

extension AXPermissionManager: DependencyKey {
    static var liveValue: Self {
        Self(
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
    var axPermissionManager: AXPermissionManager {
        get { self[AXPermissionManager.self] }
        set { self[AXPermissionManager.self] = newValue }
    }
}
