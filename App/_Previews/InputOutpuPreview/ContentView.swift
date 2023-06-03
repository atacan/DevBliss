//
// https://github.com/atacan
// 03.06.23
	

import SwiftUI
import ComposableArchitecture
import InputOutput

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
