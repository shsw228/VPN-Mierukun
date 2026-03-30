import Foundation
import VPNMierukunSharedModels

public protocol VPNStatusProviding: Sendable {
    func listServices() async throws -> [String]
    func status(for serviceName: String) async throws -> VPNStatusSnapshot
}

public struct ScutilVPNStatusProvider: VPNStatusProviding {
    public init() {}

    public func listServices() async throws -> [String] {
        let output = try await runScutil(arguments: ["--nc", "list"])
        return parseServices(output)
    }

    public func status(for serviceName: String) async throws -> VPNStatusSnapshot {
        let output = try await runScutil(arguments: ["--nc", "status", serviceName])
        return parseStatus(output, serviceName: serviceName)
    }

    private func runScutil(arguments: [String]) async throws -> String {
        try await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: data, as: UTF8.self)
            let error = String(decoding: errorData, as: UTF8.self)

            guard process.terminationStatus == 0 else {
                throw NSError(
                    domain: "ScutilVPNStatusProvider",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: error.isEmpty ? output : error]
                )
            }

            return output
        }.value
    }

    private func parseServices(_ output: String) -> [String] {
        output
            .split(separator: "\n")
            .compactMap { line in
                guard let firstQuote = line.firstIndex(of: "\""),
                      let lastQuote = line.lastIndex(of: "\""),
                      firstQuote != lastQuote else {
                    return nil
                }
                let start = line.index(after: firstQuote)
                return String(line[start..<lastQuote])
            }
            .sorted()
    }

    private func parseStatus(_ output: String, serviceName: String) -> VPNStatusSnapshot {
        let rawStatus = output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? "Unknown"

        let normalized = rawStatus.lowercased()
        let state: VPNDisplayState
        if normalized.contains("connected") {
            state = .connected
        } else if normalized.contains("disconnected") {
            state = .disconnected
        } else if normalized.contains("connecting")
                    || normalized.contains("disconnecting")
                    || normalized.contains("reasserting") {
            state = .transitioning
        } else {
            state = .unknown
        }

        return VPNStatusSnapshot(
            state: state,
            serviceName: serviceName,
            rawStatus: rawStatus,
            updatedAt: .now
        )
    }
}
