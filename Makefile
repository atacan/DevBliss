install-formatters:
	brew install swiftformat
	brew install swift-format

precommit:
	touch .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
	echo '#!/bin/bash\n\nmake format' > .git/hooks/pre-commit

start: install-formatters precommit

format:
	# nicklockwood/SwiftFormat
	swiftformat --config .swiftformat --swiftversion 5.7 .
	# apple/swift-format
	swift-format . -i -p --ignore-unparsable-files -r --configuration .swift-format