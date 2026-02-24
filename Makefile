PREFIX ?= /Applications
APP = Hyperkey.app

.PHONY: build install uninstall clean

build:
	swift build -c release

install: build
	@mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	@cp .build/release/hyperkey $(APP)/Contents/MacOS/
	@cp Info.plist $(APP)/Contents/
	@cp AppIcon.icns $(APP)/Contents/Resources/
	@codesign -f -s - --identifier com.feedthejim.hyperkey $(APP)
	@mkdir -p "$(PREFIX)"
	@rm -rf "$(PREFIX)/$(APP)"
	@cp -R $(APP) "$(PREFIX)/$(APP)"
	@rm -rf $(APP)
	@echo "Installed to $(PREFIX)/$(APP)"
	@echo "Grant Accessibility permission to Hyperkey in System Settings if prompted."

uninstall:
	@"$(PREFIX)/$(APP)/Contents/MacOS/hyperkey" --uninstall 2>/dev/null || true
	@rm -rf "$(PREFIX)/$(APP)"
	@echo "Uninstalled."

clean:
	swift package clean
	@rm -rf $(APP)
