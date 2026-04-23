//
//  AXPermissionManager.swift
//  Plakaki
//
//  Created by Andrey Marshak on 18/04/2026.
//

@preconcurrency import ApplicationServices
import Dependencies
import Foundation
import GroundControl

struct AXPermissionManager {
    var isTrusted: @Sendable (_ triggerPrompt: Bool) -> Bool
    var openSystemSettings: @Sendable () -> Void
}

extension AXPermissionManager: DependencyKey {
    static var liveValue: Self {
        Self(
            isTrusted: { (triggerPrompt: Bool) -> Bool in
                return AXPermissionReader.isTrusted(triggerPrompt: triggerPrompt)
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
