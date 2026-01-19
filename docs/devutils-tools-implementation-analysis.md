# DevUtils Tools Implementation Analysis

This document analyzes each tool from DevUtils.app and provides recommendations for implementation in Swift for macOS/iOS applications.

For each tool, I've assessed:
- **Simple in Swift**: Can be easily implemented using Foundation APIs
- **Swift Package**: Available open-source Swift packages
- **JavaScript Solution**: JavaScript libraries compatible with JavaScriptCore

---

## 1. Unix Time Converter

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (Foundation)**

This is trivial to implement in Swift using Foundation's `Date`, `DateFormatter`, and `Calendar` APIs.

```swift
// All the functionality needed:
- Date(timeIntervalSince1970: timestamp)
- DateFormatter for formatting
- Calendar for day of year, week of year
- Calendar.isLeapYear()
```

**No external library needed.**

---

## 2. JSON Format/Validate

**Implementation Complexity**: ⭐⭐ Moderate

### Recommendation: **Hybrid Approach**

**Native Swift for basic validation**:
- `JSONSerialization` for basic parsing/formatting
- `JSONEncoder`/`JSONDecoder` for Codable types

**JavaScript for advanced features**:
- **Library**: [json-repair](https://github.com/josdejong/jsonrepair) - Repairs invalid JSON
- **Library**: [json5](https://github.com/json5/json5) - Supports trailing commas and comments
- **Library**: [jsonpath-plus](https://github.com/JSONPath-Plus/JSONPath) - JSONPath queries

These JavaScript libraries work well in JavaScriptCore and provide features that would be complex to reimplement in Swift.

---

## 3. Base64 String Encode/Decode

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (Foundation)**

Trivial using Foundation APIs:

```swift
// Encoding
let data = string.data(using: .utf8)
let base64 = data?.base64EncodedString()

// Decoding
let data = Data(base64Encoded: base64String)
let string = String(data: data, encoding: .utf8)
```

**No external library needed.**

---

## 4. Base64 Image Encode/Decode

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (Foundation + UIKit/AppKit)**

Simple to implement:

```swift
// Encoding
let imageData = image.pngData() // or jpegData()
let base64 = imageData.base64EncodedString()
let dataURL = "data:image/png;base64,\(base64)"

// Decoding
let data = Data(base64Encoded: base64String)
let image = UIImage(data: data) // or NSImage on macOS
```

**No external library needed.**

---

## 5. JWT Debugger

**Implementation Complexity**: ⭐⭐ Moderate

### Recommendation: **Swift Package**

**Swift Package**: [Auth0/JWTDecode.swift](https://github.com/auth0/JWTDecode.swift)
- Most popular Swift JWT decoder (695 stars)
- Actively maintained (last update: 3 days ago as of search)
- Supports iOS 14.0+, macOS 11.0+, tvOS 14.0+, watchOS 7.0+
- Zero data race safety errors
- MIT licensed
- Available via Swift Package Manager

**Alternative**: [Kitura/Swift-JWT](https://github.com/Kitura/Swift-JWT) - Full JWT encoding/decoding with signing

**JavaScript Alternative**: [jwt-decode](https://www.npmjs.com/package/jwt-decode) by Auth0
- Same functionality as Swift package
- Works in JavaScriptCore (may need `atob()` polyfill)

**Recommendation**: Use the Swift package - it's well-maintained and native.

---

## 6. RegExp Tester

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (Foundation)**

Swift has built-in regex support:

```swift
// NSRegularExpression (traditional)
let regex = try NSRegularExpression(pattern: pattern, options: options)
let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

// Swift Regex (modern - iOS 16+)
let regex = try Regex(pattern)
let matches = text.matches(of: regex)
```

The gear icon settings (flags) map directly to `NSRegularExpression.Options`:
- Case insensitive → `.caseInsensitive`
- Allow comments → `.allowCommentsAndWhitespace`
- Dot matches newlines → `.dotMatchesLineSeparators`
- Multiline → `.anchorsMatchLines`

**No external library needed.**

---

## 7. URL Encode/Decode

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (Foundation)**

Simple using Foundation:

```swift
// Encoding
let encoded = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

// For RFC3986 Standard (encode more characters)
var allowed = CharacterSet.urlQueryAllowed
allowed.remove(charactersIn: "!*'();:@&=+$,/?%#[]")
let encoded = string.addingPercentEncoding(withAllowedCharacters: allowed)

// For Form Data (+ for spaces)
let formEncoded = string.replacingOccurrences(of: " ", with: "+")
                        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

// Decoding
let decoded = string.removingPercentEncoding
```

**No external library needed.**

---

## 8. URL Parser

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (Foundation)**

Foundation's `URLComponents` provides everything needed:

```swift
let components = URLComponents(string: urlString)
let scheme = components?.scheme
let host = components?.host
let path = components?.path
let queryItems = components?.queryItems // Array of URLQueryItem
```

Query parameters can be easily converted to JSON dictionary.

**No external library needed.**

---

## 9. HTML Entity Encode/Decode

**Implementation Complexity**: ⭐⭐ Moderate

### Recommendation: **JavaScript Library**

**JavaScript Library**: [he](https://github.com/mathiasbynens/he) (HTML entities)
- Comprehensive HTML entity encoding/decoding
- Supports all options mentioned in DevUtils:
  - Named references vs numeric
  - Decimal vs hexadecimal
  - Encode everything option
  - Strict decoding
- Robust and well-tested
- Works perfectly in JavaScriptCore

**Alternative**: Write a Swift implementation using a dictionary of HTML entities, but `he` is more comprehensive and battle-tested.

---

## 10. Backslash Escape/Unescape

**Implementation Complexity**: ⭐ Simple

### Recommendation: **Native Swift**

Can be implemented with string replacements:

```swift
// Escape
func escape(_ string: String) -> String {
    return string
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
}

// Unescape
// Use a more sophisticated approach with character iteration
```

**JavaScript Alternative**: Simple string replacement operations work well in JavaScriptCore too.

**No external library needed.**

---

## 11. UUID/ULID Generate/Decode

**Implementation Complexity**: ⭐⭐ Moderate

### Recommendation: **Swift Package for ULID, Native for UUID**

**UUID (Native Swift)**:
```swift
let uuid = UUID() // Generate
let uuidString = UUID(uuidString: string) // Parse
```

UUID v1 decoding requires parsing the timestamp, clock ID, and node from the UUID bytes.

**ULID (Swift Package)**: [yaslab/ULID.swift](https://github.com/yaslab/ULID.swift)
- Supports ULID generation and parsing
- Extracts timestamps as Date objects
- Converts between ULID and UUID
- MIT licensed
- Swift Package Manager

**Alternative**: [std-swift/ULID](https://github.com/std-swift/ULID) - More protocol conformances

**Nano ID**: Implement in Swift (simple random string generation with custom alphabet)

---

## 12. HTML Preview

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (WebKit)**

Use WKWebView:

```swift
let webView = WKWebView()
webView.loadHTMLString(htmlString, baseURL: nil)

// Configure settings from gear icon
let config = WKWebViewConfiguration()
config.preferences.javaScriptEnabled = enableJS
// etc.
```

**No external library needed.**

---

## 13. Text Diff Checker

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [jsdiff](https://github.com/kpdecker/jsdiff)
- Implements Myers diff algorithm
- Supports character, word, and line diffs
- Well-maintained and popular
- Works perfectly in JavaScriptCore

**Swift Alternative**: Implement Myers diff algorithm or use `CollectionDifference` (iOS 13+) but it's more limited.

---

## 14. YAML to JSON

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **Swift Package**

**Swift Package**: [jpsim/Yams](https://github.com/jpsim/Yams)
- Most popular Swift YAML parser
- Version 6.0.1 (Swift 6 compatible)
- 1,027 commits, 53 releases
- Built on LibYAML for performance
- Supports Codable
- MIT licensed
- Swift Package Manager

Yams provides three APIs:
- Codable types (YAMLEncoder/YAMLDecoder)
- Swift Standard Library types
- Native YAML representation

**No JavaScript alternative needed - Yams is excellent.**

---

## 15. JSON to YAML

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **Swift Package**

**Use the same package**: [jpsim/Yams](https://github.com/jpsim/Yams)

```swift
import Yams

let json = """
{"name": "John", "age": 30}
"""
let object = try JSONSerialization.jsonObject(with: json.data(using: .utf8)!)
let yaml = try Yams.dump(object: object)
```

---

## 16. Number Base Converter

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (Foundation)**

Trivial using Swift's integer initializers and string formatting:

```swift
let number = 42

// Binary
let binary = String(number, radix: 2)

// Octal
let octal = String(number, radix: 8)

// Decimal
let decimal = String(number, radix: 10)

// Hexadecimal
let hex = String(number, radix: 16)

// Parsing
let parsed = Int(string, radix: radix)
```

**No external library needed.**

---

## 17. HTML Beautify/Minify

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [js-beautify](https://github.com/beautifier/js-beautify)
- Industry standard for HTML beautification
- Supports HTML, CSS, and JavaScript
- Extensive options for formatting
- Works in JavaScriptCore
- MIT licensed

```javascript
html_beautify(html, { indent_size: 2 })
```

**Minification**: Simple regex-based approach in Swift or use the same library.

---

## 18. CSS Beautify/Minify

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [js-beautify](https://github.com/beautifier/js-beautify)
- Same library as HTML
- `css_beautify()` function

```javascript
css_beautify(css, { indent_size: 2 })
```

---

## 19. JS Beautify/Minify

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [js-beautify](https://github.com/beautifier/js-beautify)
- `js_beautify()` function

**Minification**: [terser](https://github.com/terser/terser) or [uglify-js](https://github.com/mishoo/UglifyJS)
- These are the industry standards
- Work in JavaScriptCore (may need configuration)

---

## 20. ERB Beautify/Minify

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library or Skip**

ERB (Embedded Ruby) is niche. Options:
1. Use js-beautify's HTML mode (partial support)
2. Look for Ruby-specific beautifiers
3. Consider skipping this tool if not essential for your users

---

## 21. LESS Beautify/Minify

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [less.js](https://github.com/less/less.js)
- Official LESS compiler/parser
- Has formatting capabilities
- Works in browser/Node.js (compatible with JavaScriptCore)

---

## 22. SCSS Beautify/Minify

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [prettier](https://github.com/prettier/prettier) with SCSS plugin
- Industry standard formatter
- May be heavy for JavaScriptCore

**Alternative**: [sass-formatter](https://github.com/TheRealSyler/sass-formatter)

---

## 23. XML Beautify/Minify

**Implementation Complexity**: ⭐⭐ Moderate

### Recommendation: **Native Swift or JavaScript**

**Swift Approach**: Use `XMLDocument` (macOS) or `XMLParser`:
```swift
let doc = try XMLDocument(xmlString: xml, options: [.nodePrettyPrint])
let formatted = doc.xmlString(options: [.nodePrettyPrint])
```

**JavaScript Library**: [vkbeautify](https://github.com/vkiryukhin/vkBeautify) or xml-formatter

**Recommendation**: Native Swift is sufficient for this.

---

## 24. Lorem Ipsum Generator

**Implementation Complexity**: ⭐ Simple

### Recommendation: **JavaScript Library (easiest)**

**JavaScript Library**: [lorem-ipsum](https://www.npmjs.com/package/lorem-ipsum)
- Highly configurable
- Sentences per paragraph, words per sentence
- CLI and programmatic access

**Swift Alternative**: Create an array of Lorem Ipsum words and generate randomly. Simple but requires maintaining word list.

**Recommendation**: Use JavaScript library for convenience.

---

## 25. QR Code Reader/Generator

**Implementation Complexity**: ⭐⭐ Moderate

### Recommendation: **Swift Package**

**Swift Package**: [dagronf/QRCode](https://github.com/dagronf/QRCode)
- Comprehensive library for generation AND detection
- 506 commits, 188 releases
- Supports macOS, iOS, tvOS, watchOS, visionOS
- SwiftUI and Objective-C support
- 4 years in development

**Alternative**: [EFQRCode](https://github.com/EFPrefix/EFQRCode)
- Version 7.0.3
- Stylized QR codes with watermarks
- Recognition capabilities

**Native iOS Framework**: Core Image's `CIQRCodeGenerator` for generation, AVFoundation for scanning

**Recommendation**: Use Swift package for comprehensive features, or native iOS frameworks for simplicity.

---

## 26. String Inspector

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (Foundation)**

Simple Swift implementation:

```swift
let characterCount = string.count
let byteSize = string.utf8.count
let lineCount = string.components(separatedBy: .newlines).count
let wordCount = string.components(separatedBy: .whitespacesAndNewlines)
                      .filter { !$0.isEmpty }.count
```

**No external library needed.**

---

## 27. JSON to CSV

**Implementation Complexity**: ⭐⭐⭐ Moderate to Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [json-2-csv](https://www.npmjs.com/package/json-2-csv)
- Handles all the options mentioned:
  - Quote characters
  - Escaped quotes
  - Delimiter
  - Headers
  - Flatten objects
  - Include BOM
- Works in JavaScriptCore

**Alternative**: [Papa Parse](https://www.papaparse.com/)
- More popular
- Bidirectional JSON ↔ CSV

**Swift Alternative**: Write a custom implementation but handling nested objects ("flatten objects") is complex.

---

## 28. CSV to JSON

**Implementation Complexity**: ⭐⭐⭐ Moderate to Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [Papa Parse](https://www.papaparse.com/)
- Fast (90,000 rows/second)
- Auto-delimiter detection
- Header detection
- Works in browser/Node.js (JavaScriptCore compatible)

**Alternative**: [csvtojson](https://www.npmjs.com/package/csvtojson)
- Streaming support
- RFC4180 compliant

**Swift Alternative**: Can parse simple CSV with `String.components(separatedBy:)` but proper CSV parsing (quoted fields, escaped characters) is complex.

---

## 29. Hash Generator

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift (CryptoKit)**

Use CryptoKit (iOS 13+) or CommonCrypto:

```swift
import CryptoKit

// MD5 (need to use CommonCrypto, not in CryptoKit)
let md5 = Insecure.MD5.hash(data: data)

// SHA-256
let sha256 = SHA256.hash(data: data)

// SHA-512
let sha512 = SHA512.hash(data: data)
```

For MD5 and SHA-1, use CommonCrypto since CryptoKit marks them as insecure.

**No external library needed.**

---

## 30. HTML to JSX

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [node-html-to-jsx](https://www.npmjs.com/package/node-html-to-jsx)
- Converts class → className
- Converts event attributes to camelCase
- Handles self-closing tags
- Converts inline styles to objects
- MIT licensed

**Alternative**: [DiogoAngelim/html-to-jsx](https://github.com/DiogoAngelim/html-to-jsx)

**Swift Alternative**: Would require HTML parsing and AST transformation - very complex.

---

## 31. Markdown Preview

**Implementation Complexity**: ⭐⭐ Moderate

### Recommendation: **Swift Package or JavaScript**

**Swift Package**: [apple/swift-markdown](https://github.com/apple/swift-markdown)
- Official Apple package
- CommonMark compliant
- Can generate HTML

**JavaScript Library**: [marked](https://github.com/markedjs/marked) (32.1k stars)
- Fastest JavaScript Markdown parser
- GitHub Flavored Markdown support
- Works in JavaScriptCore

**Alternative JavaScript**: [markdown-it](https://github.com/markdown-it/markdown-it) (17.4k stars)
- CommonMark compliant
- Plugin system

**Recommendation**: Swift package for native performance, JavaScript for GFM support.

---

## 32. SQL Formatter

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [sql-formatter](https://github.com/sql-formatter-org/sql-formatter)
- Latest version: 15.6.9
- Supports multiple SQL dialects:
  - MySQL, PostgreSQL, SQL Server
  - BigQuery, Oracle, DB2
  - Snowflake, Redshift, Spark
  - And many more
- Extensive formatting options
- Keyword case (upper/lower)
- Indentation
- Available on npm and CDN

**Swift Alternative**: Would be very complex to implement all dialects.

---

## 33. String Case Converter

**Implementation Complexity**: ⭐ Simple to Moderate

### Recommendation: **JavaScript Library (for completeness)**

**JavaScript Library**: [change-case](https://github.com/blakeembrey/change-case)
- 4,435 dependents
- Supports all case formats:
  - camelCase, PascalCase, snake_case
  - kebab-case, SCREAMING_SNAKE_CASE
  - Title Case, Sentence case
  - And more
- Pure ESM package with TypeScript definitions

**Swift Alternative**: Can implement manually for common cases:

```swift
// camelCase
func toCamelCase(_ string: String) -> String {
    // Implementation
}

// snake_case
func toSnakeCase(_ string: String) -> String {
    // Implementation
}
```

The "always uppercase acronyms" feature would require a custom implementation in Swift.

**Recommendation**: JavaScript library for completeness, Swift for core features.

---

## 34. Cron Job Parser

**Implementation Complexity**: ⭐⭐⭐ Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [cron-parser](https://github.com/harrisiirak/cron-parser)
- Most established option
- Timezone support
- DST handling
- Iterator support for next/previous execution times

**Alternative**: [cron-schedule](https://github.com/P4sca1/cron-schedule)
- Zero dependencies
- Works in Node.js, Deno, and browser

**Alternative**: [cronstrue](https://github.com/bradymholt/cRonstrue)
- Converts cron expressions to human-readable descriptions
- "Every 5 minutes" etc.

**Recommendation**: Use cron-parser for parsing and cronstrue for human-readable descriptions.

---

## 35. Color Converter

**Implementation Complexity**: ⭐⭐ Moderate

### Recommendation: **Native Swift (UIKit/AppKit) or JavaScript**

**Swift Approach**: UIColor/NSColor have conversion methods:
```swift
// Get RGB components
var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

// Get HSL components (need conversion formulas)
```

Conversion formulas are well-documented.

**JavaScript Library**: [color-convert](https://www.npmjs.com/package/color-convert)
- Converts all ways between rgb, hsl, hsv, hwb, cmyk, hex
- Automatic routing for complex conversions

**Alternative JavaScript**: [chroma.js](https://gka.github.io/chroma.js/)
- More comprehensive color manipulation

**Recommendation**: Native Swift is sufficient, JavaScript library if you want more color spaces.

---

## 36-39. PHP to JSON / JSON to PHP / PHP Serializer / Unserializer

**Implementation Complexity**: ⭐⭐⭐⭐ Very Complex

### Recommendation: **Requires PHP Runtime**

These tools require executing PHP code to properly serialize/unserialize PHP data structures. Options:

1. **Ship with PHP binary**: Embed a PHP runtime in your app
2. **Use system PHP**: Execute PHP via shell commands (macOS has PHP)
3. **JavaScript implementation**: Limited support for basic cases
4. **Skip these tools**: Unless your target users are PHP developers

**Recommendation**: Skip these tools unless absolutely necessary. If needed, use system PHP.

---

## 40. Random String Generator

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift**

Simple Swift implementation:

```swift
func randomString(length: Int, charset: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {
    return String((0..<length).map { _ in charset.randomElement()! })
}
```

**No external library needed.**

---

## 41. SVG to CSS

**Implementation Complexity**: ⭐⭐ Moderate

### Recommendation: **Swift Implementation**

Convert SVG to data URI:

```swift
func svgToCSS(_ svg: String) -> String {
    // Encode SVG
    let encoded = svg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

    // Create data URI
    return "background-image: url('data:image/svg+xml,\(encoded)');"
}
```

Can also use base64 encoding.

**No external library needed.**

---

## 42. cURL to Code

**Implementation Complexity**: ⭐⭐⭐⭐ Very Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [curlconverter](https://github.com/curlconverter/curlconverter)
- Converts curl to 29+ languages:
  - Python, JavaScript, Go, Rust, Swift, Java
  - PHP, Ruby, C#, Kotlin, and many more
- Available as npm package and CLI
- Static website (conversion in browser)
- Works in JavaScriptCore

**Alternative**: [curl-parser-js](https://www.npmjs.com/package/curl-parser-js)
- Simpler parser (to JSON)
- Plugin system for code generation

**Recommendation**: Use curlconverter - it's comprehensive and battle-tested.

---

## 43. JSON to Code

**Implementation Complexity**: ⭐⭐⭐⭐ Very Complex

### Recommendation: **JavaScript Library**

**JavaScript Library**: [quicktype](https://github.com/glideapps/quicktype)
- Generates types and serializers from JSON
- Supports 20+ languages:
  - Swift, TypeScript, Python, Go, Rust
  - C#, Java, Kotlin, C++, and more
- Available as npm package, CLI, and website
- Can be used in JavaScriptCore

**Alternative**: [json-schema-to-typescript](https://www.npmjs.com/package/json-schema-to-typescript)
- Specific to TypeScript

**Swift Alternative**: [SwiftyJSONAccelerator](https://github.com/insanoid/SwiftyJSONAccelerator)
- macOS app for Swift code generation
- Could extract the core library

**Recommendation**: Use quicktype for multi-language support.

---

## 44. Certificate Decoder (X.509)

**Implementation Complexity**: ⭐⭐⭐⭐ Very Complex

### Recommendation: **Swift Package (Native)**

**Swift Package**: [apple/swift-certificates](https://github.com/apple/swift-certificates)
- Official Apple implementation
- Announced November 2025 (very recent!)
- Memory-safe ASN.1 parsing
- X.509 certificate parsing and serialization
- Available on Swift Package Index

**Companion Package**: [apple/swift-asn1](https://github.com/apple/swift-asn1)
- ASN.1 DER parsing (required for X.509)

**Alternative**: Use OpenSSL via shell commands
```swift
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/openssl")
task.arguments = ["x509", "-in", certPath, "-text"]
```

**Recommendation**: Use Apple's swift-certificates package - it's the modern, safe solution.

---

## 45. Hex to ASCII

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift**

Simple implementation:

```swift
func hexToASCII(_ hex: String) -> String? {
    let hex = hex.replacingOccurrences(of: " ", with: "")
    var result = ""
    var index = hex.startIndex

    while index < hex.endIndex {
        let nextIndex = hex.index(index, offsetBy: 2)
        let byteString = String(hex[index..<nextIndex])

        guard let byte = UInt8(byteString, radix: 16) else { return nil }
        result.append(Character(UnicodeScalar(byte)))

        index = nextIndex
    }

    return result
}
```

**No external library needed.**

---

## 46. ASCII to Hex

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift**

Simple implementation:

```swift
func asciiToHex(_ ascii: String, separator: String = " ", prefix: Bool = false) -> String {
    let hex = ascii.utf8.map {
        let h = String($0, radix: 16)
        return prefix ? "0x\(h)" : h
    }
    return hex.joined(separator: separator)
}
```

**No external library needed.**

---

## 47. Line Sort/Dedupe

**Implementation Complexity**: ⭐ Very Simple

### Recommendation: **Native Swift**

Trivial implementation:

```swift
func sortLines(_ text: String, ascending: Bool = true, caseSensitive: Bool = true, removeDuplicates: Bool = false) -> String {
    var lines = text.components(separatedBy: .newlines)

    // Remove duplicates
    if removeDuplicates {
        if caseSensitive {
            lines = Array(Set(lines))
        } else {
            var seen = Set<String>()
            lines = lines.filter { line in
                let lower = line.lowercased()
                if seen.contains(lower) {
                    return false
                } else {
                    seen.insert(lower)
                    return true
                }
            }
        }
    }

    // Sort
    lines.sort {
        let result = caseSensitive ? $0 < $1 : $0.lowercased() < $1.lowercased()
        return ascending ? result : !result
    }

    return lines.joined(separator: "\n")
}
```

**No external library needed.**

---

## Summary by Implementation Method

### ✅ Native Swift (Foundation/UIKit/AppKit) - 19 tools

These are very simple to implement using built-in APIs:

1. Unix Time Converter
2. Base64 String Encode/Decode
3. Base64 Image Encode/Decode
4. RegExp Tester
5. URL Encode/Decode
6. URL Parser
7. Backslash Escape/Unescape (simple version)
8. HTML Preview (WKWebView)
9. Number Base Converter
10. String Inspector
11. Hash Generator (CryptoKit)
12. Markdown Preview (with swift-markdown)
13. Color Converter
14. Random String Generator
15. SVG to CSS
16. Hex to ASCII
17. ASCII to Hex
18. Line Sort/Dedupe
19. XML Beautify (with XMLDocument)

### 📦 Swift Packages - 7 tools

Well-maintained Swift packages available:

1. **JWT Debugger**: Auth0/JWTDecode.swift
2. **ULID Generate/Decode**: yaslab/ULID.swift
3. **YAML to JSON**: jpsim/Yams
4. **JSON to YAML**: jpsim/Yams
5. **QR Code Reader/Generator**: dagronf/QRCode
6. **Markdown Preview**: apple/swift-markdown
7. **Certificate Decoder**: apple/swift-certificates

### 🟨 JavaScript Libraries (JavaScriptCore) - 21 tools

Best implemented with JavaScript libraries:

1. **JSON Format/Validate** (advanced features): json-repair, json5, jsonpath-plus
2. **HTML Entity Encode/Decode**: he
3. **Text Diff Checker**: jsdiff
4. **HTML Beautify/Minify**: js-beautify
5. **CSS Beautify/Minify**: js-beautify
6. **JS Beautify/Minify**: js-beautify + terser/uglify-js
7. **LESS Beautify/Minify**: less.js
8. **SCSS Beautify/Minify**: sass-formatter
9. **Lorem Ipsum Generator**: lorem-ipsum
10. **JSON to CSV**: json-2-csv or Papa Parse
11. **CSV to JSON**: Papa Parse
12. **HTML to JSX**: node-html-to-jsx
13. **Markdown Preview**: marked or markdown-it
14. **SQL Formatter**: sql-formatter
15. **String Case Converter**: change-case
16. **Cron Job Parser**: cron-parser + cronstrue
17. **Color Converter**: color-convert (alternative to native)
18. **cURL to Code**: curlconverter
19. **JSON to Code**: quicktype
20. **ERB Beautify/Minify**: (consider skipping)
21. **PHP Tools**: (consider skipping or use system PHP)

### ⚠️ Consider Skipping - 4 tools

These are complex or require external runtimes:

1. **ERB Beautify/Minify**: Niche Ruby tool
2. **PHP to JSON**
3. **JSON to PHP**
4. **PHP Serializer/Unserializer**

---

## Implementation Strategy

### Phase 1: Quick Wins (Native Swift) - 19 tools
Implement all tools that use native APIs first. These are fast and require no dependencies.

### Phase 2: Swift Packages - 7 tools
Integrate well-maintained Swift packages via Swift Package Manager.

### Phase 3: JavaScript Integration - 21 tools
Set up JavaScriptCore infrastructure and integrate JavaScript libraries:
- Create a JSContext manager
- Load JavaScript libraries
- Create Swift ↔ JavaScript bridge functions
- Handle errors and type conversions

### Phase 4: Evaluate Optional Tools - 4 tools
Decide whether to implement PHP and ERB tools based on user demand.

---

## JavaScript Library Integration Notes

### Loading Libraries in JavaScriptCore

```swift
import JavaScriptCore

class JSManager {
    let context = JSContext()!

    init() {
        // Load libraries from bundle
        if let path = Bundle.main.path(forResource: "marked.min", ofType: "js"),
           let source = try? String(contentsOfFile: path) {
            context.evaluateScript(source)
        }
    }

    func callJS(_ function: String, with args: [Any]) -> JSValue? {
        guard let fn = context.objectForKeyedSubscript(function) else { return nil }
        return fn.call(withArguments: args)
    }
}

// Usage
let js = JSManager()
let html = js.callJS("marked", with: [markdown])?.toString()
```

### Polyfills for JavaScriptCore

Some libraries may need polyfills:
- `atob()`/`btoa()` for Base64
- `crypto` for cryptographic functions
- `Buffer` for Node.js libraries

---

## Recommended Libraries Summary

| Category | Library | Language | Package Manager |
|----------|---------|----------|-----------------|
| JWT | JWTDecode.swift | Swift | SPM |
| YAML | Yams | Swift | SPM |
| QR Code | QRCode | Swift | SPM |
| ULID | ULID.swift | Swift | SPM |
| Certificate | swift-certificates | Swift | SPM |
| JSON Repair | json-repair | JS | npm |
| Diff | jsdiff | JS | npm |
| Beautify | js-beautify | JS | npm |
| Markdown | marked | JS | npm |
| SQL Format | sql-formatter | JS | npm |
| CSV/JSON | Papa Parse | JS | npm |
| HTML→JSX | node-html-to-jsx | JS | npm |
| Case Convert | change-case | JS | npm |
| Cron | cron-parser | JS | npm |
| Color | color-convert | JS | npm |
| Lorem | lorem-ipsum | JS | npm |
| Curl→Code | curlconverter | JS | npm |
| JSON→Code | quicktype | JS | npm |

---

## Resources

### Swift Packages
- [Swift Package Index](https://swiftpackageindex.com/)
- [Swift Package Registry](https://swiftpackageregistry.com/)

### JavaScript Libraries
- [npm](https://www.npmjs.com/)
- [cdnjs](https://cdnjs.com/) - For loading libraries

### Documentation
- [JavaScriptCore Documentation](https://developer.apple.com/documentation/javascriptcore)
- [Foundation Documentation](https://developer.apple.com/documentation/foundation)
- [CryptoKit Documentation](https://developer.apple.com/documentation/cryptokit)

---

## Next Steps

1. **Prototype Phase 1**: Implement 5 native Swift tools to establish patterns
2. **Set up JS Infrastructure**: Create JavaScriptCore manager and test with one library
3. **Prioritize by User Value**: Survey potential users for most-wanted tools
4. **Iterative Development**: Release incrementally, gather feedback
5. **Performance Testing**: Benchmark JavaScript vs native implementations
6. **Error Handling**: Robust error handling for both Swift and JS code
7. **Testing**: Unit tests for each tool, especially for edge cases

---

*Document prepared: January 2026*
*Based on current Swift and JavaScript ecosystem*
