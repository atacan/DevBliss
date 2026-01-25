import SwiftUI

/// A primary action button that shows a loading indicator when isLoading is true
public struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    public init(
        _ title: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(minWidth: 80)
        }
        .blissPrimaryButton()
    }
}
