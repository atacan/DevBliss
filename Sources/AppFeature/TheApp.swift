import SharedModels
import SwiftUI

struct AppContentView: View {
    @State private var model = AppModel()

    var body: some View {
        AppModelView(model: model)
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
