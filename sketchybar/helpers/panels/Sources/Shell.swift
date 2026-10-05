import Foundation

/// Runs a command through /usr/bin/env and returns its stdout. Blocks until it exits.
@discardableResult
func runCommand(_ arguments: [String]) -> Data {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = arguments
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    guard (try? task.run()) != nil else { return Data() }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    return data
}

/// Runs a command and parses its stdout as a JSON object.
func runJSONCommand(_ arguments: [String]) -> [String: Any]? {
    try? JSONSerialization.jsonObject(with: runCommand(arguments)) as? [String: Any]
}

/// Runs an AppleScript through osascript in the background and hands its trimmed output back on
/// the main queue. osascript (rather than NSAppleScript) keeps the Automation permissions the same
/// as the rest of the sketchybar config.
func runOsascript(_ source: String, completion: ((String) -> Void)? = nil) {
    DispatchQueue.global(qos: .userInitiated).async {
        let output = String(decoding: runCommand(["osascript", "-e", source]), as: UTF8.self)
        DispatchQueue.main.async {
            completion?(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
