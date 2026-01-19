# DevUtils.app Tools Documentation

This document lists all tools available in DevUtils.app with their configurations and options.

---

## 1. Unix Time Converter

**What it does:** Converts between Unix timestamps (seconds since epoch) and human-readable date/time formats.

**User Configuration Options:**

### Input Section:
- **Input type dropdown:** Unix time (seconds since epoch)
- **Now/Clipboard/Clear buttons:** Quick input options
- **Gear icon (⚙️) settings:**
  - ✅ **Auto detect when input is a number within range:**
    - Range 1: 946684799 to 32503593600
    - Range 2: 1999-12-31T23:59:59Z to 2999-12-31T00:00:00Z
  - **Add timezone:** Dropdown to select additional timezones to display
  - **Reset to defaults button**

### Output Displays:
- Local time with timezone
- UTC (ISO 8601) format
- Relative time (e.g., "0sec ago")
- Unix time
- Day of year
- Week of year
- Is leap year
- Other formats (local)

---

## 2. JSON Format/Validate

**What it does:** Formats, validates, and beautifies JSON data.

**User Configuration Options:**

### Input Section:
- **Input format dropdown:** JSON (and other formats)
- **Spacing dropdown:** 2 spaces, 4 spaces, etc.
- **Gear icon (⚙️) settings:**
  - ✅ **Auto detect when input is a valid JSON**
  - ☐ **Allow trailing commas and comments in JSON**
  - ✅ **Auto repair invalid JSON if possible**
    - Fix missing quotes, replace Python constants, strip trailing commas, etc.
  - ✅ **Continuous Mode: format the input continuously as you type**
  - ☐ **Sort keys in output**
  - ☐ **Preserves encoded strings (like "\u00e2") and big numbers**
    - Only works when "Sort keys" and "Auto repair" options are off
  - **Reset to Defaults button**

### Output Section:
- JSON Path support (e.g., $.store.book[*].author)

---

## 3. Base64 String Encode/Decode

**What it does:** Encodes text to Base64 or decodes Base64 strings back to text.

**User Configuration Options:**

### Mode Toggle:
- **Encode/Decode radio buttons**

### Gear icon (⚙️) settings:
- ✅ **Auto detect when input is a Base64 and decodeable to UTF8**
- ✅ **Auto remove "data:...;base64," from the input when decoding**
- ✅ **Auto remove null byte ("\0") at the end of decoded string**
- **Restore to Defaults button**

### Output Section:
- Copy button
- "Use as input" button (↑ arrow)

---

## 4. Base64 Image Encode/Decode

**What it does:** Converts images to Base64 strings or decodes Base64 strings to images.

**User Configuration Options:**

### String Section:
- Clipboard/Sample/Clear buttons
- Three tabs for output format:
  - **Raw String**
  - **Data URL**
  - **CSS Attribute**
- Copy button

### Image Section:
- **Clipboard button:** Paste image from clipboard
- **Load File... button:** Select image file
- **Clear button:** Clear current image
- **Save button:** Save decoded image
- **Copy button:** Copy image to clipboard
- Image preview area

---

## 5. JWT Debugger

**What it does:** Decodes and debugs JSON Web Tokens (JWT), showing header, payload, and signature verification.

**User Configuration Options:**

### Input Section:
- Clipboard/Sample/Clear buttons
- **Algorithm dropdown:** HS256 and other JWT algorithms
- **Gear icon (⚙️) settings:**
  - ✅ **Auto detect when input is a well formed JWT token**
  - **Reset to Defaults button**

### Output Sections:
- **Header:** Displays decoded JWT header with Copy button
- **Payload:** Displays decoded JWT payload with Copy button
- **Signature:** Shows signature verification formula and status
- **Verification Status:** Shows "Signature Verified" or "No Input"
- **Issued At timestamp display**

---

## 6. RegExp Tester

**What it does:** Tests regular expressions against text with real-time matching and highlighting.

**User Configuration Options:**

### RegExp Section:
- Clipboard/Sample/Clear buttons
- **Cheat Sheet button:** Opens regex quick reference

