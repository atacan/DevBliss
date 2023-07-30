import ComposableArchitecture
import SwiftPrettyFeature
import SwiftUI

struct ContentView: View {
    var body: some View {
        SwiftPrettyView(store: Store(initialState: .init(), reducer: SwiftPrettyReducer()))
    }
}
