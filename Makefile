OS:=$(shell uname)

ifdef SystemRoot
	SYSTEM=Windows
else ifdef SYSTEMROOT
	SYSTEM=Windows
else
	SYSTEM=Other
endif

ifeq ($(SYSTEM), Windows)
	EXE=.exe
	PLATFORM_DEFINES=-DSYSTEM_WIN32 -D_CONSOLE
	PLATFORM_FLAGS=
	RM=cmd /c del /F
	RMR=cmd /c rd /S/Q
	MKDIR=cmd /c md
	CP=cmd /c copy /B
	PATHSEP2=\\
	PATHSEP=$(strip $(PATHSEP2))
	CMDSEP=&
else
	EXE=
	PLATFORM_DEFINES=-DSYSTEM_POSIX -DHAVE_SYS_TIME_H -DHAVE_UNISTD_H -DHAVE_SYS_STAT_H -DHAVE_FCNTL_H -DHAVE_SYS_RESOURCE_H -D_strdup=strdup -D_strlwr=strlwr -D_strupr=strupr -Dstricmp=strcasecmp -D_unlink=unlink -D_open=open -D_read=read -D_close=close
	PLATFORM_FLAGS=-pthread
	RM=rm -f
	RMR=rm -rf
	MKDIR=mkdir -p
	CP=cp
	PATHSEP2=/
	PATHSEP=$(strip $(PATHSEP2))
	CMDSEP=;
endif

CC=gcc
CFLAGS=-Wall -I./src
LDFLAGS=

# Link math library on Linux
ifeq ($(OS),Linux)
	CFLAGS+=-lm
endif

ifeq ($(ARCH),-m32)
	CHECKPLATFORM?=unix32
	ARCHPATH?=i386
else ifeq ($(ARCH),-m64)
	CHECKPLATFORM?=unix64
	ARCHPATH?=x86_64
endif

CPPCHECK?=cppcheck
CPPCHECKFLAGS= --enable=warning --enable=portability --platform=$(CHECKPLATFORM) --language=c++ -I common --force --quiet

# Darwin specific (macOS)
ifeq ($(OS),Darwin)
	OSX_VERSION := $(shell sw_vers -productVersion)
	DEVELOPER_DIR := $(shell /usr/bin/xcode-select -print-path)
	SDK_DIR := $(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/SDKs
	SDKROOT ?= $(SDK_DIR)/MacOSX10.12.sdk

	CFLAGS += -Qunused-arguments -isysroot $(SDKROOT) -mmacosx-version-min=10.9
endif

INSTALL_PATH?=/usr/local/bin

BUILD_DIR=build$(PATHSEP)build-$(ARCHPATH)
BIN_DIR=build$(PATHSEP)bin-$(ARCHPATH)

SRCS = src/bmpread.c \
       src/cmdlib.c \
       src/mathlib.c \
       src/scriplib.c \
       src/studiomdl.c \
       src/trilib.c \
       src/tristrip.c \
       src/write.c

OBJS = $(SRCS:.c=.o)
TARGET = studiomdl

all : $(TARGET)

$(BUILD_DIR):
	-$(MKDIR) $@
$(BIN_DIR):
	-$(MKDIR) -p $@

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET) $(LDFLAGS)

checkstudiomdl: studiomdl.log

studiomdl.log: $(COMMON_SOURCES) $(addprefix studiomdl$(PATHSEP), $(SRCS))
	$(CPPCHECK) $(COMMON_DEFINES) $(STUDIOMDL_DEFINES) $(CPPCHECKFLAGS) studiomdl 2>$@

$(BUILD_DIR)/%.o : src/%.c
	$(CC) -c $(CFLAGS) $(COMMON_DEFINES) $(STUDIOMDL_DEFINES) $(INCLUDE_DIRS) $< -o $@

clean:
	-$(RMR) $(foreach target,$(TARGET),$(BUILD_DIR)$(PATHSEP)$(target) )

distclean: clean
	-$(RMR) $(foreach target,$(TARGET),$(BIN_DIR)$(PATHSEP)$(target)$(EXE))

install:
	-$(CP) $(BIN_DIR)$(PATHSEP)$(TARGET)$(EXE) $(INSTALL_PATH)$(PATHSEP)$(TARGET)

uninstall:
	-$(RM) $(INSTALL_PATH)$(PATHSEP)$(TARGET)

check: checkstudiomdl

.PHONY: clean
