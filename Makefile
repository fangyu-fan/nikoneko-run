SCHEME = nikoneko
PROJECT = nikoneko.xcodeproj
DESTINATION = platform=iOS Simulator,id=449C3F0D-7074-4D89-972A-8943E8D1308F

build:
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -destination "$(DESTINATION)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination "$(DESTINATION)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED|Test Suite|passed|failed)"

lint:
	swiftlint lint --strict

clean:
	xcodebuild clean -project $(PROJECT) -scheme $(SCHEME)
	rm -rf ~/Library/Developer/Xcode/DerivedData

.PHONY: build test lint clean
