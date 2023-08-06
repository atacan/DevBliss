
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

public struct TheApp {
    public init() {}
    public var windowGroup: some Scene = WindowGroup {
            AppContentView()
        }
        #if os(macOS)
            .windowStyle(.titleBar)
            .windowToolbarStyle(.unified(showsTitle: true))
        #endif
    
}
