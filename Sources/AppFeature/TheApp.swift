import ComposableArchitecture
import SwiftUI

struct AppContentView: View {
    var body: some View {
        AppView(
            store: Store(
                initialState: .init(),
                reducer: AppReducer()
            )
        )
    }
}

public struct TheApp: App {
    public init() {}
    public var body: some Scene {
        WindowGroup {
            AppContentView()
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        #endif
    }
}
