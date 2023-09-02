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
                    Text(NSLocalizedString("Go to a tool by order", bundle: Bundle.module, comment: ""))
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌃⇥")
                    Text(NSLocalizedString("Go to the next tool", bundle: Bundle.module, comment: ""))
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌥⌃⇥")
                    Text(NSLocalizedString("Go to the previous tool", bundle: Bundle.module, comment: ""))
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
                    Text(NSLocalizedString("Generate output", bundle: Bundle.module, comment: ""))
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⇧C")
                    Text(NSLocalizedString("Copy output", bundle: Bundle.module, comment: ""))
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⇧S")
                    Text(NSLocalizedString("Save output as...", bundle: Bundle.module, comment: ""))
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘U")
                    Text(NSLocalizedString("Move output to another tool", bundle: Bundle.module, comment: ""))
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⇧P")
                    Text(NSLocalizedString("Paste to Input", bundle: Bundle.module, comment: ""))
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
                    Text(NSLocalizedString("Toggle sidebar", bundle: Bundle.module, comment: ""))
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⇧A")
                    Text(NSLocalizedString("Toggle split alignment", bundle: Bundle.module, comment: ""))
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
                HStack {
                    Text("⌘⌥L")
                    Text(NSLocalizedString("Toggle input editor", bundle: Bundle.module, comment: ""))
                        .alignmentGuide(.description) { d in d[HorizontalAlignment.leading] }
                }
            } // <-VStack
            .font(.title2)
        }
        .frame(maxWidth: 400)
    }
}

// #Preview {
//    HomeStartView()
//            .frame(width: 400)
// }

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
