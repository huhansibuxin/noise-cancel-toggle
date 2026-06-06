TARGET := iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoiseCancelToggle
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
NoiseCancelToggle_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += NoiseCancelToggleApp
include $(THEOS_MAKE_PATH)/aggregate.mk

before-package::
	@mkdir -p $(THEOS_STAGING_DIR)/var/jb/Applications
	rm -rf $(THEOS_STAGING_DIR)/var/jb/Applications/NoiseCancelToggle.app
	cp -a NoiseCancelToggleApp/_output/NoiseCancelToggle.app $(THEOS_STAGING_DIR)/var/jb/Applications/
	cp NoiseCancelToggleApp/Info.plist $(THEOS_STAGING_DIR)/var/jb/Applications/NoiseCancelToggle.app/
	cp NoiseCancelToggleApp/PkgInfo $(THEOS_STAGING_DIR)/var/jb/Applications/NoiseCancelToggle.app/
	@echo "App bundled into package"