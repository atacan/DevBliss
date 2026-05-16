import BlissTheme
import Dependencies
import JSDiff
import JSDiffUI
import Observation
import SharedModels
import Sharing
import SplitView
import SwiftUI

@MainActor
@Observable
public final class StringDiffModel {
    @ObservationIgnored
    @Shared(.toolInput("stringDiff")) public var oldText = ""

    @ObservationIgnored
    @Shared(.toolOutput("stringDiff")) public var newText = ""

    public var diffType: DiffType = .lines
    public var displayStyle: DiffDisplayStyle = .inline
    public var changes: [Change] = []
    public var isComputing = false

    @ObservationIgnored
    @Dependency(\.stringDiff) private var stringDiff

    @ObservationIgnored
    private var diffTask: Task<Void, Never>?

    public init() {
        let oldText = Shared(wrappedValue: "", .toolInput("stringDiff"))
        let newText = Shared(wrappedValue: "", .toolOutput("stringDiff"))
        self._oldText = oldText
        self._newText = newText
    }

    public init(oldText: String, newText: String = "") {
        let oldText = Shared(wrappedValue: oldText, .toolInput("stringDiff"))
        let newText = Shared(wrappedValue: newText, .toolOutput("stringDiff"))
        self._oldText = oldText
        self._newText = newText
        scheduleDiff()
    }

    public func setOldText(_ value: String) {
        oldText = value
        scheduleDiff()
    }

    public func setNewText(_ value: String) {
        newText = value
        scheduleDiff()
    }

    public func setDiffType(_ value: DiffType) {
        guard diffType != value else { return }
        diffType = value
        scheduleDiff()
    }

    public func convertButtonTouched() {
        scheduleDiff()
    }

    public func cancel() {
        diffTask?.cancel()
        diffTask = nil
        isComputing = false
    }

    private func scheduleDiff() {
        diffTask?.cancel()
        isComputing = true

        let old = oldText
        let new = newText
        let type = diffType

        diffTask = Task { [weak self, old = old, new = new, type = type, stringDiff = stringDiff] in
            guard let self else { return }
            do {
                let result = try await stringDiff.diff(type, old, new)
                await MainActor.run {
                    isComputing = false
                    changes = result
                }
            } catch {
                await MainActor.run {
                    isComputing = false
                    changes = []
                }
            }
        }
    }
}

extension StringDiffModel: Equatable {
    public static func == (lhs: StringDiffModel, rhs: StringDiffModel) -> Bool {
        lhs === rhs
    }
}

public struct StringDiffModelView: View {
    @Bindable var model: StringDiffModel
    let fraction = FractionHolder.usingUserDefaults(0.5, key: SettingsKey.StringDiff.splitViewFraction)
    @StateObject var layout = LayoutHolder.usingUserDefaults(.vertical, key: SettingsKey.StringDiff.splitViewLayout)
    @StateObject var hide = SideHolder()

    public init(model: StringDiffModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            optionsView

            Divider()

            VSplit(top: { editorsPane }, bottom: { diffResultView })
                .fraction(fraction)
                .hide(hide)
                .styling(visibleThickness: 2)
        }
    }

    private var optionsView: some View {
        HStack(spacing: 12) {
            Picker(
                NSLocalizedString("Diff Type", comment: ""),
                selection: Binding(
                    get: { model.diffType },
                    set: { model.setDiffType($0) }
                )
            ) {
                ForEach(DiffType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .fixedSize()
            .help(NSLocalizedString("Select the granularity of the diff", comment: ""))

            Divider().frame(height: 20)

            DiffStylePicker(
                displayStyle: Binding(
                    get: { model.displayStyle },
                    set: { model.displayStyle = $0 }
                )
            )
            .fixedSize()

            Spacer()

            if model.isComputing {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var editorsPane: some View {
        HStack(spacing: 0) {
            TextEditor(
                text: Binding(
                    get: { model.oldText },
                    set: { model.setOldText($0) }
                )
            )
            .font(.system(.body, design: .monospaced))
            .padding(8)
            .background(ThemeColor.Background.textBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ThemeColor.Background.separator, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                Text("Original")
                    .padding(4)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            TextEditor(
                text: Binding(
                    get: { model.newText },
                    set: { model.setNewText($0) }
                )
            )
            .font(.system(.body, design: .monospaced))
            .padding(8)
            .background(ThemeColor.Background.textBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ThemeColor.Background.separator, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                Text("Modified")
                    .padding(4)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var diffResultView: some View {
        if model.changes.isEmpty && !model.isComputing {
            VStack {
                Spacer()
                Text(NSLocalizedString("Enter text in both editors to see the diff", comment: ""))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } else {
            ScrollView([.horizontal, .vertical]) {
                DiffView(
                    changes: model.changes,
                    displayStyle: model.displayStyle
                )
                .font(.system(.body, design: .monospaced))
            }
        }
    }
}

struct StringDiffModelView_Previews: PreviewProvider {
    static var previews: some View {
        StringDiffModelView(model: .init())
    }
}

// MARK: - Dependency

public struct StringDiffClient {
    public var diff: @Sendable (DiffType, String, String) async -> [Change]

    public init(diff: @escaping @Sendable (DiffType, String, String) async -> [Change]) {
        self.diff = diff
    }
}

extension StringDiffClient: DependencyKey {
    public static let liveValue = Self(
        diff: { type, old, new in
            guard let jsDiff = JSDiff() else { return [] }
            return await jsDiff.diff(type, old, new)
        }
    )
}

public extension DependencyValues {
    var stringDiff: StringDiffClient {
        get { self[StringDiffClient.self] }
        set { self[StringDiffClient.self] = newValue }
    }
}
