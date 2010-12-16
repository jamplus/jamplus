# Makefile for jam

# Portions used from the Lua 5.1.4 makefile.

# Your platform. See PLATS for possible values.
PLAT = none

CC = gcc
CFLAGS =
EXENAME = ./jam0
LINKLIBS =
TARGET = -o $(EXENAME)

# Special flavors - uncomment appropriate lines

# NCR seems to have a broken readdir() -- use gnu
#CC = gcc

# AIX needs -lbsd, and has no identifying cpp symbol
# Use _AIX41 if you're not on 3.2 anymore.
#LINKLIBS = -lbsd
#CFLAGS = -D_AIX

# Interix - gcc
#CC = gcc

# Cygwin - gcc & cygwin
#CC = gcc
#CFLAGS = -D__cygwin__

# MingW32
#CC = gcc
#CFLAGS = -DMINGW

# MPEIX
#CC = gcc
#CFLAGS = -I/usr/include -D_POSIX_SOURCE

# QNX rtp (neutrino)
#CC = gcc

PLATS = linux32 macosx32 linux64 macosx64

default: $(PLAT)

none:
	@echo "Please choose a platform"
	@echo "    $(PLATS)"

linux32:
	$(MAKE) all CFLAGS="$(CFLAGS) -fexceptions -m32" LINKLIBS="$(LINKLIBS) -m32" PLATFORM=$@
linux64:
	$(MAKE) all CFLAGS="$(CFLAGS) -fexceptions -m64" LINKLIBS="$(LINKLIBS) -m64" PLATFORM=$@
macosx32:
	$(MAKE) all CFLAGS="$(CFLAGS) -fexceptions -m32" LINKLIBS="$(LINKLIBS) -m32 -framework CoreFoundation -framework CoreServices" PLATFORM=$@
macosx64:
	$(MAKE) all CFLAGS="$(CFLAGS) -fexceptions -m64" LINKLIBS="$(LINKLIBS) -m64 -framework CoreFoundation -framework CoreServices" PLATFORM=$@

.PHONY: all $(PLATS)

include Makefile.Common
