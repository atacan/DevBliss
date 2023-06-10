import ComposableArchitecture
import InputOutput
import SwiftUI

struct ContentView: View {
    var body: some View {
        InputOutputEditorsView(
            store: Store(
                initialState: InputOutputEditorsReducer.State(
                    input: "",
                    output: .init()
                ),
                reducer: InputOutputEditorsReducer()._printChanges()
            ),
            inputEditorTitle: "Input",
            outputEditorTitle: "Output"
        )

        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
