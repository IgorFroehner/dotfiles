BINARY = bin/sbar_panel
SOURCES = $(wildcard Sources/*.swift)
FRAMEWORKS = -framework Cocoa -framework SwiftUI -framework CoreAudio -framework IOKit

$(BINARY): $(SOURCES) | bin
	swiftc -O $(SOURCES) $(FRAMEWORKS) -o $@

bin:
	mkdir -p bin

clean:
	rm -rf bin

.PHONY: clean
