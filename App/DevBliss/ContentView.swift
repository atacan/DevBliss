import AppFeature
import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    var body: some View {
        AppView(
            store: Store(
                initialState: .init(),
                reducer: AppReducer()
//                    ._printChanges()
            )
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
