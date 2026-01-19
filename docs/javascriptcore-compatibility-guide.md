# JavaScriptCore Compatibility Guide for iOS/macOS

## Executive Summary

**Not all JavaScript libraries work with JavaScriptCore out of the box.** JavaScriptCore is a pure ECMAScript engine and lacks many features that Node.js and browsers provide. This guide explains what works, what doesn't, and how to make libraries compatible.

---

## What is JavaScriptCore?

JavaScriptCore (JSC) is Apple's JavaScript engine used in Safari and available to iOS/macOS apps via the `JavaScriptCore` framework. It provides:

✅ **What JSC Has:**
- ECMAScript 6+ (ES6) support
- Pure JavaScript execution
- Native Swift/Objective-C bridge
- Good performance

❌ **What JSC Lacks:**
- No `require()` or `import` statements (no module system)
- No Node.js APIs (`fs`, `path`, `buffer`, `process`, `crypto`, etc.)
- No browser APIs (`window`, `document`, `fetch`, `XMLHttpRequest`, `localStorage`)
- No npm package resolution
- No async module loading

---

## Library Compatibility Categories

### ✅ Category 1: Pure JavaScript, No Modules (Works Immediately)

These libraries work directly in JavaScriptCore with no modifications:

**Characteristics:**
- Single file (or concatenated files)
- No `require()` or `import` statements
- No Node.js or browser API dependencies
- Exposes functionality via global variables

**Examples:**
- `marked.min.js` - Markdown parser (global: `marked`)
- `lodash.min.js` - Utility library (global: `_`)
- Most UMD bundles with `.min.js` versions
- Libraries specifically built for browsers

**How to use:**
```swift
import JavaScriptCore

let context = JSContext()!

// Load the library
if let path = Bundle.main.path(forResource: "marked.min", ofType: "js"),
   let source = try? String(contentsOfFile: path) {
    context.evaluateScript(source)
}

// Use the library
let html = context.evaluateScript("marked('# Hello World')")?.toString()
```

---

### ⚠️ Category 2: Browser-Targeted (Needs Polyfills)

These libraries expect browser APIs but don't use modules:

**Missing APIs to Polyfill:**
- `atob()` / `btoa()` - Base64 encoding/decoding
- `console.log()` - Logging (JSC has it, but may need enhancement)
- `setTimeout()` / `setInterval()` - Timers (not in JSC by default)
- `fetch()` / `XMLHttpRequest` - HTTP requests
- `localStorage` / `sessionStorage` - Storage
- `window`, `document` - DOM APIs

**Example Polyfills:**

```swift
// Add to JSContext
let context = JSContext()!

// Console polyfill
context.evaluateScript("""
var console = {
    log: function(msg) { _consoleLog(String(msg)); },
    error: function(msg) { _consoleError(String(msg)); },
    warn: function(msg) { _consoleWarn(String(msg)); }
};
""")

// Bridge to Swift
let consoleLog: @convention(block) (String) -> Void = { msg in
    print("[JS]: \(msg)")
}
context.setObject(consoleLog, forKeyedSubscript: "_consoleLog" as NSString)

// atob/btoa polyfill
context.evaluateScript("""
var atob = function(str) {
    // Call Swift implementation
    return _atob(str);
};
var btoa = function(str) {
    return _btoa(str);
};
""")

// Swift implementation
let atob: @convention(block) (String) -> String? = { base64 in
    guard let data = Data(base64Encoded: base64),
          let string = String(data: data, encoding: .utf8) else {
        return nil
    }
    return string
}
context.setObject(atob, forKeyedSubscript: "_atob" as NSString)
```

**Common Browser Libraries:**
- `crypto-js` - Needs minimal polyfills
- `validator.js` - Pure JS, usually works
- `moment.js` - Works with minimal setup

---

### ❌ Category 3: Node.js Modules (Needs Bundling)

These libraries use CommonJS (`require()`) or ES Modules (`import`):

**Characteristics:**
- Uses `require()` to load dependencies
- Uses `module.exports` or `export` statements
- Distributed via npm
- May depend on Node.js built-in modules

**Examples from Your List:**
- `curlconverter` - Uses CommonJS
- `quicktype` - Complex module dependencies
- `sql-formatter` - Likely uses modules
- `json-repair` - May use modules
- `cron-parser` - Uses modules

**Solution: Bundling Required**

You need to bundle these libraries into a single file that works in browsers (and therefore JSC).

---

## How to Make Libraries Work: Bundling Guide

### Option 1: Use Existing Browser Builds (Easiest)

Many libraries provide pre-built browser versions:

