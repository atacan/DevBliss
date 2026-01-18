import SwiftUI

// MARK: - Configuration Label

/// Right-aligned label for configuration grids
public struct ConfigLabel: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .gridColumnAlignment(.trailing)
    }
}

// MARK: - Configuration Section

/// Collapsible disclosure group for tool configuration options
public struct ConfigurationSection<Content: View>: View {
    let title: String
    let content: Content

    public init(
        _ title: String = "Configuration",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        DisclosureGroup(title) {
            content
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Error Display

/// Standardized error message display
public struct ErrorMessageView: View {
    let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .foregroundStyle(.red)
            Spacer()
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
