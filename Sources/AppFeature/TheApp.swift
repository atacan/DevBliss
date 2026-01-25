import ComposableArchitecture
import SharedModels
import SwiftUI

struct AppContentView: View {
    var body: some View {
        AppView(
            store: Store(initialState: .init()) {
                AppReducer()
                    //                    ._printChanges()
            }
        )
    }
}

public struct TheApp: App {
    public init() {
        // Run migration FIRST, before any stores are created
        ToolStorageMigration.migrateAllTools()
    }
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
