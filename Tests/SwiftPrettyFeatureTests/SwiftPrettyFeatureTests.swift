import Dependencies
import XCTest

@testable import SwiftPrettyFeature

@MainActor
final class SwiftPrettyFeatureTests: XCTestCase {
    func testLockwoodConfigBinding() async {
        await withDependencies {
            $0.swiftPretty = .testValue
        } operation: {
            let model = SwiftPrettyModel()
            let config = "some config"
            model.setLockwoodConfig(config)
            XCTAssertEqual(model.lockwoodConfig, config)
        }
    }
}
