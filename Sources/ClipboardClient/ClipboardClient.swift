import Dependencies

public struct ClipboardClient: DependencyKey {
    public var copyString: (String) -> Void
    public var getString: () -> String?
}

#if os(macOS)
    import Cocoa

    extension ClipboardClient {
        public static var liveValue: Self {
            Self(
                copyString: { text in
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                },
                getString: { NSPasteboard.general.string(forType: .string) }
            )
        }
    }
#endif

#if os(iOS)
    import UIKit

    extension ClipboardClient {
        public static var liveValue: Self {
            Self(
                copyString: { text in
                    UIPasteboard.general.string = text
                },
                getString: { UIPasteboard.general.string }
            )
        }
    }
#endif

extension DependencyValues {
    public var clipboard: ClipboardClient.Value {
        get { self[ClipboardClient.self] }
        set { self[ClipboardClient.self] = newValue }
    }
}