### Gear icon (⚙️) settings:
- **Regex Engine dropdown:** ICU (and possibly other engines)
- **Flags:**
  - ☐ **Case insensitive**
  - ☐ **Allow use of white space and #comments within patterns**
  - ☐ **"." matches line separators**
  - ☐ **"^" and "$" matches at the start and end of each line within the input text**
  - ☐ **"\b" matches words based on boundaries defined in Unicode UAX 29, Text Boundaries**
- **Restore Defaults button**

### Text Section:
- Clipboard button
- Match counter display (e.g., "0 matches")
- Navigation arrows (< >) to jump between matches

### Output Section:
- Output format dropdown (e.g., $0\n)
- Copy button
- Search matches field
- Help icon (?)

---

## 7. URL Encode/Decode

**What it does:** Encodes text for safe use in URLs or decodes URL-encoded strings.

**User Configuration Options:**

### Mode Toggle:
- **Encode/Decode radio buttons**

### Gear icon (⚙️) settings:
- ✅ **Auto detect when input contains characters that can be decoded**
- **Encode options:**
  - ● **RFC3986 Standard** (selected)
  - ○ **Form Data**
    - ☑ **Use plus sign (+) for spaces**
- **Decode options:**
  - ✅ **Decode "+" characters to spaces**
- **Restore to Defaults button**

### Output Section:
- Copy button
- "Use as input" button

---

## 8. URL Parser

**What it does:** Parses URLs into their component parts (protocol, domain, path, query parameters, etc.).

**User Configuration Options:**

### Input Section:
- Clipboard/Sample/Clear buttons
- **Gear icon (⚙️) settings:**
  - ✅ **Auto detect when input is a URL and contains ≥ 2 query string variables.**
  - **Reset to Defaults button**

### Output Sections:
- **Field/Value table:** Shows Protocol, Host, Path, File name, Query components
- **Query string:** Parsed as JSON with Copy button
- **Tips section:**
  - Right Click → Save to File...
  - Right Click → Show Line Numbers
  - Right Click → Line Wrapping

---

## 9. HTML Entity Encode/Decode

**What it does:** Converts HTML special characters to entities (e.g., `<` to `&lt;`) or decodes them back.

**User Configuration Options:**

### Mode Toggle:
- **Encode/Decode radio buttons**

### Gear icon (⚙️) settings:

**Auto detect:**
- ✅ **Auto detect if input contains decodable HTML entities**

**Encode options:**
- ☐ **Allow unsafe symbols**
  - Specifies if unsafe ASCII characters should be skipped or not.
- ☐ **Use decimal format**
  - Specifies if decimal character escapes should be used instead of hexadecimal character escapes whenever numeric character escape is used.
- ☐ **Encode everything (overrides "Allow unsafe symbols")**
  - Specifies if all characters should be escaped, even if some characters are safe.
- ✅ **Use named references (overrides "Use decimal format")**
  - Specifies if named character references should be used whenever possible.

**Decode options:**
- ☐ **Strict decoding**
  - Specifies if HTML5 parse errors should be thrown or simply passed over.

- **Reset to Defaults button**

### Output Section:
- Copy button
- "Use as input" button

---

## 10. Backslash Escape/Unescape

**What it does:** Adds or removes backslash escape sequences (e.g., for strings in code).

**User Configuration Options:**

### Mode Toggle:
- **Escape/Unescape radio buttons**

### Output Section:
- Copy button
- "Use as input" button

---

## 11. UUID/ULID Generate/Decode

**What it does:** Generates UUIDs/ULIDs or decodes existing ones to show their components.

**User Configuration Options:**

### Input Section for Decoding:
- Clipboard/Sample/Clear buttons
- **Gear icon (⚙️) settings:**
  - ✅ **Auto detect when input is a valid UUID**
  - **Reset to Defaults button**

### Decode Output:
- Standard String Format
- Raw Contents (with copy button)
- Version (with copy button)
- Variant (with copy button)
- Contents - Time (with copy button)
- Contents - Clock ID (with copy button)
- Contents - Node (with copy button)

