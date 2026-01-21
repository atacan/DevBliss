# DevBliss Tool Implementation Complexity Groups

This document groups all open issues by their implementation complexity based on whether they can be implemented in native Swift, use pre-bundled single JavaScript files, or require complex bundling.

## 1. Native Swift Implementation (Simple - No JS needed)

These tools can be implemented using Foundation, CryptoKit, AppKit/UIKit, or simple Swift packages:

### Very Simple (Foundation/Standard Library):
- **DevBliss-l13** - Line Sort/Dedupe Tool
- **DevBliss-chj** - ASCII to Hex Tool
- **DevBliss-e8x** - Hex to ASCII Tool
- **DevBliss-2px** - Random String Generator Tool
- **DevBliss-rho** - Hash Generator Tool (CryptoKit)
- **DevBliss-0pt** - String Inspector Tool
- **DevBliss-d1t** - Number Base Converter Tool
- **DevBliss-nea** - URL Parser Tool (URLComponents)
- **DevBliss-6ju** - RegExp Tester Tool (NSRegularExpression)
- **DevBliss-58f** - HTML Preview Tool (WKWebView)

### Simple to Moderate:
- **DevBliss-jno** - Color Converter Tool (AppKit color APIs)
- **DevBliss-a8g** - SVG to CSS Tool (URL encoding)
- **DevBliss-x7c** - Backslash Escape/Unescape Tool (string manipulation)
- **DevBliss-vvn** - XML Beautify/Minify Tool (XMLDocument)

## 2. Swift Package Manager (SPM) Dependencies

These tools use well-maintained Swift packages:

- **DevBliss-sc5** - Certificate Decoder (X.509) Tool
  - Package: `apple/swift-certificates` + `apple/swift-asn1`

- **DevBliss-2u3** - QR Code Reader/Generator Tool
  - Package: `dagronf/QRCode`

- **DevBliss-uyh** - JSON to YAML Tool
  - Package: `jpsim/Yams`

- **DevBliss-0ry** - YAML to JSON Tool
  - Package: `jpsim/Yams`

- **DevBliss-djj** - UUID/ULID Generate/Decode Tool
  - Native UUID + Package: `yaslab/ULID.swift`

## 3. Pre-bundled Single JavaScript (CDN Available - No Bundling)

These tools use JavaScript libraries available as pre-built single files from CDNs:

- **DevBliss-7w1** - HTML Beautify/Minify Tool
  - JS: `beautify-html.min.js` (from CDN)

- **DevBliss-4q5** - CSS Beautify/Minify Tool
  - JS: `beautify-css.min.js` (from CDN)

- **DevBliss-ubb** - JS Beautify/Minify Tool
  - JS: `js-beautify.min.js` (from CDN)

- **DevBliss-6x1** - Text Diff Checker Tool
  - JS: `jsdiff.min.js` (from CDN)

- **DevBliss-peg** - Markdown Preview Tool
  - JS: `marked.min.js` (from CDN)

## 4. Complex Bundling Required (esbuild or webpack)

These tools need JavaScript libraries that require bundling with esbuild:

### Moderate Complexity (esbuild):

- **DevBliss-a9l** - HTML Entity Encode/Decode Tool
  - npm: `he` → bundle with esbuild

- **DevBliss-2z9** - HTML to JSX Tool
  - npm: `node-html-to-jsx` → bundle with esbuild

- **DevBliss-1ax** - SQL Formatter Tool
  - npm: `sql-formatter` → bundle with esbuild

- **DevBliss-qss** - String Case Converter Tool
  - npm: `change-case` → bundle with esbuild


- **DevBliss-8r9** - Cron Job Parser Tool
  - npm: `cronstrue` + `cron-parser` → bundle with esbuild

- **DevBliss-bj2** - CSV to JSON Tool
  - npm: `papaparse` → bundle with esbuild (or use CDN)

- **DevBliss-qwj** - JSON to CSV Tool
  - npm: `papaparse` → bundle with esbuild (or use CDN)

- **DevBliss-7bg** - Lorem Ipsum Generator Tool
  - npm: `lorem-ipsum` → bundle with esbuild

### Very Complex (May require webpack or subprocess):
- **DevBliss-qif** - JSON to Code Tool
  - npm: `quicktype-core` → very complex bundling (consider CLI subprocess instead)

- **DevBliss-iar** - cURL to Code Tool
  - npm: `curlconverter` → complex bundling (or use their web API)

## 5. Lower Priority / Niche Tools

These are lower priority based on issue priority field (priority 3) or niche use cases:

- **DevBliss-a5i** - SCSS Beautify/Minify Tool (priority 3)
  - npm: `sass-formatter` → bundle with esbuild

- **DevBliss-24h** - LESS Beautify/Minify Tool (priority 3)
  - npm: `less.js` → requires webpack bundling

- **DevBliss-1lv** - ERB Beautify/Minify Tool (priority 3)
  - Niche format, consider skipping or using HTML beautifier

## 6. Code Quality / Refactoring

- **DevBliss-vnm** - Fix initialization pattern in tool reducers
  - Code consistency improvement (not blocking)

---

## Summary by Implementation Effort

### Quick Wins (Native Swift - 15 tools):
Start with these - no external dependencies or simple SPM packages
- 10 Foundation/Standard Library tools
- 5 Swift Package Manager tools

### Medium Effort (Pre-bundled JS - 5 tools):
Download single JS files from CDN, no bundling needed

### Higher Effort (Bundling Required - 12 tools):
Need esbuild or webpack to bundle npm packages
- 8 moderate complexity (esbuild)
- 4 very complex (may need subprocess or API calls)

### Lower Priority (3 tools):
Priority 3 issues - implement after core tools

---

## Recommended Implementation Order

1. **Phase 1**: Native Swift tools (DevBliss-l13, DevBliss-chj, DevBliss-e8x, etc.)
2. **Phase 2**: SPM packages (DevBliss-sc5, DevBliss-2u3, DevBliss-uyh, etc.)
3. **Phase 3**: Pre-bundled JS from CDN (DevBliss-peg, DevBliss-7w1, DevBliss-4q5, etc.)
4. **Phase 4**: Moderate bundling (DevBliss-qss, DevBliss-a9l, DevBliss-8r9, etc.)
5. **Phase 5**: Complex tools (DevBliss-qif, DevBliss-iar)
6. **Phase 6**: Lower priority tools (DevBliss-a5i, DevBliss-24h, DevBliss-1lv)
