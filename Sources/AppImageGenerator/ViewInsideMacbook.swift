import ComposableArchitecture
import HtmlToSwiftFeature
import SwiftUI

struct ViewInsideMacbookView: View {
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(colors: [.indigo, .blue, .red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            RoundedRectangle(cornerRadius: 22)
                .frame(width: 1550, height: 990, alignment: .center)
                .foregroundColor(Color(nsColor: .windowBackgroundColor))
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 12) {
                        Circle().fill(.red)
                            .frame(width: 22)
                        Circle().fill(.yellow)
                            .frame(width: 22)
                        Circle().fill(.green)
                            .frame(width: 22)
                    }
                    .opacity(0.8)
                    .offset(x: 37, y: 32)
                }
            Image("MacBook", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 2200, height: 1600, alignment: .center)
            HtmlToSwiftView(store: Store(initialState: .init(), reducer: {
                HtmlToSwiftReducer()
            }))
            .frame(width: 1400, height: 900, alignment: .center)
        }
    }
}

struct ViewInsideMacbookView_Previews: PreviewProvider {
    static var previews: some View {
        ViewInsideMacbookView()
    }
}

public struct ViewInsideMacbookApp: App {
    public init() {}
    public var body: some Scene {
        WindowGroup {
            ViewInsideMacbookView()
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        #endif
    }
}
