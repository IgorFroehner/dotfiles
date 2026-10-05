# An app bundle (not a bare binary) so Location Services can grant it permission
APP = bin/SSID.app
BINARY = $(APP)/Contents/MacOS/ssid

$(BINARY): Sources/main.swift Info.plist
	mkdir -p $(APP)/Contents/MacOS
	cp Info.plist $(APP)/Contents/Info.plist
	swiftc -O Sources/main.swift -framework CoreLocation -framework CoreWLAN -o $@
	codesign --force --sign - $(APP)

clean:
	rm -rf bin

.PHONY: clean
