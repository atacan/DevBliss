//
// https://github.com/atacan
// 27.06.23
	

import SwiftUI
import SwiftPrettyFeature
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        SwiftPrettyView(store: Store(initialState: .init(), reducer: SwiftPrettyReducer()))
    }
}