**Check for these files in the npm package:**
- `dist/library-name.min.js`
- `dist/library-name.umd.js`
- `browser/index.js`
- Files listed in `package.json` under `"browser"` field

**How to find them:**
1. Check the library's GitHub releases page
2. Look in CDN services like:
   - [cdnjs.com](https://cdnjs.com/)
   - [unpkg.com](https://unpkg.com/)
   - [jsdelivr.com](https://www.jsdelivr.com/)

**Example:**
```
// marked.js is available at:
https://cdn.jsdelivr.net/npm/marked/marked.min.js

// Download and include in your Xcode project
```

---

### Option 2: Bundle with Webpack (Most Common)

If no browser build exists, create one with Webpack:

**Step 1: Install Dependencies**
```bash
npm install --save-dev webpack webpack-cli
npm install the-library-name
```

**Step 2: Create `webpack.config.js`**
```javascript
const path = require('path');

module.exports = {
  mode: 'production',
  entry: './src/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'library.min.js',
    library: 'LibraryName',
    libraryTarget: 'umd',
    globalObject: 'this'
  },
  resolve: {
    fallback: {
      // Polyfill Node.js modules if needed
      "path": require.resolve("path-browserify"),
      "buffer": require.resolve("buffer/"),
      "crypto": require.resolve("crypto-browserify"),
      "stream": require.resolve("stream-browserify"),
      "util": require.resolve("util/"),
      "process": require.resolve("process/browser"),
      // Set to false to ignore
      "fs": false,
      "net": false,
      "tls": false
    }
  }
};
```

**Step 3: Create Entry File (`src/index.js`)**
```javascript
// Import the library
const library = require('the-library-name');

// Export it as a global
if (typeof window !== 'undefined') {
  window.LibraryName = library;
}

// For JavaScriptCore
if (typeof global !== 'undefined') {
  global.LibraryName = library;
}

// Also export normally
module.exports = library;
```

**Step 4: Build**
```bash
npx webpack
```

**Step 5: Use in Swift**
```swift
// Load dist/library.min.js into JSContext
let result = context.evaluateScript("LibraryName.someFunction('input')")
```

---

### Option 3: Bundle with Browserify (Alternative)

Browserify is simpler than Webpack for basic bundling:

**Step 1: Install**
```bash
npm install -g browserify
npm install the-library-name
```

**Step 2: Create Entry File (`index.js`)**
```javascript
const library = require('the-library-name');
window.LibraryName = library; // or global.LibraryName
```

**Step 3: Bundle**
```bash
browserify index.js --standalone LibraryName > bundle.js
```

The `--standalone` flag creates a UMD bundle.

---

### Option 4: Use ESBuild (Fastest)

ESBuild is extremely fast for bundling:

**Step 1: Install**
```bash
npm install --save-dev esbuild
npm install the-library-name
```

**Step 2: Create Entry File (`index.js`)**
```javascript
import library from 'the-library-name';
globalThis.LibraryName = library;
export default library;
```

**Step 3: Bundle**
```bash
npx esbuild index.js --bundle --outfile=bundle.js --format=iife --global-name=LibraryName
```

`--format=iife` creates an immediately-invoked function expression that works in browsers and JSC.

---

## Specific Libraries Analysis

Let me analyze the JavaScript libraries I recommended:

### ✅ Ready to Use (Browser Builds Available)

| Library | CDN Link | Global Variable |
|---------|----------|-----------------|
| **marked** | [jsdelivr](https://cdn.jsdelivr.net/npm/marked/marked.min.js) | `marked` |
| **jsdiff** | [cdnjs](https://cdnjs.cloudflare.com/ajax/libs/jsdiff/5.1.0/diff.min.js) | `Diff` |
| **js-beautify** | [cdnjs](https://cdnjs.cloudflare.com/ajax/libs/js-beautify/1.14.9/beautify.min.js) | `js_beautify` |
| **crypto-js** | [cdnjs](https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.1.1/crypto-js.min.js) | `CryptoJS` |
| **lorem-ipsum** | [unpkg](https://unpkg.com/lorem-ipsum@2.0.8/dist/index.js) | Check docs |
| **change-case** | May need bundling | - |

### ⚠️ Needs Bundling

| Library | Reason | Difficulty |
|---------|--------|------------|
| **curlconverter** | Node.js modules | Medium |
| **quicktype** | Complex, many deps | Hard |
| **sql-formatter** | ES modules | Medium |
| **json-repair** | Probably modules | Easy |
| **cron-parser** | CommonJS | Easy |
| **Papa Parse** | Has browser build | Easy ✅ |
| **color-convert** | Tiny, easy to bundle | Easy |
| **node-html-to-jsx** | Needs bundling | Medium |

### ✅ Papa Parse (CSV Parser) - Ready to Use!

Papa Parse has an excellent browser build:
```html
<!-- Available at -->
https://cdn.jsdelivr.net/npm/papaparse@5.4.1/papaparse.min.js
<!-- Global: Papa -->
```

---

## Practical Bundling Examples

### Example 1: Bundle `cron-parser`

```bash
# Install
npm install cron-parser

# Create index.js
cat > index.js << 'EOF'
const parser = require('cron-parser');
globalThis.CronParser = parser;
module.exports = parser;
EOF

# Bundle with esbuild
npx esbuild index.js --bundle --outfile=cron-parser.min.js --format=iife --global-name=CronParser --minify

# Use in Swift
# Load cron-parser.min.js
# let result = context.evaluateScript("CronParser.parseExpression('*/5 * * * *')")
```

### Example 2: Bundle `json-repair`

```bash
npm install json-repair

cat > index.js << 'EOF'
const { jsonRepair } = require('json-repair');
globalThis.jsonRepair = jsonRepair;
EOF

npx esbuild index.js --bundle --outfile=json-repair.min.js --format=iife --global-name=jsonRepair --minify
```

### Example 3: Bundle `sql-formatter`

```bash
npm install sql-formatter

cat > index.js << 'EOF'
const { format } = require('sql-formatter');
globalThis.sqlFormatter = { format };
EOF

npx esbuild index.js --bundle --outfile=sql-formatter.min.js --format=iife --global-name=sqlFormatter --minify
```

---

## Testing Bundled Libraries

### Test in Node.js First

Before using in JavaScriptCore, test that your bundle works:

```bash
node -e "
const fs = require('fs');
const script = fs.readFileSync('bundle.min.js', 'utf8');
eval(script);
console.log(typeof LibraryName); // Should print 'object' or 'function'
console.log(LibraryName.someMethod('test')); // Test functionality
"
```

### Test in JavaScriptCore

```swift
import JavaScriptCore

let context = JSContext()!

// Set up exception handler
context.exceptionHandler = { context, exception in
    print("JS Error: \(exception?.toString() ?? "unknown")")
}

// Load bundle
guard let path = Bundle.main.path(forResource: "bundle.min", ofType: "js"),
      let source = try? String(contentsOfFile: path) else {
    print("Failed to load bundle")
    return
}

context.evaluateScript(source)

// Test
if let result = context.evaluateScript("typeof LibraryName") {
    print("Library loaded: \(result.toString())")
}

if let result = context.evaluateScript("LibraryName.someMethod('test')") {
    print("Result: \(result.toString())")
}
```

---

## Handling Complex Cases

### When Libraries Use Node.js APIs

Some libraries use Node.js built-in modules like `fs`, `path`, `crypto`:

**Solution 1: Webpack Polyfills**

Install browser polyfills:
```bash
npm install --save-dev \
  path-browserify \
  crypto-browserify \
  stream-browserify \
  buffer \
  util \
  process
```

Add to `webpack.config.js`:
```javascript
resolve: {
  fallback: {
    "path": require.resolve("path-browserify"),
    "crypto": require.resolve("crypto-browserify"),
    "stream": require.resolve("stream-browserify"),
    "buffer": require.resolve("buffer/"),
    "util": require.resolve("util/"),
    "process": require.resolve("process/browser"),
  }
}
```

**Solution 2: Mock APIs**

For libraries that just check for Node.js APIs:
```javascript
// Add to bundle
if (typeof process === 'undefined') {
  globalThis.process = { env: {} };
}
if (typeof Buffer === 'undefined') {
  globalThis.Buffer = {
    from: function(str) { return str; },
    isBuffer: function() { return false; }
  };
}
```

### When Libraries Are Too Complex

Some libraries (like `quicktype`) have massive dependency trees. Options:

1. **Use Web API**: If the library has a web version, call it from Swift using URLSession
2. **Find Alternatives**: Look for simpler libraries
3. **Native Implementation**: Write Swift code instead
4. **Node.js Sidecar**: Run Node.js as a subprocess (more complex)

---

## Recommended Workflow

### For Each JavaScript Library:

1. **Check for browser builds**
   - Look in package.json `"browser"` field
   - Search CDN services (cdnjs, unpkg, jsdelivr)
   - Check GitHub releases

2. **If no browser build, bundle it**
   - Use esbuild (fastest) or webpack (most flexible)
   - Target `iife` or `umd` format
   - Set `global-name` for library access
   - Minify for smaller size

3. **Test the bundle**
   - Test in Node.js with `eval()`
   - Test in JavaScriptCore with simple calls
   - Check for errors in exception handler

4. **Add to Xcode project**
   - Add .js file to Resources
   - Load in JSContext on app launch
   - Cache JSContext for performance

---

## Performance Considerations

### JSContext Lifecycle

**❌ Bad: Create context every time**
```swift
func hashString(_ input: String) -> String {
    let context = JSContext()! // Slow!
    context.evaluateScript(cryptoJSSource)
    return context.evaluateScript("CryptoJS.SHA256('\(input)')").toString()
}
```

**✅ Good: Reuse context**
```swift
class JSManager {
    static let shared = JSManager()
    let context: JSContext

    private init() {
        context = JSContext()!
        loadLibraries()
    }

    private func loadLibraries() {
        // Load all JS libraries once
        loadScript(name: "marked.min")
        loadScript(name: "crypto-js.min")
        // etc.
    }
}

func hashString(_ input: String) -> String {
    let context = JSManager.shared.context
    return context.evaluateScript("CryptoJS.SHA256('\(input)')").toString()
}
```

### Bundle Size

Minimize bundle sizes:
- Use minified versions
- Enable tree-shaking (webpack/esbuild)
- Only include needed functions
- Consider splitting large libraries

---

## Troubleshooting Common Issues

### "ReferenceError: require is not defined"

**Cause**: Library uses CommonJS modules
**Solution**: Bundle the library with webpack/browserify/esbuild

### "ReferenceError: global is not defined"

**Cause**: Library expects Node.js global object
**Solution**: Add polyfill
```javascript
if (typeof global === 'undefined') {
    var global = globalThis;
}
```

### "ReferenceError: Buffer is not defined"

**Cause**: Library uses Node.js Buffer API
**Solution**: Include buffer polyfill in webpack config or add mock

### "TypeError: undefined is not an object"

**Cause**: Library expects browser APIs
**Solution**: Add polyfills for missing APIs (atob, fetch, etc.)

### Bundle is huge (>1MB)

**Cause**: Including unnecessary dependencies
**Solution**:
- Check if library has a "lite" version
- Use webpack tree-shaking
- Consider alternative libraries
- Split into multiple bundles

---

## Summary Table: JavaScript Libraries for Your Tools

| Tool | Library | Compatibility | Action Needed |
|------|---------|---------------|---------------|
| Text Diff | jsdiff | ✅ Browser build | Download from CDN |
| HTML/CSS/JS Beautify | js-beautify | ✅ Browser build | Download from CDN |
| Markdown | marked | ✅ Browser build | Download from CDN |
| CSV/JSON | Papa Parse | ✅ Browser build | Download from CDN |
| Lorem Ipsum | lorem-ipsum | ⚠️ May need bundle | Test/bundle |
| JSON Repair | json-repair | ⚠️ Needs bundling | Bundle with esbuild |
| Cron Parser | cron-parser | ⚠️ Needs bundling | Bundle with esbuild |
| SQL Formatter | sql-formatter | ⚠️ Needs bundling | Bundle with esbuild |
| Case Converter | change-case | ⚠️ Needs bundling | Bundle with esbuild |
| Color Convert | color-convert | ⚠️ Needs bundling | Bundle with esbuild |
| HTML→JSX | node-html-to-jsx | ⚠️ Needs bundling | Bundle with webpack |
| cURL→Code | curlconverter | ❌ Complex | Bundle or use API |
| JSON→Code | quicktype | ❌ Very complex | Consider alternatives |

---

## Alternative: Native Swift Implementation

For some tools, implementing in Swift may be simpler than JavaScript:

**Consider Swift when:**
- Library is very complex to bundle
- Performance is critical
- You want type safety
- Library has simple algorithm

**Examples:**
- Case converter (simple string manipulation)
- Lorem ipsum (word list + randomization)
- Color converter (math formulas)
- Base converter (built into Swift)

---

## Resources

- [JavaScriptCore Documentation](https://developer.apple.com/documentation/javascriptcore)
- [Using JavaScriptCore in Production iOS App](https://gist.github.com/mheiber/9e35ddb29ee2a76bd44b3cc1193a9215)
- [Webpack Documentation](https://webpack.js.org/)
- [ESBuild Documentation](https://esbuild.github.io/)
- [Browserify Handbook](https://github.com/browserify/browserify-handbook)
- [cdnjs - JavaScript CDN](https://cdnjs.com/)
- [unpkg - npm CDN](https://unpkg.com/)

---

**Last Updated**: January 2026

