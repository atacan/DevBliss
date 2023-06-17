import ComposableArchitecture
import RegexMatchesFeature
import SwiftUI

struct ContentView: View {
    var body: some View {
        RegexMatchesView(
            store: Store(
                initialState: .init(),
                reducer: RegexMatchesReducer()._printChanges()
            )
        )
        .padding()
    }
}
