//
// https://github.com/atacan
// 19.06.23
	

import SwiftUI
import FilePanelsClient
import Dependencies
import Foundation

struct ContentView: View {
    @Dependency(\.filePanels) var filePanels
    @State var openPanelURL: URL = .init(filePath: "")
    @State var savePanelURL: URL = .init(filePath: "")
    @State var openPanelContent: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Group{
                Text("Testing if ended **Open** panel's url can still be used")
                Button("Open Panel URL") {
                    openPanelURL = filePanels.openPanel()
                }
                Text(openPanelURL.relativePath)
                Text(openPanelURL.path())
                Text(openPanelURL.relativeString)
                Button("Read Open Panel URL") {
                    do {
                        openPanelContent = try String(contentsOf: openPanelURL)
                    } catch {
                        openPanelContent = "\(error)"
                    }
                }
                TextEditor(text: $openPanelContent)
            }
            
            Text("Testing if ended **Save** panel's url can still be used")
            Button("Save Panel URL") {
                savePanelURL = filePanels.savePanel(.init())
            }
            Text(savePanelURL.absoluteString)
            Button("Save to Save Panel URL") {
                do {
                    try "slkdfjaslkfjklasd\naslkfjklsdjfl\n\njsadflkjasklfjlkasjf".write(to: savePanelURL, atomically: true, encoding: .utf8)
                } catch {
                    openPanelContent = "\(error)"
                }
            }
//            TextEditor(text: $openPanelContent)
        }
        .padding()
    }
}

