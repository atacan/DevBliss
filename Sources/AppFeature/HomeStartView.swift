import SwiftUI

struct HomeStartView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                Spacer()
                Image(systemName: "sidebar.squares.left")
                Text(NSLocalizedString("Navigation", bundle: Bundle.module, comment: ""))
                Spacer()
            } // <-HStack
            .font(.title)
            .padding()

            VStack(alignment: .description, spacing: 8) {
                HStack {
                    Text("⌘1, ⌘2")
                    Text("Go to a tool by order")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌃⇥")
                    Text("Go to the next tool")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌥⌃⇥")
                    Text("Go to the previous tool")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
            }
            .font(.title2)

            HStack(alignment: .center) {
                Spacer()
                Image(systemName: "hammer")
                Text(NSLocalizedString("Tool Usage", bundle: Bundle.module, comment: ""))
                Spacer()
            } // <-HStack
            .font(.title)
            .padding()

            VStack(alignment: .description, spacing: 8) {
                HStack {
                    Text("⌘⏎")
                    Text("Generate output")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⇧C")
                    Text("Copy output")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⇧S")
                    Text("Save output as...")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘U")
                    Text("Move output to another tool")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⇧P")
                    Text("Past to Input")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
            } // <-VStack
            .font(.title2)

            HStack(alignment: .center) {
                Spacer()
                Image(systemName: "square.split.diagonal")
                Text(NSLocalizedString("Layout", bundle: Bundle.module, comment: ""))
                Spacer()
            } // <-HStack
            .font(.title)
            .padding()

            VStack(alignment: .description, spacing: 8) {
                HStack {
                    Text("⌘⇧L")
                    Text("Toggle sidebar")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⇧A")
                    Text("Toggle split alignment")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⌥L")
                    Text("Toggle input editor")
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
            } // <-VStack
            .font(.title2)
        }
        .frame(maxWidth: 400)
    }
}

#Preview {
    HomeStartView()
    //        .frame(width: 400)
}

extension HorizontalAlignment {
    struct Descriptions: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            d[.leading]
        }
    }

    static let description = HorizontalAlignment(Descriptions.self)
}

extension HorizontalAlignment {
    struct KeyboardShortcuts: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            d[.leading]
        }
    }

    static let keyboardShortcut = HorizontalAlignment(KeyboardShortcuts.self)
}
