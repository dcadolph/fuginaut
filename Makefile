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

# STORE=1 compiles the Mac App Store flavor, in its own scratch path so it never mixes with direct builds.
STORE ?=
STORE_SCRATCH_PATH := .build/store-scratch
SWIFT := $(if $(STORE),FUGINAUT_STORE=1) swift
SWIFT_FLAVOR_FLAGS := $(if $(STORE),--scratch-path $(STORE_SCRATCH_PATH))
# The Mac App Store build signs with the personal team's Apple Distribution identity and wraps the app in an
# installer package for upload. PROFILE is the downloaded Mac App Store Connect provisioning profile, and
# STORE_BUILD is the build number, which must rise with every upload.
TEAM_ID := U7L4P2YHWJ
BUNDLE_ID := com.dcadolph.fuginaut
STORE_SIGN_ID ?= Apple Distribution: Douglas Adolph ($(TEAM_ID))
INSTALLER_ID ?= 3rd Party Mac Developer Installer: Douglas Adolph ($(TEAM_ID))
PROFILE ?=
STORE_BUILD ?=
PKG ?= .build/Fuginaut.pkg
STORE_APP := .build/store/Fuginaut.app
SANDBOX_APP := .build/sandbox/Fuginaut.app
STORE_ENTITLEMENTS := Fuginaut-store.entitlements
SIGNED_ENTITLEMENTS := .build/store/Fuginaut.entitlements
PROFILE_PLIST := .build/store/profile.plist

.PHONY: build test test-store lint format app zip dmg run sandbox store-check store-preflight appstore site clean

build:
	swift build -Xswiftc -warnings-as-errors

test: build
	swift test -Xswiftc -warnings-as-errors

test-store:
	FUGINAUT_STORE=1 swift test --scratch-path $(STORE_SCRATCH_PATH) -Xswiftc -warnings-as-errors

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
	$(SWIFT) build -c release $(ARCH_FLAGS) $(SWIFT_FLAVOR_FLAGS)
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp "$$($(SWIFT) build -c release $(ARCH_FLAGS) $(SWIFT_FLAVOR_FLAGS) --show-bin-path)/Fuginaut" $(APP)/Contents/MacOS/Fuginaut
	cp Sources/Fuginaut/Info.plist $(APP)/Contents/Info.plist
	$(if $(ICON_DEP),cp $(ICNS) $(APP)/Contents/Resources/AppIcon.icns)
	cp art/astronaut.png $(APP)/Contents/Resources/Astronaut.png
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

# sandbox builds the store flavor under the store's sandbox, without the store's signature, so it can run here.
sandbox:
	$(MAKE) app APP=$(SANDBOX_APP) STORE=1
	$(MAKE) store-check APP=$(SANDBOX_APP)
	codesign --force --options runtime $(TIMESTAMP) --entitlements $(STORE_ENTITLEMENTS) --sign "$(SIGN_ID)" $(SANDBOX_APP)

# store-check refuses a binary that still carries the update checker.
store-check:
	@! grep -q -E 'api\.github\.com|brew upgrade' $(APP)/Contents/MacOS/Fuginaut \
		|| { echo "$(APP) still has the update checker" >&2; exit 1; }

# store-preflight refuses a certificate or profile from outside the personal team before anything is built.
store-preflight:
	@test -n "$(PROFILE)" || { echo "PROFILE=<path to the Mac App Store Connect .provisionprofile> is required" >&2; exit 1; }
	@test -n "$(STORE_BUILD)" || { echo "STORE_BUILD=<number above the last upload> is required" >&2; exit 1; }
	@for id in "$(STORE_SIGN_ID)" "$(INSTALLER_ID)"; do \
		security find-certificate -c "$$id" -p | openssl x509 -noout -subject 2>/dev/null | grep -q "OU *= *$(TEAM_ID)" \
			|| { echo "$$id is not a certificate of team $(TEAM_ID)" >&2; exit 1; }; \
	done
	@mkdir -p $(dir $(PROFILE_PLIST))
	@security cms -D -i "$(PROFILE)" > $(PROFILE_PLIST)
	@test "$$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.application-identifier' $(PROFILE_PLIST))" = "$(TEAM_ID).$(BUNDLE_ID)" \
		|| { echo "$(PROFILE) is not a profile for $(TEAM_ID).$(BUNDLE_ID)" >&2; exit 1; }

appstore: store-preflight
	$(MAKE) app APP=$(STORE_APP) STORE=1 SIGN_ID=- ARCHS="arm64 x86_64"
	$(MAKE) store-check APP=$(STORE_APP)
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(STORE_BUILD)" $(STORE_APP)/Contents/Info.plist
	cp "$(PROFILE)" $(STORE_APP)/Contents/embedded.provisionprofile
	# App Store processing refuses any file with the quarantine attribute a downloaded profile carries.
	xattr -cr $(STORE_APP)
	cp $(STORE_ENTITLEMENTS) $(SIGNED_ENTITLEMENTS)
	/usr/libexec/PlistBuddy -c "Add :com.apple.application-identifier string $(TEAM_ID).$(BUNDLE_ID)" $(SIGNED_ENTITLEMENTS)
	/usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $(TEAM_ID)" $(SIGNED_ENTITLEMENTS)
	codesign --force --options runtime --timestamp --entitlements $(SIGNED_ENTITLEMENTS) --sign "$(STORE_SIGN_ID)" $(STORE_APP)
	@codesign -dv $(STORE_APP) 2>&1 | grep -q "TeamIdentifier=$(TEAM_ID)" \
		|| { echo "$(STORE_APP) is not signed by team $(TEAM_ID)" >&2; exit 1; }
	rm -f $(PKG)
	productbuild --component $(STORE_APP) /Applications --sign "$(INSTALLER_ID)" $(PKG)

# site publishes fuginaut.com and www.fuginaut.com from wrangler.jsonc.
site:
	wrangler deploy

clean:
	rm -rf .build
