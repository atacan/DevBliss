# Quick Reference: Bundling JavaScript Libraries for JavaScriptCore

## Setup (One-Time)

```bash
# Install Node.js and npm (if not already installed)
# On macOS:
brew install node

# Install bundlers globally
npm install -g esbuild webpack webpack-cli browserify
```

---

## Quick Bundle Commands

### Template 1: Simple Library (No Node.js Dependencies)

```bash
# Install library
npm install library-name

# Create wrapper
cat > index.js << 'EOF'
const library = require('library-name');
globalThis.LibraryName = library;
EOF

# Bundle with esbuild (fastest, recommended)
npx esbuild index.js \
  --bundle \
  --outfile=library-name.min.js \
  --format=iife \
  --global-name=LibraryName \
  --minify
```

### Template 2: Library with Node.js Dependencies

```bash
# Install library + polyfills
npm install library-name
npm install --save-dev \
  path-browserify \
  crypto-browserify \
  stream-browserify \
  buffer \
  process

# Create webpack.config.js
cat > webpack.config.js << 'EOF'
const path = require('path');

module.exports = {
  mode: 'production',
  entry: './index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.min.js',
    library: 'LibraryName',
    libraryTarget: 'umd',
    globalObject: 'this'
  },
  resolve: {
    fallback: {
      "path": require.resolve("path-browserify"),
      "crypto": require.resolve("crypto-browserify"),
      "stream": require.resolve("stream-browserify"),
      "buffer": require.resolve("buffer/"),
      "process": require.resolve("process/browser"),
      "fs": false,
      "net": false
    }
  }
};
EOF

# Create wrapper
cat > index.js << 'EOF'
const library = require('library-name');
if (typeof globalThis !== 'undefined') {
  globalThis.LibraryName = library;
}
module.exports = library;
EOF

# Bundle
npx webpack
```

---

## Specific Libraries: Copy-Paste Commands

### cron-parser

```bash
npm install cron-parser

cat > cron-parser-wrapper.js << 'EOF'
const parser = require('cron-parser');
globalThis.CronParser = parser;
EOF

npx esbuild cron-parser-wrapper.js \
  --bundle \
  --outfile=cron-parser.min.js \
  --format=iife \
  --global-name=CronParser \
  --minify

# Result: cron-parser.min.js
# Usage in Swift: context.evaluateScript("CronParser.parseExpression('*/5 * * * *')")
```

### cronstrue (human-readable cron)

```bash
npm install cronstrue

cat > cronstrue-wrapper.js << 'EOF'
const cronstrue = require('cronstrue');
globalThis.cronstrue = cronstrue;
EOF

npx esbuild cronstrue-wrapper.js \
  --bundle \
  --outfile=cronstrue.min.js \
  --format=iife \
  --global-name=cronstrue \
  --minify

# Usage: context.evaluateScript("cronstrue.toString('*/5 * * * *')")
```

### json-repair

```bash
npm install json-repair

cat > json-repair-wrapper.js << 'EOF'
const { jsonRepair } = require('json-repair');
globalThis.jsonRepair = jsonRepair;
EOF

npx esbuild json-repair-wrapper.js \
  --bundle \
  --outfile=json-repair.min.js \
  --format=iife \
  --global-name=jsonRepair \
  --minify

# Usage: context.evaluateScript("jsonRepair('{invalid json}')")
```

### sql-formatter

```bash
npm install sql-formatter

cat > sql-formatter-wrapper.js << 'EOF'
const { format } = require('sql-formatter');
globalThis.sqlFormatter = { format };
EOF

npx esbuild sql-formatter-wrapper.js \
  --bundle \
  --outfile=sql-formatter.min.js \
  --format=iife \
  --global-name=sqlFormatter \
  --minify

# Usage: context.evaluateScript("sqlFormatter.format('SELECT * FROM users WHERE id=1')")
```

### color-convert

```bash
npm install color-convert

cat > color-convert-wrapper.js << 'EOF'
const convert = require('color-convert');
globalThis.colorConvert = convert;
EOF

npx esbuild color-convert-wrapper.js \
  --bundle \
  --outfile=color-convert.min.js \
  --format=iife \
  --global-name=colorConvert \
  --minify

# Usage: context.evaluateScript("colorConvert.hex.rgb('FFFFFF')")
```

### change-case

```bash
npm install change-case

cat > change-case-wrapper.js << 'EOF'
const changeCase = require('change-case');
globalThis.changeCase = changeCase;
EOF

npx esbuild change-case-wrapper.js \
  --bundle \
  --outfile=change-case.min.js \
  --format=iife \
  --global-name=changeCase \
  --minify

# Usage: context.evaluateScript("changeCase.camelCase('hello world')")
```

