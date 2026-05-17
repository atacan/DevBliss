import BlissTheme
import Foundation

#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

public enum EditorAttributedStrings {
    public static func regular(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: regularAttributes)
    }

    public static func error(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: errorAttributes)
    }

    private static var regularAttributes: [NSAttributedString.Key: Any] {
        #if os(macOS)
            [
                .foregroundColor: NSColor(ThemeColor.Text.editedText),
                .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            ]
        #elseif os(iOS)
            [
                .foregroundColor: UIColor(ThemeColor.Text.editedText),
                .font: UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular),
            ]
        #endif
    }

    private static var errorAttributes: [NSAttributedString.Key: Any] {
        #if os(macOS)
            [
                .foregroundColor: NSColor(ThemeColor.Text.failure),
                .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            ]
        #elseif os(iOS)
            [
                .foregroundColor: UIColor(ThemeColor.Text.failure),
                .font: UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular),
            ]
        #endif
    }
}

public extension NSMutableAttributedString {
    func removeBackgroundColors() {
        enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: length), options: []) { value, range, _ in
            guard value != nil else { return }
            removeAttribute(.backgroundColor, range: range)
        }
    }
}
