TARGET := iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoiseCancelToggle
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = BluetoothManager

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += NoiseCancelToggleApp
include $(THEOS_MAKE_PATH)/aggregate.mk

before-package::
	@mkdir -p $(THEOS_STAGING_DIR)/var/jb/Applications/NoiseCancelToggle.app
	cp -r NoiseCancelToggleApp/_output/* $(THEOS_STAGING_DIR)/var/jb/Applications/NoiseCancelToggle.app/
	@echo "App bundled into package"