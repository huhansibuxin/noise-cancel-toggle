TARGET := iphone:clang:latest:16.0
ARCHS = arm64e

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NoiseCancelToggle
$(APPLICATION_NAME)_FILES = main.m AppDelegate.m
$(APPLICATION_NAME)_CFLAGS = -fobjc-arc
$(APPLICATION_NAME)_LDFLAGS = -undefined dynamic_lookup
$(APPLICATION_NAME)_INSTALL_PATH = /var/jb/Applications

include $(THEOS_MAKE_PATH)/application.mk

after-all::
	@mkdir -p _output
	cp -r $(THEOS_OBJ_DIR)/NoiseCancelToggle.app/* _output/
	cp icon.png _output/AppIcon60x60@2x.png 2>/dev/null || true
	@echo "App built to _output/"