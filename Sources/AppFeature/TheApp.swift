import ComposableArchitecture
import SwiftUI

public struct AppContentView: View {
    public init() {}
    public var body: some View {
        AppView(
            store: Store(
                initialState: .init(),
                reducer: AppReducer()
//                    ._printChanges()
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
