
build:
  swift build
  
build-heavy-debug:
  swift build -Xswiftc -DHEAVY_DEBUG
  
build-release:
  swift build -c release
  
build-all: build build-heavy-debug build-release

test:
  swift test
  
test-heavy-debug:
  swift test -Xswiftc -DHEAVY_DEBUG
  
test-release:
  swift test -c release
  
test-all: test test-heavy-debug test-release

lint-format:
  swift-format lint -r ./Sources ./Tests

[confirm]  
bulk-reformat:
  swift-format format -i -r ./Sources ./Tests
  