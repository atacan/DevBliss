import SwiftUI

public enum ThemeColor {
    public enum Text {
        #if os(macOS)

            public static let label = Color(nsColor: .labelColor)
            public static let controlText = Color(nsColor: .controlTextColor)
        #endif

        #if os(iOS)
            public static let label = Color(uiColor: .label)
            public static let controlText = Color.accentColor
        #endif
    }
}
