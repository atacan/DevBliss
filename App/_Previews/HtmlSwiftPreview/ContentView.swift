import ComposableArchitecture
import HtmlToSwiftFeature
import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(iOS)
            NavigationView {
                HtmlToSwiftView(store: Store(initialState: .init(), reducer: HtmlToSwiftReducer()))
                    .padding()
            }
        #else
            HtmlToSwiftView(
                store: Store(
                    initialState: .init(),
                    reducer: HtmlToSwiftReducer()._printChanges()
                )
            )
            .padding()
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
