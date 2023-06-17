import SwiftUI

public enum ThemeColor {
    public enum Text {
#if os(macOS)
        public static let editedText = Color(nsColor: .textColor)
        public static let label = Color(nsColor: .labelColor)
        public static let controlText = Color(nsColor: .controlTextColor)
        public static let success = Color(nsColor: .systemGreen)
        public static let failure = Color(nsColor: .systemRed)
        public static let highlightedTextSecondary = NSColor.lightGray.cgColor
        public static let highlightedTextPrimary = NSColor.systemBlue.withSystemEffect(.pressed).cgColor
#endif
        
#if os(iOS)
        public static let editedText = Color(uiColor: UIColor.darkText)
        public static let label = Color(uiColor: .label)
        public static let controlText = Color.accentColor
        public static let success = Color.green
        public static let failure = Color.red
        public static let highlightedTextSecondary = UIColor.systemGray.cgColor
        public static let highlightedTextPrimary = UIColor.systemBlue.cgColor
#endif
    }
}
