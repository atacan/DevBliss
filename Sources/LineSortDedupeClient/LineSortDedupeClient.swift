import Dependencies
import Foundation

public struct LineSortDedupeClient {
    public var convert: @Sendable (String, LineSortDedupeConfig) async throws -> String
}

public enum LineSortOrder: String, CaseIterable, Identifiable, Codable {
    case ascending = "Ascending"
    case descending = "Descending"

    public var id: Self { self }
}

public struct LineSortDedupeConfig: Equatable, Codable {
    public var sortOrder: LineSortOrder
    public var removeDuplicates: Bool
    public var caseInsensitive: Bool
    public var trimWhitespace: Bool
    public var removeEmptyLines: Bool

    public init(
        sortOrder: LineSortOrder = .ascending,
        removeDuplicates: Bool = true,
        caseInsensitive: Bool = true,
        trimWhitespace: Bool = true,
        removeEmptyLines: Bool = true
    ) {
        self.sortOrder = sortOrder
        self.removeDuplicates = removeDuplicates
        self.caseInsensitive = caseInsensitive
        self.trimWhitespace = trimWhitespace
        self.removeEmptyLines = removeEmptyLines
    }
}

extension LineSortDedupeClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, config in
            let rawLines = input.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                .map(String.init)

            var processedLines = [String]()
            processedLines.reserveCapacity(rawLines.count)

            for line in rawLines {
                let trimmed = config.trimWhitespace
                    ? line.trimmingCharacters(in: .whitespacesAndNewlines)
                    : line

                if config.removeEmptyLines && trimmed.isEmpty {
                    continue
                }

                processedLines.append(trimmed)
            }

            let compare: (String, String) -> ComparisonResult = { lhs, rhs in
                if config.caseInsensitive {
                    return lhs.localizedCaseInsensitiveCompare(rhs)
                }
                return lhs.localizedCompare(rhs)
            }

            let sortedLines: [String]
            switch config.sortOrder {
            case .ascending:
                sortedLines = processedLines.sorted { compare($0, $1) == .orderedAscending }
            case .descending:
                sortedLines = processedLines.sorted { compare($0, $1) == .orderedDescending }
            }

            let finalLines: [String]
            if config.removeDuplicates {
                var seen = Set<String>()
                finalLines = sortedLines.filter { line in
                    let key = config.caseInsensitive ? line.lowercased() : line
                    if seen.contains(key) {
                        return false
                    }
                    seen.insert(key)
                    return true
                }
            } else {
                finalLines = sortedLines
            }

            return finalLines.joined(separator: "\n")
        }
    )
}

extension DependencyValues {
    public var lineSortDedupe: LineSortDedupeClient {
        get { self[LineSortDedupeClient.self] }
        set { self[LineSortDedupeClient.self] = newValue }
    }
}
