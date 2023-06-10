import SwiftUI

public enum ThemeColor {
    public enum Text {
        #if os(macOS)

            public static let label = Color(nsColor: .labelColor)
            public static let controlText = Color(nsColor: .controlTextColor)
            public static let success = Color(nsColor: .systemGreen)
            public static let failure = Color(nsColor: .systemRed)
        #endif

        #if os(iOS)
            public static let label = Color(uiColor: .label)
            public static let controlText = Color.accentColor
            public static let success = Color.green
            public static let failure = Color.red
        #endif
    }
}