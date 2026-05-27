import BlissTheme
import Dependencies
import Foundation
import Sharing
import SharedModels
import SwiftUI

@MainActor
@Observable
public final class UnixTimeModel {
    @ObservationIgnored
    @Shared(.toolInput("unixTime"))
    public var inputText = ""

    @ObservationIgnored
    @Shared(.toolOutput("unixTime"))
    public var outputText = ""

    public var isConversionRequestInFlight = false
    public var mode: UnixTimeMode = .unixToDate
    public var autoDetect: Bool = true
    public var selectedTimezone: String = "UTC"
    public var result: UnixTimeResult?
    public var errorMessage: String?

    @ObservationIgnored
    @Dependency(\.unixTime) private var unixTime

    @ObservationIgnored
    private var conversionTask: Task<Void, Never>?

    public var input: String {
        get { inputText }
        set {
            $inputText.withLock { $0 = newValue }
            guard autoDetect else { return }
            let input = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let _ = Double(input) {
                mode = .unixToDate
            } else if !input.isEmpty {
                mode = .dateToUnix
            }
        }
    }

    public init() {}

    public init(input: String, output: String = "") {
        self._inputText = Shared(wrappedValue: input, .toolInput("unixTime"))
        self._outputText = Shared(wrappedValue: output, .toolOutput("unixTime"))
    }

    public func nowButtonTouched() {
        mode = .unixToDate
        $inputText.withLock { $0 = String(Int(unixTime.currentTimestamp())) }
        convertButtonTouched()
    }

    public func convertButtonTouched() {
        conversionTask?.cancel()
        errorMessage = nil

        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            errorMessage = "Please enter a value"
            result = nil
            $outputText.withLock { $0 = "" }
            isConversionRequestInFlight = false
            return
        }

        isConversionRequestInFlight = true
        let mode = self.mode

        conversionTask = Task { [unixTime, input, mode] in
            do {
                let output = try await unixTime.convert(input, mode)
                await MainActor.run {
                    isConversionRequestInFlight = false
                    result = output
                    $outputText.withLock { $0 = output.localTimeWithTimezone }
                }
            } catch {
                if error is CancellationError { return }
                await MainActor.run {
                    isConversionRequestInFlight = false
                    result = nil
                    errorMessage = error.localizedDescription
                    $outputText.withLock { $0 = "" }
                }
            }
        }
    }

    public func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isConversionRequestInFlight = false
    }
}

public struct UnixTimeModelView: View {
    @Bindable var model: UnixTimeModel

    public init(model: UnixTimeModel) {
        self.model = model
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

    private var inputField: some View {
        TextField("Enter Unix timestamp or date", text: Binding(
            get: { model.input },
            set: { model.input = $0 }
        ))
            .blissTextField()
            .onSubmit {
                model.convertButtonTouched()
            }
    }

    private var nowButton: some View {
        Button {
            model.nowButtonTouched()
        } label: {
            Label("Now", systemImage: "clock")
        }
        .buttonStyle(.bordered)
        .keyboardShortcut("n", modifiers: [.command])
        .help("Insert current timestamp (⌘N)")
    }

    private var convertButton: some View {
        LoadingButton("Convert", isLoading: model.isConversionRequestInFlight) {
            model.convertButtonTouched()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .help("Convert (⌘ Return)")
        .disabled(model.input.isEmpty || model.isConversionRequestInFlight)
    }

    private var modePicker: some View {
        Picker("Mode", selection: $model.mode) {
            ForEach(UnixTimeMode.allCases) { mode in
                Text(mode.rawValue)
                    .tag(mode)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    private var autoDetectToggle: some View {
        Toggle("Auto-detect", isOn: $model.autoDetect)
            .help("Automatically detect if input is Unix timestamp or date")
    }

    private var timezonePicker: some View {
        Picker("Timezone", selection: $model.selectedTimezone) {
            ForEach(Self.commonTimezones, id: \.0) { tz in
                Text(tz.1).tag(tz.0)
            }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = model.errorMessage {
                ErrorMessageView(errorMessage)
            }

            #if os(iOS)
            VStack(spacing: 10) {
                inputField
                HStack(spacing: 12) {
                    nowButton
                    convertButton
                }
                modePicker
                HStack(spacing: 16) {
                    autoDetectToggle
                    Spacer()
                }
                HStack {
                    Text("Timezone")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    timezonePicker
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #else
            HStack(spacing: 12) {
                inputField
                nowButton
                convertButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ConfigLabel("Mode")
                    modePicker
                        .frame(width: 200)

                    autoDetectToggle
                        .toggleStyle(.checkbox)

                    timezonePicker
                        .blissMenuPicker(width: 180)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            #endif

            Divider()

            if let result = model.result {
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

struct UnixTimeModelView_Previews: PreviewProvider {
    static var previews: some View {
        UnixTimeModelView(model: UnixTimeModel())
    }
}

private struct ResultCard: View {
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
            }

            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
