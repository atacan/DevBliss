import BlissTheme
import ComposableArchitecture
import SharedModels
import SwiftUI
import UnixTimeClient

@Reducer
public struct UnixTimeReducer {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        @Shared(.toolInput("unixTime")) public var inputText = ""
        @Shared(.toolOutput("unixTime")) public var outputText = ""
        var isConversionRequestInFlight = false
        var mode: UnixTimeMode = .unixToDate
        var autoDetect: Bool = true
        var selectedTimezone: String = "UTC"
        var result: UnixTimeResult?
        var errorMessage: String?

        // Input is derived from inputText for persistence
        public var input: String {
            get { inputText }
            set { $inputText.withLock { $0 = newValue } }
        }

        public init() {}

        public init(input: String, output: String = "") {
            self._inputText = Shared(wrappedValue: input, .toolInput("unixTime"))
            self._outputText = Shared(wrappedValue: output, .toolOutput("unixTime"))
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case convertButtonTouched
        case nowButtonTouched
        case conversionResponse(TaskResult<UnixTimeResult>)
    }

    @Dependency(\.unixTime) var unixTime
    private enum CancelID { case conversionRequest }

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.input):
                // Auto-detect input type if enabled
                if state.autoDetect {
                    let input = state.input.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let _ = Double(input) {
                        state.mode = .unixToDate
                    } else if !input.isEmpty {
                        state.mode = .dateToUnix
                    }
                }
                return .none

            case .binding:
                return .none

            case .nowButtonTouched:
                let timestamp = unixTime.currentTimestamp()
                let timestampString = String(Int(timestamp))
                state.mode = .unixToDate
                state.$inputText.withLock { $0 = timestampString }
                return .send(.convertButtonTouched)

            case .convertButtonTouched:
                state.errorMessage = nil
                let input = state.input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !input.isEmpty else {
                    state.errorMessage = "Please enter a value"
                    return .none
                }
                state.isConversionRequestInFlight = true
                let mode = state.mode
                return .run { [unixTime] send in
                    await send(
                        .conversionResponse(
                            TaskResult {
                                try await unixTime.convert(input, mode)
                            }
                        )
                    )
                }
                .cancellable(id: CancelID.conversionRequest, cancelInFlight: true)

            case let .conversionResponse(.success(result)):
                state.isConversionRequestInFlight = false
                state.result = result
                return .none

            case let .conversionResponse(.failure(error)):
                state.isConversionRequestInFlight = false
                state.result = nil
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}

public struct UnixTimeView: View {
    @Perception.Bindable var store: StoreOf<UnixTimeReducer>

    public init(store: StoreOf<UnixTimeReducer>) {
        self.store = store
    }

    private static let commonTimezones: [(String, String)] = [
        ("UTC", "UTC"),
        ("America/New_York", "New York (EST/EDT)"),
        ("America/Los_Angeles", "Los Angeles (PST/PDT)"),
        ("America/Chicago", "Chicago (CST/CDT)"),
        ("Europe/London", "London (GMT/BST)"),
        ("Europe/Paris", "Paris (CET/CEST)"),
        ("Europe/Berlin", "Berlin (CET/CEST)"),
        ("Asia/Tokyo", "Tokyo (JST)"),
        ("Asia/Shanghai", "Shanghai (CST)"),
        ("Asia/Singapore", "Singapore (SGT)"),
        ("Asia/Dubai", "Dubai (GST)"),
        ("Australia/Sydney", "Sydney (AEST/AEDT)"),
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Input section: TextField + Now + Convert
            HStack(spacing: 12) {
                TextField("Enter Unix timestamp or date", text: $store.input)
                    .blissTextField()
                    .onSubmit {
                        store.send(.convertButtonTouched)
                    }

                Button {
                    store.send(.nowButtonTouched)
                } label: {
                    Label("Now", systemImage: "clock")
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("n", modifiers: [.command])
                .help("Insert current timestamp (⌘N)")

                LoadingButton("Convert", isLoading: store.isConversionRequestInFlight) {
                    store.send(.convertButtonTouched)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Convert (⌘ Return)")
                .disabled(store.input.isEmpty || store.isConversionRequestInFlight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Error message
            if let errorMessage = store.errorMessage {
                ErrorMessageView(errorMessage)
            }

            // Options row
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Mode")
                    Picker("Mode", selection: $store.mode) {
                        ForEach(UnixTimeMode.allCases) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 200)

                    Toggle("Auto-detect", isOn: $store.autoDetect)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                        .help("Automatically detect if input is Unix timestamp or date")

                    Picker("Timezone", selection: $store.selectedTimezone) {
                        ForEach(Self.commonTimezones, id: \.0) { tz in
                            Text(tz.1).tag(tz.0)
                        }
                    }
                    .blissMenuPicker(width: 180)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            // Results display
            if let result = store.result {
                ScrollView {
                    resultCardsView(result)
                        .padding()
                }
            } else {
                Spacer()
                Text("Enter a Unix timestamp or date and click Convert")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func resultCardsView(_ result: UnixTimeResult) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 400), spacing: 16)], spacing: 16) {
            ResultCard(title: "Unix Timestamp", value: result.unixTimestamp, icon: "number")
            ResultCard(title: "Local Time", value: result.localTimeWithTimezone, icon: "clock")
            ResultCard(title: "UTC (ISO 8601)", value: result.utcISO8601, icon: "globe")
            ResultCard(title: "Relative", value: result.relativeTime, icon: "calendar.badge.clock")
            ResultCard(title: "Day of Year", value: "\(result.dayOfYear)", icon: "calendar")
            ResultCard(title: "Week of Year", value: "\(result.weekOfYear)", icon: "calendar.day.timeline.left")
            ResultCard(title: "Leap Year", value: result.isLeapYear ? "Yes" : "No", icon: result.isLeapYear ? "checkmark.circle.fill" : "xmark.circle")

            if let additionalTz = result.additionalTimezoneTime {
                ResultCard(title: "Additional Timezone", value: additionalTz, icon: "globe.americas")
            }
        }
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    #else
                    UIPasteboard.general.string = value
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Copy to clipboard")
            }

            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(macOS)
        .background(ThemeColor.Background.controlBackground)
        #else
        .background(Color(uiColor: .secondarySystemBackground))
        #endif
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

struct UnixTimeReducer_Previews: PreviewProvider {
    static var previews: some View {
        UnixTimeView(store: .init(initialState: .init()) { UnixTimeReducer() })
    }
}
