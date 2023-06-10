import ComposableArchitecture
import SwiftUI
import TextCaseConverterFeature

struct ContentView: View {
    var body: some View {
        #if os(iOS)
            NavigationView {
                TextCaseConverterView(store: Store(initialState: .init(), reducer: TextCaseConverterReducer()))
                    .padding()
            }
        #else
            TextCaseConverterView(
                store: Store(
                    initialState: .init(),
                    reducer: TextCaseConverterReducer()._printChanges()
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
