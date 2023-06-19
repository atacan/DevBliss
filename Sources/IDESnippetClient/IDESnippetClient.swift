//
// https://github.com/atacan
// 18.06.23
	

import Foundation
import Dependencies

public struct IDESnippetClient {
    public var convert: @Sendable () async throws -> Void
}

// User story
// select source IDE type
// select open panel url
// // if the source is Xcode, then can select folder or file, else only file
// // if the target is Xcode only select a folder, because we don't know how many snippets there will be
// create a list of snippets from the source
// convert them one by one to the target sniptable types
// // if target is Xcode every snippet will be different file, otherwise combine them into one file
// // // library needs function for that. output method is only for one single snippet. static func maybe that takes array of instances
