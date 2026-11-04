APP := .build/Fuginaut.app
SIGN_ID ?= -
# A real identity gets a secure timestamp, which notarization requires. Ad-hoc builds skip it so local
# builds never need the network.
TIMESTAMP := $(if $(filter -,$(SIGN_ID)),,--timestamp)
ARCHS ?=
ARCH_FLAGS := $(foreach arch,$(ARCHS),--arch $(arch))
ZIP ?= .build/Fuginaut.zip

.PHONY: build test app zip run clean

build:
	swift build

test:
	swift build
	swift test

app:
	swift build -c release $(ARCH_FLAGS)
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp "$$(swift build -c release $(ARCH_FLAGS) --show-bin-path)/Fuginaut" $(APP)/Contents/MacOS/Fuginaut
	cp Sources/Fuginaut/Info.plist $(APP)/Contents/Info.plist
	codesign --force --options runtime $(TIMESTAMP) --sign "$(SIGN_ID)" $(APP)

zip: app
	rm -f $(ZIP)
	ditto -c -k --keepParent $(APP) $(ZIP)

run: app
	-pkill -x Fuginaut
	open $(APP)

clean:
	rm -rf .build
