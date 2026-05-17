import BlissTheme
import SharedModels
import SwiftUI

public struct SendToToolButton: View {
    @State private var isPopoverVisible = false

    private let title: String
    private let tools: [Tool]
    private let onSelect: (Tool) -> Void

    public init(
        _ title: String = "Send",
        tools: [Tool] = Tool.allCases.filter { $0.isActive && $0.isInputtable },
        onSelect: @escaping (Tool) -> Void
    ) {
        self.title = title
        self.tools = tools
        self.onSelect = onSelect
    }

    public var body: some View {
        EditorFooterButton(title, systemImage: "wand.and.rays.inverse") {
            isPopoverVisible = true
        }
        .keyboardShortcut("u", modifiers: [.command, .shift])
        .help("Input it to the other tools (Command+Shift+U)")
        .accessibilityLabel("Input it to the other tools")
        .popover(isPresented: $isPopoverVisible) {
            VStack(alignment: .leading) {
                #if os(iOS)
                    HStack {
                        Spacer()
                        Button {
                            isPopoverVisible = false
                        } label: {
                            Image(systemName: "xmark.circle")
                                .opacity(0.8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close pop over")
                    }
                    .padding(.bottom)
                #endif

                HStack(alignment: .lastTextBaseline) {
                    Image(systemName: "square.and.pencil")
                    Text("Move the output to one of the tools as input")
                        .lineLimit(nil)
                        .font(.headline)
                }
                .padding(.bottom)

                ForEach(tools) { tool in
                    Button {
                        isPopoverVisible = false
                        onSelect(tool)
                    } label: {
                        Text(tool.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.01))
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
            .padding()
        }
    }
}
