#if os(macOS)
import CommandLineClient
import Dependencies
import Foundation
import XCTestDynamicOverlay

public struct FileContentSearchClient {
    public var run: @Sendable (SearchOptions) async throws -> [FoundFile]
}

extension FileContentSearchClient: DependencyKey {
    public static let liveValue = {
        @Dependency(\.commandLine) var commandLine

        return Self(
            run: { options in

                let command =
                    #"""
                    # Set the search term and folder to search in
                    SEARCH_TERM="\#(options.term)"
                    SEARCH_FOLDER="\#(options.folder)"
                    SEARCH_HIDDEN_FILES=\#(options.searchHiddenFiles)

                    # Loop through all files in the folder and its subdirectories
                    while IFS= read -r -d '' file; do
                        # Check if the file is a regular file and not a binary file
                        if [ -f "$file" ] && [ "$(file -b --mime-type "$file")" != "application/octet-stream" ] && [[ "$(file -b --mime-type "$file")" == text/* ]]; then
                            # Check if the file is hidden and if hidden files should be searched
                            if [ "$SEARCH_HIDDEN_FILES" = true ] || [ "$(basename "$file")" = "$(basename "$file" | sed 's/^\..*//')" ]; then
                                # Search for the search term in the file
                                grep_output=$(grep -nI "$SEARCH_TERM" "$file" | cut -d ':' -f 1 | tr '\n' ',' | sed 's/,$//')
                                # Check if the search term was found in the file
                                if [ -n "$grep_output" ]; then
                                    # Get the last modified time of the file
                                    modified_time=$(date -r "$file" "+%Y-%m-%d %H:%M:%S")
                                    # Check if the file is in a git repository
                                    if [ -n "$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null)" ]; then
                                        # Get the user who made the change in the first line that the search term is found in
                                        line_number=$(echo "$grep_output" | cut -d ',' -f 1)
                                        git_output=$(git blame -L "$line_number,+1" "$file" | head -n 1)
                                        git_user=$(echo "$git_output" | sed 's/^[^(]*(//' | cut -d ' ' -f 1)
                                        # Print the file path, lines that the search term is found, last modified time, and git user (if applicable)
                                        echo "$file|$grep_output|$modified_time|$git_user"
                                    else
                                        # Print the file path, lines that the search term is found, and last modified time
                                        echo "$file|$grep_output|$modified_time"
                                    fi
                                fi
                            fi
                        fi
                    done < <(if [ "$SEARCH_HIDDEN_FILES" = true ]; then
                        find "$SEARCH_FOLDER" -type f -print0
                    else
                        find "$SEARCH_FOLDER" -type f -not -path '*/\.*' -print0
                    fi)
                    """#

                let output = try await commandLine.run(command)
                return
                    output
                    .text
                    .components(separatedBy: "\n")
                    .compactMap { FoundFile($0) }
            }
        )
    }()
}

extension DependencyValues {
    public var fileContentSearch: FileContentSearchClient {
        get { self[FileContentSearchClient.self] }
        set { self[FileContentSearchClient.self] = newValue }
    }
}

public struct SearchOptions: Equatable {
    public var term: String
    public var folder: String
    public var searchHiddenFiles: Bool

    public init(
        searchTerm: String = .init(),
        searchFolder: String = .init(),
        searchHiddenFiles: Bool = false
    ) {
        self.term = searchTerm
        self.folder = searchFolder
        self.searchHiddenFiles = searchHiddenFiles
    }
}

public struct FoundFile: Equatable, Identifiable {
    public let fileURL: String
    public let lineNumbers: [Int]
    public let modifiedTime: Date
    public let gitUsername: String?
    public let id: UUID = .init()

    public var lines: String {
        lineNumbers.map(String.init).joined(separator: ", ")
    }

    public var modifiedTimeString: String {
        let modifiedTimeFormatter = DateFormatter()
        modifiedTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return modifiedTimeFormatter.string(from: modifiedTime)
    }

    public var gitUsernameCleaned: String {
        gitUsername ?? ""
    }

    /// input: /Users/atacan/Downloads/blabla.txt|1,2,4|2023-06-19 23:10:34|atacan
    init?(_ input: String) {
        let components = input.components(separatedBy: "|")
        guard components.count >= 3 else { return nil }
        let fileURL = components[0]
        let lineNumbers = components[1].components(separatedBy: ",").compactMap(Int.init)
        let modifiedTimeString = components[2]
        let modifiedTimeFormatter = DateFormatter()
        modifiedTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let modifiedTime = modifiedTimeFormatter.date(from: modifiedTimeString) else { return nil }
        let gitUsername = components.count > 3 ? components[3] : nil
        
        self.fileURL = fileURL
        self.lineNumbers = lineNumbers
        self.modifiedTime = modifiedTime
        self.gitUsername = gitUsername
    }
}
#endif
