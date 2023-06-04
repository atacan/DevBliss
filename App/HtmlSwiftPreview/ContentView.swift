import ComposableArchitecture
import HtmlToSwiftFeature
import SwiftUI

struct ContentView: View {
    var body: some View {
        HtmlToSwiftView(store: Store(initialState: .init(), reducer: HtmlToSwiftReducer()))
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