### he (HTML entities)

```bash
npm install he

cat > he-wrapper.js << 'EOF'
const he = require('he');
globalThis.he = he;
EOF

npx esbuild he-wrapper.js \
  --bundle \
  --outfile=he.min.js \
  --format=iife \
  --global-name=he \
  --minify

# Usage: context.evaluateScript("he.encode('<div>')")
```

### curlconverter

```bash
npm install curlconverter

cat > curlconverter-wrapper.js << 'EOF'
const curlconverter = require('curlconverter');
globalThis.curlconverter = curlconverter;
EOF

npx esbuild curlconverter-wrapper.js \
  --bundle \
  --outfile=curlconverter.min.js \
  --format=iife \
  --global-name=curlconverter \
  --minify

# Usage: context.evaluateScript("curlconverter.toSwift('curl https://example.com')")
```

### jsonpath-plus (JSON Path queries)

```bash
npm install jsonpath-plus

cat > jsonpath-wrapper.js << 'EOF'
const { JSONPath } = require('jsonpath-plus');
globalThis.JSONPath = JSONPath;
EOF

npx esbuild jsonpath-wrapper.js \
  --bundle \
  --outfile=jsonpath.min.js \
  --format=iife \
  --global-name=JSONPath \
  --minify

# Usage: context.evaluateScript("JSONPath({path: '$.store.book[*].author', json: data})")
```

### less (LESS compiler)

```bash
npm install less

cat > less-wrapper.js << 'EOF'
const less = require('less');
globalThis.less = less;
EOF

# LESS is complex, use webpack
npm install --save-dev webpack webpack-cli

cat > webpack.config.js << 'EOF'
module.exports = {
  mode: 'production',
  entry: './less-wrapper.js',
  output: {
    filename: 'less.min.js',
    library: 'less',
    libraryTarget: 'umd',
    globalObject: 'this'
  },
  resolve: {
    fallback: {
      "path": false,
      "fs": false
    }
  }
};
EOF

npx webpack

# Usage: less.render(lessCode).then(output => ...)
```

---

## Download Pre-Built Libraries (No Bundling Needed!)

### jsdiff
```bash
curl -o jsdiff.min.js https://cdnjs.cloudflare.com/ajax/libs/jsdiff/5.1.0/diff.min.js
# Global: Diff
# Usage: Diff.diffWords('old text', 'new text')
```

### js-beautify
```bash
curl -o js-beautify.min.js https://cdnjs.cloudflare.com/ajax/libs/js-beautify/1.14.9/beautify.min.js
curl -o css-beautify.min.js https://cdnjs.cloudflare.com/ajax/libs/js-beautify/1.14.9/beautify-css.min.js
curl -o html-beautify.min.js https://cdnjs.cloudflare.com/ajax/libs/js-beautify/1.14.9/beautify-html.min.js
# Global: js_beautify, css_beautify, html_beautify
```

### marked (Markdown)
```bash
curl -o marked.min.js https://cdn.jsdelivr.net/npm/marked/marked.min.js
# Global: marked
# Usage: marked.parse('# Hello')
```

### Papa Parse (CSV)
```bash
curl -o papaparse.min.js https://cdn.jsdelivr.net/npm/papaparse@5.4.1/papaparse.min.js
# Global: Papa
# Usage: Papa.parse(csvString)
```

### crypto-js
```bash
curl -o crypto-js.min.js https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.1.1/crypto-js.min.js
# Global: CryptoJS
# Usage: CryptoJS.SHA256('text').toString()
```

---

## Testing Bundles

### Test in Node.js
```bash
node -e "
const fs = require('fs');
const script = fs.readFileSync('bundle.min.js', 'utf8');
eval(script);
console.log('Global check:', typeof LibraryName);
console.log('Test call:', LibraryName.someMethod('test'));
"
```

### Test in Browser Console
```bash
# Start simple HTTP server
python3 -m http.server 8000

# Create test.html
cat > test.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <script src="bundle.min.js"></script>
</head>
<body>
    <script>
        console.log('Library loaded:', typeof LibraryName);
        console.log('Test:', LibraryName.someMethod('test'));
    </script>
</body>
</html>
EOF

# Open http://localhost:8000/test.html
# Check browser console
```

---

## Swift Integration Template

