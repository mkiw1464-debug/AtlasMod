ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = FreeFire

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AtlasMod

# All source files
AtlasMod_FILES = \
    src/main.m \
    src/kernel_exploit.c \
    src/hypervisor_spoof.c \
    src/sep_spoof.c \
    src/dyld_poison.c \
    src/code_mutation.c \
    src/kill_acdaemon.c \
    src/syscall_hook.c \
    src/mem_encrypt.c \
    src/network_spoof.c \
    src/bypass_engine.c \
    src/offsets.c \
    src/aimbot.c \
    src/esp.c \
    src/menu.m \
    src/utils.c \
    KittyMemory/KittyMemory.cpp

# Compiler flags
AtlasMod_CFLAGS = -fobjc-arc -I./include -O3 -march=armv8.3-a -mtune=apple-a12 -flto -ffast-math -funroll-loops -fomit-frame-pointer -Wall -Wextra -Wno-unused-parameter

# Linker flags
AtlasMod_LDFLAGS = -lobjc -lc++ -framework UIKit -framework CoreGraphics -framework QuartzCore -framework Metal -framework OpenGLES -framework Foundation -framework CoreTelephony -framework SystemConfiguration -framework Security -framework CommonCrypto

# Strip to reduce size
AtlasMod_STRIP = 1

include $(THEOS_MAKE_PATH)/tweak.mk
