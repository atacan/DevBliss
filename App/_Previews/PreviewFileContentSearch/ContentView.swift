//
// https://github.com/atacan
// 22.07.23

import ComposableArchitecture
import FileContentSearchFeature
import SwiftUI

struct ContentView: View {
    var body: some View {
        FileContentSearchView(
            store: Store(
                initialState: FileContentSearchReducer.State(),
                reducer: FileContentSearchReducer()
                    ._printChanges()
            )
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
