
- [Overview](#overview)
- [Tools](#tools)
- [Contributing](#contributing)
  - [Adding a new tool](#adding-a-new-tool)
  - [Setup](#setup)
- [License](#license)
- [Similar projects](#similar-projects)

## Overview

DevBliss is a bag of tools to help developers be more productive. We want to use such tools locally instead of in an online website with bunch of ads and privacy concerns.

## Tools
- Converters
  1. Html to Swift
  2. Text Case
  3. Prefix Suffix Replace and Add
  4. Regex Match Extract
- Formatters
  1. JSON
- Generators
  1. UUID 

## Contributing

The structure is based on pointfree.co's [isowords](https://github.com/pointfreeco/isowords) project. Every feature is a library in the swift package and the app's Xcode project is barebones.

### Adding a new tool
1. Add a case to the enum in SharedModels/Tool.swift
1. Update state and actions in AppFeature/AppReducer.swift. Fix `switch must be exhaustive errors.`

### Setup

1. `make start` to set up the pre-commit hooks
1. `open App/DevBliss.xcodeproj` to open the project in Xcode

## License

MIT

## Similar projects

- [DevToys](https://devtoys.app/)