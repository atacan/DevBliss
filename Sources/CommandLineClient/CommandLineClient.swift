#if os(macOS)
import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct CommandLineClient {
    public var run: @Sendable (String) async throws -> CLIOutput
}

extension CommandLineClient: DependencyKey {
    public static let liveValue = Self(
        run: { command in
            let task = Process()
            let pipe = Pipe()

            task.standardOutput = pipe
            task.standardError = pipe
            task.arguments = ["-c", command]
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.standardInput = nil

            try task.run()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)!

            return CLIOutput(text: output)
        }
    )
}

extension DependencyValues {
    public var commandLine: CommandLineClient {
        get { self[CommandLineClient.self] }
        set { self[CommandLineClient.self] = newValue }
    }
}

public struct CLIOutput {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

extension CommandLineClient: TestDependencyKey {
    public static var previewValue: CommandLineClient = Self(
        run: { _ in CLIOutput(text: "") }
    )
    public static var testValue: CommandLineClient = Self(
        run: XCTUnimplemented("\(Self.self).run")
    )
}
#endif
