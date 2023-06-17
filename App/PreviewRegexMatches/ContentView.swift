//
// https://github.com/atacan
// 17.06.23
	

import SwiftUI
import RegexMatchesFeature
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        RegexMatchesView(store: Store(initialState: .init(), reducer: RegexMatchesReducer()._printChanges()
                                     ))
        .padding()
    }
}

