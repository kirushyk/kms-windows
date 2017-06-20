**UNDER CONSTRUCTION, NOT FINISHED**

# KMS for Windows cross-compilation on Fedora 25

This document describes how to prepare environment and how to build Kurento
Media Server for Windows using MinGW cross-compiler on Fedora 25.

## Install dependencies provided by package manager.

    sudo dnf install autoconf automake mingw32-filesystem cmake mingw32-gcc-c++ maven \
      mingw32-boost gettext-devel bison flex mingw32-glib2 mingw32-orc mingw32-libtheora \
      mingw32-libvorbis mingw32-opus mingw32-libsigc++20 mingw32-glibmm24 yasm mingw32-openssl \
      mingw32-libtiff mingw32-libpng mingw32-OpenEXR mingw32-jasper libtool glib2-devel gtk-doc \
      mingw32-atk mingw32-cairo mingw32-gtk3 mingw32-speex mingw32-wavpack mingw32-libsoup
  
## Optionally, if you would like to change source codes of KMS on that machine and put changes back to repo, you should install this packages as well:

    sudo dnf install indent astyle
	
## Helper script for setup, build, and distro creation

In subdirectory **contrib** a script called **kms-windows-port.sh** can be found.

### Setup workspace

To setup or update your local workspace call

    kms-windows-port.sh setup

This will fetch all needed repositories into the directory specified with the
environment variable **KMSWORKDIR** which default to **'cwd'/kms-windows-port/work**.

### Building

To build one component call

    kms-windows-port.sh build_COMP

where COMP represents one of the components (e.g. gst-plugins-base).

**Hint:** You need to keep attention on component dependencies for yourself!

To build all components call

    kms-windows-port.sh build

### Assemble distribution directory

To assemble a distribution directory call

    kms-windows-port.sh dist

This will create the target directory tree inside the directory specified
with the environment variable **KMSDISTDIR** which defaults to **'cwd'/kms-windows-port/dist**.

### Do it all

To run all the three needed steps (setup, build, dist) together just call

    kms-windows-port.sh all

### Environment

* **KMSWORKDIR** - local working directory (defaults to 'cwd'/kms-windows-port/work)
* **KMSDISTDIR** - dist directory (defaults to 'cwd'/kms-windows-port/dist)
* **CMAKEVERSION** - cmake version (default: 3.9)
