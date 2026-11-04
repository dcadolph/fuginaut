APP := .build/Fuginaut.app
SIGN_ID ?= -
# A real identity gets a secure timestamp, which notarization requires. Ad-hoc builds skip it so local
# builds never need the network.
TIMESTAMP := $(if $(filter -,$(SIGN_ID)),,--timestamp)
ARCHS ?=
ARCH_FLAGS := $(foreach arch,$(ARCHS),--arch $(arch))
ZIP ?= .build/Fuginaut.zip
DMG ?= .build/Fuginaut.dmg
DMGBUILD ?= dmgbuild
FORMAT_PATHS := Package.swift Sources Tests

ICON := art/app-icon.png
ICONSET := .build/AppIcon.iconset
ICNS := .build/AppIcon.icns
# The icon is optional for local builds until the art lands. The release workflow requires it.
ICON_DEP := $(wildcard $(ICON))

.PHONY: build test lint format app zip dmg run clean

build:
	swift build -Xswiftc -warnings-as-errors

test: build
	swift test -Xswiftc -warnings-as-errors

lint:
	xcrun swift-format lint --strict --recursive $(FORMAT_PATHS)

format:
	xcrun swift-format format -i --recursive $(FORMAT_PATHS)

$(ICNS): $(ICON)
	rm -rf $(ICONSET)
	mkdir -p $(ICONSET)
	for size in 16 32 128 256 512; do \
		sips -z $$size $$size $(ICON) --out $(ICONSET)/icon_$${size}x$${size}.png >/dev/null; \
		sips -z $$((size * 2)) $$((size * 2)) $(ICON) --out $(ICONSET)/icon_$${size}x$${size}@2x.png >/dev/null; \
	done
	iconutil -c icns $(ICONSET) -o $(ICNS)

app: $(if $(ICON_DEP),$(ICNS))
	swift build -c release $(ARCH_FLAGS)
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp "$$(swift build -c release $(ARCH_FLAGS) --show-bin-path)/Fuginaut" $(APP)/Contents/MacOS/Fuginaut
	cp Sources/Fuginaut/Info.plist $(APP)/Contents/Info.plist
	$(if $(ICON_DEP),cp $(ICNS) $(APP)/Contents/Resources/AppIcon.icns)
	codesign --force --options runtime $(TIMESTAMP) --sign "$(SIGN_ID)" $(APP)

zip: app
	rm -f $(ZIP)
	ditto -c -k --keepParent $(APP) $(ZIP)

dmg:
	rm -f $(DMG)
	$(DMGBUILD) -s dmg.py -D app=$(APP) "Fuginaut" $(DMG)
	$(if $(filter-out -,$(SIGN_ID)),codesign --force --sign "$(SIGN_ID)" --timestamp $(DMG))

run: app
	-pkill -x Fuginaut
	open $(APP)

clean:
	rm -rf .build