### Generate Section:
- **ID type dropdown:** UUID v1, Nano ID, etc.
- **Quantity:** x 100 (adjustable)
- **Generate button**
- **Copy button**
- **Clear button**
- ☐ **lowercased** checkbox
- Generated IDs list display
- Right click → Save to file...

---

## 12. HTML Preview

**What it does:** Renders HTML code in a live preview pane.

**User Configuration Options:**

### Input Section:
- Clipboard/Sample/Clear buttons
- **Format dropdown:** Select format
- **Gear icon (⚙️) settings:**
  - ✅ **Enable JavaScript**
  - ☐ **Enable link navigation**
  - ✅ **Enable outgoing network from WebView**
  - **Reset to Defaults button**

### Preview Section:
- **Open in Browser button:** Opens preview in external browser
- **Reload button:** Refresh the preview
- Live preview pane showing rendered HTML

---

## 13. Text Diff Checker

**What it does:** Compares two text inputs and highlights differences.

**User Configuration Options:**

### Input Sections:
- Two input panes with labels (aaaa and bbbb)
- Clipboard/Sample/Clear buttons for each pane
- **"Swap Inputs" button:** Switch the two text inputs

### Diff Options:
- **Diff mode selector (radio buttons):**
  - ● **Characters**
  - ○ **Words**
  - ○ **Lines**

### Output Section:
- **Output format dropdown:** Formatted Text (and other formats)
- Copy button
- **Navigation arrows (< >):** Move between differences with counter display (e.g., "6")

---

## 14. YAML to JSON

**What it does:** Converts YAML format to JSON format.

**User Configuration Options:**
- Clipboard/Sample/Clear buttons
- Output spacing control (e.g., "2 spaces")
- Copy button

---

## 15. JSON to YAML

**What it does:** Converts JSON format to YAML format.

**User Configuration Options:**
- Clipboard/Sample/Clear buttons
- Copy button

---

## 16. Number Base Converter

**What it does:** Converts numbers between different bases (binary, decimal, hexadecimal, octal, etc.).

**User Configuration Options:**
- Input field for number
- Multiple output bases displayed simultaneously:
  - Binary
  - Octal
  - Decimal
  - Hexadecimal
  - And more
- Copy buttons for each output

---

## 17. HTML Beautify/Minify

**What it does:** Formats HTML code for readability or minifies it to reduce size.

**User Configuration Options:**
- **Beautify/Minify toggle:** Switch between formatting and minifying
- Clipboard/Sample/Clear buttons
- Copy button

---

## 18. CSS Beautify/Minify

**What it does:** Formats CSS code for readability or minifies it to reduce size.

**User Configuration Options:**
- **Beautify/Minify toggle:** Switch between formatting and minifying
- Clipboard/Sample/Clear buttons
- Copy button

---

## 19. JS Beautify/Minify

**What it does:** Formats JavaScript code for readability or minifies it to reduce size.

**User Configuration Options:**
- **Beautify/Minify toggle:** Switch between formatting and minifying
- Clipboard/Sample/Clear buttons
- Copy button

---

## 20. ERB Beautify/Minify

**What it does:** Formats ERB (Embedded Ruby) code for readability or minifies it to reduce size.

**User Configuration Options:**
- **Beautify/Minify toggle:** Switch between formatting and minifying
- Clipboard/Sample/Clear buttons
- Copy button

---

## 21. LESS Beautify/Minify

**What it does:** Formats LESS CSS preprocessor code for readability or minifies it to reduce size.

**User Configuration Options:**
- **Beautify/Minify toggle:** Switch between formatting and minifying
- Clipboard/Sample/Clear buttons
- Copy button

---

## 22. SCSS Beautify/Minify

**What it does:** Formats SCSS/Sass code for readability or minifies it to reduce size.

**User Configuration Options:**
- **Beautify/Minify toggle:** Switch between formatting and minifying
- Clipboard/Sample/Clear buttons
- Copy button

---

## 23. XML Beautify/Minify

**What it does:** Formats XML code for readability or minifies it to reduce size.

**User Configuration Options:**
- **Beautify/Minify toggle:** Switch between formatting and minifying
- Clipboard/Sample/Clear buttons
- Copy button

