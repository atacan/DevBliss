import AppFeature
import Cocoa
import ComposableArchitecture
import HtmlToSwiftFeature
import SwiftUI
import UniformTypeIdentifiers

// let appContentview = AppContentView()
// let appContentview = Text("Testing Text").font(.largeTitle)
let appContentview = HtmlToSwiftView(
    store: Store(
        initialState: .init(),
        reducer: HtmlToSwiftReducer()
    )
)

extension View {
    func renderAsImage() -> NSImage? {
        let view = NoInsetHostingView(rootView: self)
//        view.setFrameSize(view.fittingSize)
        view.setFrameSize(.init(width: 1340, height: 680))
        return view.bitmapImage()
    }
}

class NoInsetHostingView<V>: NSHostingView<V> where V: View {
    override var safeAreaInsets: NSEdgeInsets {
        .init()
    }
}

extension NSView {
    func bitmapImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: rep)
        guard let cgImage = rep.cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}

extension NSImage {
    func save(
        as fileName: String,
        fileType: NSBitmapImageRep.FileType = .jpeg,
        at directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    ) -> Bool {
        guard let tiffRepresentation, directory.isDirectory, !fileName.isEmpty else {
            return false
        }
        do {
            try NSBitmapImageRep(data: tiffRepresentation)?
                .representation(using: fileType, properties: [:])?
                .write(to: directory.appendingPathComponent(fileName).appendingPathExtension(fileType.pathExtension))
            return true
        } catch {
            print(error)
            return false
        }
    }
}

extension NSImage {
    func saveHigh(
        as fileName: String,
        fileType: NSBitmapImageRep.FileType = .jpeg,
        at directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        dpi: CGFloat = 300,
        compressionFactor: CGFloat = 1.0
    ) -> Bool {
        guard let tiffRepresentation, directory.isDirectory, !fileName.isEmpty else {
            return false
        }
        do {
            let imageRep = NSBitmapImageRep(data: tiffRepresentation)!
            let imageSize = NSSize(width: size.width * dpi / 72.0, height: size.height * dpi / 72.0)
            imageRep.size = imageSize
            let properties: [NSBitmapImageRep.PropertyKey: Any] = [
                .compressionFactor: compressionFactor,
            ]
            try imageRep.representation(using: fileType, properties: properties)?
                .write(to: directory.appendingPathComponent(fileName).appendingPathExtension(fileType.pathExtension))
            return true
        } catch {
            print(error)
            return false
        }
    }
}

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

extension NSBitmapImageRep.FileType {
    var pathExtension: String {
        switch self {
        case .bmp:
            return "bmp"
        case .gif:
            return "gif"
        case .jpeg:
            return "jpg"
        case .jpeg2000:
            return "jp2"
        case .png:
            return "png"
        case .tiff:
            return "tif"
        @unknown default:
            return "jpeg"
        }
    }
}

let folderUrl = URL(fileURLWithPath: "/Users/atacan/Documents/myway/repositories/DevBliss/images")
print(folderUrl)

let nsimage = appContentview.renderAsImage()!
let didSave = nsimage.save(
    as: "app-content",
    fileType: .png,
    at: URL(fileURLWithPath: "/Users/atacan/Documents/myway/repositories/DevBliss/images")
)

let image = appContentview.renderAsImage()
let highSaved = image?.saveHigh(
    as: "high-myImage",
    fileType: .png,
    at: URL(fileURLWithPath: "/Users/atacan/Documents/myway/repositories/DevBliss/images"),
    dpi: 1600,
    compressionFactor: 0.8
)

import AppImageGenerator

ViewInsideMacbookApp.main()
