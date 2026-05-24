import Foundation
import AppKit

// Thin wrapper around NSAppleScript. Compilation and
// execution errors surface in-band -- the caller gets
// (result: "", isError: true, errorMessage: ...)
// instead of a throw, because the JSON-RPC client
// almost always wants to surface the script error to
// its own caller rather than crash.
public enum AppleScriptBindings {
    public struct Outcome {
        public let result: String
        public let isError: Bool
        public let errorMessage: String?

        public init(result: String, isError: Bool, errorMessage: String?) {
            self.result = result
            self.isError = isError
            self.errorMessage = errorMessage
        }
    }

    public static func run(source: String) -> Outcome {
        guard let script = NSAppleScript(source: source) else {
            return Outcome(result: "", isError: true, errorMessage: "Could not initialize NSAppleScript")
        }

        var error: NSDictionary?
        let descriptor = script.executeAndReturnError(&error)
        if let error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "AppleScript error"
            return Outcome(result: "", isError: true, errorMessage: message)
        }

        let stringValue = descriptor.stringValue ?? ""
        return Outcome(result: stringValue, isError: false, errorMessage: nil)
    }
}
