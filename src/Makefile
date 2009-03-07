# Makefile for jam

# Portions used from the Lua 5.1.4 makefile.

# Your platform. See PLATS for possible values.
PLAT = none

CC = gcc
CFLAGS =
EXENAME = ./jam0
LINKLIBS = -lstdc++
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

PLATS = macosx

default: $(PLAT)

none:
	@echo "Please choose a platform"
	@echo "    $(PLATS)"

macosx:
	$(MAKE) all CFLAGS="$(CFLAGS) -fexceptions" LINKLIBS="$(LINKLIBS) -framework CoreFoundation"

include Makefile.Common
