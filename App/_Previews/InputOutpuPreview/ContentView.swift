import ComposableArchitecture
import InputOutput
import SwiftUI

struct ContentView: View {
    var body: some View {
        InputOutputView(
            store: Store(
                initialState: InputOutputReducer.State(
                    input: "",
                    output: ""
                ),
                reducer: InputOutputReducer()._printChanges()
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
