import SwiftUI
import UniformTypeIdentifiers

private struct URLDropDelegate: DropDelegate {
    @Binding var isDropInProgress: Bool

    let acceptedTypes: [UTType]
    let onDropEntered: () -> Void
    let onDropExited: () -> Void
    let onURLsDropped: ([URL]) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: acceptedTypes)
    }

    func dropEntered(info: DropInfo) {
        isDropInProgress = true
        onDropEntered()
    }

    func performDrop(info: DropInfo) -> Bool {
        let group = DispatchGroup()
        let lock = NSLock()
        var loadedURLs: [URL] = []

        for itemProvider in info.itemProviders(for: acceptedTypes) {
            for type in acceptedTypes {
                group.enter()
                itemProvider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, _ in
                    defer { group.leave() }

                    let url: URL?
                    if let itemURL = item as? URL {
                        url = itemURL
                    }
                    else if let urlString = item as? String {
                        url = URL(string: urlString)
                    }
                    else if let data = item as? Data {
                        url = URL(dataRepresentation: data, relativeTo: nil)
                    }
                    else {
                        url = nil
                    }

                    guard let url else { return }
                    lock.lock()
                    loadedURLs.append(url)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            isDropInProgress = false
            if !loadedURLs.isEmpty {
                onURLsDropped(loadedURLs)
            }
        }

        return true
    }

    func dropExited(info: DropInfo) {
        isDropInProgress = false
        onDropExited()
    }
}

public struct URLDropOverlay: View {
    @State private var isDropInProgress = false
    @State private var phase: CGFloat = 0

    private let acceptedTypes: [UTType]
    private let onDropEntered: () -> Void
    private let onDropExited: () -> Void
    private let onURLsDropped: ([URL]) -> Void

    public init(
        acceptedTypes: [UTType],
        onDropEntered: @escaping () -> Void = {},
        onDropExited: @escaping () -> Void = {},
        onURLsDropped: @escaping ([URL]) -> Void
    ) {
        self.acceptedTypes = acceptedTypes
        self.onDropEntered = onDropEntered
        self.onDropExited = onDropExited
        self.onURLsDropped = onURLsDropped
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(
                style: .init(
                    lineWidth: 4,
                    lineCap: .round,
                    lineJoin: .round,
                    miterLimit: 1,
                    dash: [10],
                    dashPhase: phase
                )
            )
            .padding(4)
            .foregroundStyle(isDropInProgress ? Color.accentColor : Color.clear)
            .animation(
                Animation.linear(duration: 2)
                    .repeatForever(autoreverses: false),
                value: phase
            )
            .onAppear {
                phase = 20
            }
            .onDrop(
                of: acceptedTypes,
                delegate: URLDropDelegate(
                    isDropInProgress: $isDropInProgress,
                    acceptedTypes: acceptedTypes,
                    onDropEntered: onDropEntered,
                    onDropExited: onDropExited,
                    onURLsDropped: onURLsDropped
                )
            )
    }
}

public struct DroppedTextFileOverlay: View {
    private let onTextDropped: @MainActor (String) -> Void

    public init(onTextDropped: @escaping @MainActor (String) -> Void) {
        self.onTextDropped = onTextDropped
    }

    public var body: some View {
        URLDropOverlay(acceptedTypes: [.fileURL]) { urls in
            Task {
                let text = await loadText(from: urls)
                guard !text.isEmpty else { return }
                onTextDropped(text)
            }
        }
    }

    private func loadText(from urls: [URL]) async -> String {
        await Task.detached {
            urls.compactMap { url in
                try? String(contentsOf: url, encoding: .utf8)
            }
            .joined(separator: "\n")
        }
        .value
    }
}
