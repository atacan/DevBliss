import Foundation

enum WordCase {
    case capital
    case lowercase
    case uppercase

    static func format(_ word: String, of kase: Self) -> String {
        switch kase {
        case .capital:
            return word.capitalized
        case .lowercase:
            return word.lowercased()
        case .uppercase:
            return word.uppercased()
        }
    }
}

enum WordCaseSplitSeparator {
    case singleCharacter(Character)
    case regex([String])
}

public enum WordGroupCase: String, CaseIterable, Identifiable {
    case snake
    case kebab
    case camel
    case pascal
    case title
    //    case sentence

    public var id: Self { self }

    var textStyleType: TextStyle.Type {
        switch self {
        case .snake:
            return Snake.self
        case .kebab:
            return Kebab.self
        case .camel:
            return Camel.self
        case .pascal:
            return Pascal.self
        case .title:
            return Title.self
        //    case .sentence:
        //        return Sentence.self
        //        default:
        //            return Snake.self
        }
    }
}

public enum WordGroupSeperator: Character, CaseIterable, Identifiable {
    case newLine = "\n"
    case space = " "

    public var id: Self { self }

    public var name: String {
        switch self {
        case .newLine:
            return NSLocalizedString("New Line", bundle: Bundle.main, comment: "")
        case .space:
            return NSLocalizedString("Space", bundle: Bundle.main, comment: "")
        }
    }
}

protocol TextStyle {
    static var style: WordGroupCase { get }
    static var separator: String { get }
    static var splitSeparator: WordCaseSplitSeparator { get }
    static var firstWordCase: WordCase { get }
    static var restWordCase: WordCase { get }
    var content: String { get set }
    init(content: String)
    init(components: [String])
}

extension TextStyle {
    func split() -> [String] {
        switch Self.splitSeparator {
        case let .singleCharacter(sep):
            return content.split(separator: sep).map { String($0) }
        case let .regex(regexPatterns):
            var output = content
            let sep = Character("*")
            for pattern in regexPatterns {
                let regex = try? NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: output.count)
                if let outputInter = regex?
                    .stringByReplacingMatches(
                        in: output,
                        options: [],
                        range: range,
                        withTemplate: "$1\(sep)$2"
                    )
                {
                    output = outputInter
                }
            }
            return output.split(separator: sep).map(String.init)
        }
    }

    static func join(_ components: [String]) -> String {
        components.enumerated()
            .map {
                $0.offset == 0
                    ? WordCase.format(String($0.element), of: Self.firstWordCase)
                    : WordCase.format(String($0.element), of: Self.restWordCase)
            }
            .joined(separator: Self.separator)
    }
}

struct Kebab: TextStyle {
    static var style = WordGroupCase.camel
    static var separator = "-"
    static var splitSeparator = WordCaseSplitSeparator.singleCharacter(Character(Self.separator))
    static var firstWordCase = WordCase.lowercase
    static var restWordCase = WordCase.lowercase

    var content: String

    init(content: String) {
        self.content = content
    }

    init(components: [String]) {
        self.content = Self.join(components)
    }
}

struct Snake: TextStyle {
    static var style = WordGroupCase.snake
    static var separator = "_"
    static var splitSeparator = WordCaseSplitSeparator.singleCharacter(Character(Self.separator))
    static var firstWordCase = WordCase.lowercase
    static var restWordCase = WordCase.lowercase
    var content: String

    init(content: String) {
        self.content = content
    }

    init(components: [String]) {
        self.content = ""
        self.content = Self.join(components)
    }
}

struct Title: TextStyle {
    static var style = WordGroupCase.title
    static var separator = " "
    static var splitSeparator = WordCaseSplitSeparator.singleCharacter(Character(Self.separator))
    static var firstWordCase = WordCase.capital
    static var restWordCase = WordCase.capital
    var content: String

    init(content: String) {
        self.content = content
    }

    init(components: [String]) {
        self.content = ""
        self.content = Self.join(components)
    }
}

struct Camel: TextStyle {
    static var style = WordGroupCase.camel
    static var separator = ""
    static var splitSeparator =
        WordCaseSplitSeparator
        .regex(["([A-Z]+)([A-Z][a-z]|[0-9])", "([a-z])([A-Z]|[0-9])", "([0-9])([A-Z])"])
    static var firstWordCase = WordCase.lowercase
    static var restWordCase = WordCase.capital
    var content: String

    init(content: String) {
        self.content = content
    }

    init(components: [String]) {
        self.content = ""
        self.content = Self.join(components)
    }
}

struct Pascal: TextStyle {
    static var style = WordGroupCase.camel
    static var separator = ""
    static var splitSeparator =
        WordCaseSplitSeparator
        .regex(["([A-Z]+)([A-Z][a-z]|[0-9])", "([a-z])([A-Z]|[0-9])", "([0-9])([A-Z])"])
    static var firstWordCase = WordCase.capital
    static var restWordCase = WordCase.capital
    var content: String

    init(content: String) {
        self.content = content
    }

    init(components: [String]) {
        self.content = ""
        self.content = Self.join(components)
    }
}