---

## 24. Lorem Ipsum Generator

**What it does:** Generates Lorem Ipsum placeholder text.

**User Configuration Options:**
- Number of paragraphs/words selector
- Clipboard/Clear buttons
- Copy button

---

## 25. QR Code Reader/Generator

**What it does:** Generates QR codes from text or reads/decodes QR code images.

**User Configuration Options:**
- Text input for generation
- Image upload for reading
- QR code size options
- Error correction level
- Copy/Save buttons

---

## 26. String Inspector

**What it does:** Analyzes strings to show character count, byte size, encoding, and other properties.

**User Configuration Options:**
- Text input area
- Statistics display:
  - Character count
  - Byte size
  - Line count
  - Word count
- Encoding information
- Copy button

---

## 27. JSON to CSV

**What it does:** Converts JSON data to CSV format.

**User Configuration Options:**

### Gear icon (⚙️) settings:
- **Quote:** `"` (quote around cell values and column names)
- **Escaped quote:** `""` (the value to replace escaped quotes in strings)
- **Delimiter:** `,` (delimiter of columns, use \t for tab)
- ✅ **Include headers**
- ✅ **Flatten objects**
- ☐ **Converts string data into normalized Excel style data**
- ☐ **Include empty rows**
- ☐ **Include BOM character**
- **Restore Defaults button**

### Input/Output:
- Clipboard/Sample/Clear buttons
- Copy button

---

## 28. CSV to JSON

**What it does:** Converts CSV data to JSON format.

**User Configuration Options:**

### Gear icon (⚙️) settings:
- **Delimiter:** `,` (delimiter of columns, use \t for tab)
- ☐ **Swap column/row**
- ✅ **Use first row as header**
- **Restore Defaults button**

### Input/Output:
- Clipboard/Sample/Clear buttons
- Output spacing control (e.g., "2 spaces")
- Copy button

---

## 29. Hash Generator

**What it does:** Generates various hash values (MD5, SHA-1, SHA-256, etc.) from input text.

**User Configuration Options:**
- Text input area
- Multiple hash algorithms displayed:
  - MD5
  - SHA-1
  - SHA-256
  - SHA-512
  - And more
- Copy buttons for each hash

---

## 30. HTML to JSX

**What it does:** Converts HTML code to JSX format for React applications.

**User Configuration Options:**
- Clipboard/Sample/Clear buttons
- Copy button
- Automatic conversion of HTML attributes to JSX format (e.g., class → className)

---

## 31. Markdown Preview

**What it does:** Renders Markdown text with live preview.

**User Configuration Options:**
- Markdown input area
- Live preview pane
- Clipboard/Sample/Clear buttons
- Copy button (for rendered HTML)

---

## 32. SQL Formatter

**What it does:** Formats SQL queries for better readability.

**User Configuration Options:**
- Clipboard/Sample/Clear buttons
- SQL dialect selection
- Indentation options
- Keyword case options (UPPERCASE/lowercase)
- Copy button

---

## 33. String Case Converter

**What it does:** Converts text between different cases (lowercase, UPPERCASE, camelCase, snake_case, etc.).

**User Configuration Options:**

### Input Section:
- Clipboard/Sample/Clear buttons

### Output Section:
- **Output format dropdown:** camelCase (with many options)
  - lowercase
  - UPPERCASE
  - Title Case
  - camelCase
  - PascalCase
  - snake_case
  - SCREAMING_SNAKE_CASE
  - kebab-case
  - And more
- Copy button

### Gear icon (⚙️) settings:
- ☐ **Always uppercase the following unique names and acronyms:**
  - Tags: **ID**, **API**, **DB**, **URL**, **HTTP** (shown as pill buttons)
- **Reset to Defaults button**

---

## 34. Cron Job Parser

**What it does:** Parses cron expressions and shows when they will run.

**User Configuration Options:**
- Cron expression input
- Next execution times display
- Timezone selection
- Human-readable description

---

## 35. Color Converter

**What it does:** Converts colors between different formats (HEX, RGB, HSL, etc.).