```swift
import JavaScriptCore

class JSLibraryManager {
    static let shared = JSLibraryManager()
    let context: JSContext

    private init() {
        context = JSContext()!
        setupExceptionHandler()
        loadLibraries()
    }

    private func setupExceptionHandler() {
        context.exceptionHandler = { context, exception in
            print("JS Error: \(exception?.toString() ?? "unknown")")
            if let stack = exception?.objectForKeyedSubscript("stack") {
                print("Stack trace: \(stack)")
            }
        }
    }

    private func loadLibraries() {
        loadScript(name: "cron-parser.min")
        loadScript(name: "sql-formatter.min")
        loadScript(name: "json-repair.min")
        // Add more...
    }

    private func loadScript(name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: "js"),
              let source = try? String(contentsOfFile: path) else {
            print("Failed to load \(name).js")
            return
        }

        context.evaluateScript(source)
        print("Loaded: \(name).js")
    }

    // Helper method for safe JS calls
    func call(_ script: String) -> String? {
        guard let result = context.evaluateScript(script) else {
            return nil
        }
        return result.toString()
    }
}

// Usage examples
extension JSLibraryManager {
    func parseCron(_ expression: String) -> String? {
        let script = """
        try {
            const interval = CronParser.parseExpression('\(expression)');
            interval.next().toString();
        } catch (e) {
            'Error: ' + e.message;
        }
        """
        return call(script)
    }

    func formatSQL(_ sql: String) -> String? {
        let escaped = sql.replacingOccurrences(of: "'", with: "\\'")
        return call("sqlFormatter.format('\(escaped)')")
    }

    func repairJSON(_ json: String) -> String? {
        let escaped = json.replacingOccurrences(of: "'", with: "\\'")
        return call("jsonRepair('\(escaped)')")
    }
}
```

---

## Troubleshooting

### Error: "Cannot find module"
```bash
# Make sure you're in the project directory
cd your-project-directory

# Initialize npm if needed
npm init -y

# Install the library
npm install library-name
```

### Error: "command not found: npx"
```bash
# Install Node.js
brew install node

# Or update npm
npm install -g npm@latest
```

### Bundle is too large
```bash
# Check bundle size
ls -lh bundle.min.js

# Analyze what's in the bundle (webpack only)
npm install --save-dev webpack-bundle-analyzer

# Add to webpack.config.js:
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;
plugins: [new BundleAnalyzerPlugin()]

npx webpack
# Opens visualization in browser
```

### Library doesn't work in JavaScriptCore
```bash
# Check for Node.js dependencies
npm ls library-name

# If it uses fs, path, crypto, etc., you need polyfills
# Use webpack with fallback configuration (see Template 2 above)
```

---

## Project Structure Recommendation

```
YourProject/
├── Scripts/              # JavaScript bundling workspace
│   ├── package.json
│   ├── webpack.config.js
│   ├── wrappers/        # Individual library wrappers
│   │   ├── cron-parser-wrapper.js
│   │   ├── sql-formatter-wrapper.js
│   │   └── ...
│   └── dist/            # Output bundles
│       ├── cron-parser.min.js
│       ├── sql-formatter.min.js
│       └── ...
├── YourApp/
│   └── Resources/       # Copy bundles here for Xcode
│       └── JavaScript/
│           ├── cron-parser.min.js
│           ├── sql-formatter.min.js
│           └── ...
└── YourApp.xcodeproj
```

### Build Script
```bash
#!/bin/bash
# build-js-libraries.sh

cd Scripts

# Bundle each library
npx esbuild wrappers/cron-parser-wrapper.js --bundle --outfile=dist/cron-parser.min.js --format=iife --global-name=CronParser --minify
npx esbuild wrappers/sql-formatter-wrapper.js --bundle --outfile=dist/sql-formatter.min.js --format=iife --global-name=sqlFormatter --minify
# ... add more

# Copy to Xcode resources
cp dist/*.min.js ../YourApp/Resources/JavaScript/

echo "✅ All libraries bundled and copied!"
```

---

## Summary Checklist

- [ ] Install Node.js and npm
- [ ] Install bundlers (esbuild recommended)
- [ ] For each library:
  - [ ] Check if browser build exists (CDN)
  - [ ] If yes: Download and use directly
  - [ ] If no: Bundle with esbuild or webpack
  - [ ] Test bundle in Node.js
  - [ ] Add to Xcode project Resources
  - [ ] Load in JSContext
  - [ ] Test in app
- [ ] Create reusable JSLibraryManager class
- [ ] Add exception handling
- [ ] Cache JSContext for performance

---

*Quick reference guide - January 2026*
