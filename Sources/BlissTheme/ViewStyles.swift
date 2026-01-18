import SwiftUI

// MARK: - Button Styles

public extension View {
    /// Primary action button style: borderedProminent, large control size
    func blissPrimaryButton() -> some View {
        self
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
}

// MARK: - TextField Styles

public extension View {
    /// Standard text field style with border and background
    func blissTextField() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(8)
            #if os(macOS)
            .background(Color(nsColor: .textBackgroundColor))
            #else
            .background(Color(uiColor: .secondarySystemBackground))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    #if os(macOS)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    #else
                    .stroke(Color(uiColor: .separator), lineWidth: 1)
                    #endif
            )
    }

    /// Compact text field style for configuration grids
    func blissCompactTextField() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(6)
            #if os(macOS)
            .background(Color(nsColor: .textBackgroundColor))
            #else
            .background(Color(uiColor: .secondarySystemBackground))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    #if os(macOS)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    #else
                    .stroke(Color(uiColor: .separator), lineWidth: 1)
                    #endif
            )
    }
}

// MARK: - Picker Styles

public extension View {
    /// Menu picker style with fixed width for configuration grids
    func blissMenuPicker(width: CGFloat = 180) -> some View {
        self
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: width, alignment: .leading)
    }
}
