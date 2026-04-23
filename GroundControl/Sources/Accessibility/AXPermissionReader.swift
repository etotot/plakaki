@preconcurrency import ApplicationServices
import Foundation

public enum AXPermissionReader {
    public static func isTrusted(triggerPrompt: Bool) -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [promptKey: triggerPrompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