**User Configuration Options:**
- Color input (HEX, RGB, HSL, etc.)
- Color picker
- Multiple format outputs:
  - HEX
  - RGB
  - HSL
  - HSV
  - And more
- Copy buttons for each format

---

## 36. PHP to JSON

**What it does:** Converts PHP arrays/objects to JSON format.

**User Configuration Options:**

### Gear icon (⚙️) settings:
- **Select PHP runtime dropdown:**
  - Shows available PHP versions or "No Usable PHP Runtime"
  - **Manage Scripts Runtime...** option
- Copy button

---

## 37. JSON to PHP

**What it does:** Converts JSON data to PHP array format.

**User Configuration Options:**

### Gear icon (⚙️) settings:
- **Select PHP runtime dropdown:**
  - Shows available PHP versions or "No Usable PHP Runtime"
  - **Manage Scripts Runtime...** option
- Copy button

---

## 38. PHP Serializer

**What it does:** Serializes PHP data structures.

**User Configuration Options:**
- Requires PHP runtime
- Copy button

---

## 39. PHP Unserializer

**What it does:** Unserializes PHP serialized data back to readable format.

**User Configuration Options:**
- Requires PHP runtime
- Copy button

---

## 40. Random String Generator

**What it does:** Generates random strings with customizable parameters.

**User Configuration Options:**
- Length selector
- Character set options:
  - Uppercase letters
  - Lowercase letters
  - Numbers
  - Special characters
- Quantity selector
- Generate button
- Copy button

---

## 41. SVG to CSS

**What it does:** Converts SVG images to CSS background-image data URIs.

**User Configuration Options:**
- SVG input/upload
- Encoding options
- Copy button for CSS output

---

## 42. cURL to Code

**What it does:** Converts cURL commands to code in various programming languages.

**User Configuration Options:**
- cURL command input
- Language selection dropdown:
  - Python
  - JavaScript
  - PHP
  - Ruby
  - Go
  - And more
- Copy button

---

## 43. JSON to Code

**What it does:** Converts JSON to code models/classes in various programming languages.

**User Configuration Options:**
- JSON input
- Language selection
- Class/type name input
- Naming convention options
- Copy button

---

## 44. Certificate Decoder (X.509)

**What it does:** Decodes X.509 SSL/TLS certificates and displays their information.

**User Configuration Options:**

### Gear icon (⚙️) settings:
- **Select an executable file for Open SSL dropdown:**
  - Shows OpenSSL version (e.g., "OpenSSL 3.6.0 1 Oct 2025 (Library: OpenSSL 3.6.0 1 Oct 2025)")
  - Allows selecting custom OpenSSL executable

### Input Section:
- Clipboard/Sample/Clear buttons
- Certificate input (PEM format)

### Output:
- Decoded certificate information:
  - Subject
  - Issuer
  - Validity dates
  - Public key
  - Signature
  - Extensions
- Copy button

---

## 45. Hex to ASCII

**What it does:** Converts hexadecimal values to ASCII text.

**User Configuration Options:**
- Hex input area
- Spacing options
- Copy button

---

## 46. ASCII to Hex

**What it does:** Converts ASCII text to hexadecimal representation.

**User Configuration Options:**
- ASCII input area
- Spacing options
- Output format (with/without prefix, separators)
- Copy button

---

## 47. Line Sort/Dedupe

**What it does:** Sorts lines of text alphabetically and/or removes duplicate lines.

**User Configuration Options:**
- Text input area
- Sort order:
  - Ascending (A→Z)
  - Descending (Z→A)
- Case sensitivity toggle
- Remove duplicates toggle
- Copy button

---

## Notes

- **⚙️ Gear Icon:** Many tools have a gear/settings icon that reveals additional configuration options. Click this icon to access advanced settings specific to each tool.
- **Common Options:** Most encode/decode and format tools include:
  - Clipboard/Sample/Clear buttons for quick input management
  - Copy buttons for output
  - "Use as Input" functionality to chain operations
- **Auto-detect Features:** Many tools include intelligent auto-detection to automatically determine the input format and switch modes accordingly
- **Reset/Restore Defaults:** Configuration dialogs typically include a button to restore all settings to their default values
