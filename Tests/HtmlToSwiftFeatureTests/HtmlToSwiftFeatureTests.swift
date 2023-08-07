import ComposableArchitecture
import XCTest
@testable import HtmlToSwiftFeature

@MainActor
final class HtmlToSwiftFeatureTests: XCTestCase {
    func testGetConvertedCode() async {
        
        let store = TestStore(initialState: HtmlToSwiftReducer.State()) {
            HtmlToSwiftReducer()
        } withDependencies: { $0.htmlToSwift.binaryBirds = {_, _ in "Binary Birds"}
        }
        
        await store.send(.convertButtonTouched) {
            $0.isConversionRequestInFlight = true
        }
        
        await store.receive(.conversionResponse(.success("Binary Birds"))){
            $0.inputOutput.output.text = "Binary Birds"
            $0.isConversionRequestInFlight = false
        }
    }
}   
