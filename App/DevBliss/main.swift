

#if DEBUG
//    import InputOutput
//    InputEditorApp.main()
//     import HtmlToSwiftFeature
//     HtmlToSwiftApp.main()
//     import SwiftPrettyFeature
//     SwiftPrettyApp.main()
import RegexMatchesFeature

RegexMatchesApp.main()
//    import AppFeature
//    TheApp.main()
#if os(macOS)
//        import FileContentSearchFeature

//        FileContentSearchApp.main()
#endif
#else
import AppFeature

TheApp.main()
#endif
