# install the swift formatters and pre-commit hook helper
install-formatters:
	brew install swiftformat
	brew install swift-format
	# npm install --save-dev git-format-staged

# Create and fill the pre-commit hook
precommit:
	touch .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
	echo '#!/bin/bash' > .git/hooks/pre-commit
	echo '' >> .git/hooks/pre-commit
	# echo 'git-format-staged --formatter "swift-format . -i -p --ignore-unparsable-files -r --configuration .swift-format '\''{}'\''" "*.swift"' >> .git/hooks/pre-commit
	echo 'git-format-staged --formatter "swiftformat --config .swiftformat --swiftversion 5.7 stdin --stdinpath '\''{}'\''" "*.swift"' >> .git/hooks/pre-commit

# Setup the environment
start: install-formatters precommit

# Run the formatters manually
format:
	# nicklockwood/SwiftFormat
	swiftformat --config .swiftformat --swiftversion 5.7 .
	# apple/swift-format
	swift-format . -i -p --ignore-unparsable-files -r --configuration .swift-format
	# commit
	git add .
	git commit -m "Format code"

en-xcloc:
	xcodebuild -exportLocalizations -localizationPath ./localisations/ -exportLanguage en -sdk iphoneos16.4

import-xcloc:
	for lang in de nl fr it ja pl pt es tr sq zh ko ru; do \
		if [ -d "./localisations/$$lang.xcloc/" ]; then \
			xcodebuild -importLocalizations -localizationPath ./localisations/$$lang.xcloc/ -sdk iphoneos16.4 ; \
		else \
			echo "Directory ./localisations/$$lang.xcloc/ does not exist." ; \
		fi ; \
	done