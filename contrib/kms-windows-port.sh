#!/bin/bash
# Editor hints for vi:
# vim: ts=4 sw=4
#
# Helper script to (re)build Windows port of KMS

set -e
#set -x

# use subdir named 'kms-windows-port/work' cwd as workdir if not set
if [ -z "$KMSWORKDIR" ]; then
	KMSWORKDIR="$(pwd)/kms-windows-port/work"
fi
mkdir -p "$KMSWORKDIR"

# use subdir named 'kms-windows-port/dist' cwd as distdir if not set
if [ -z "$KMSDISTDIR" ]; then
	KMSDISTDIR="$(pwd)/kms-windows-port/dist"
fi
mkdir -p "$KMSDISTDIR"

# use 3.8 as cmake version if not set
if [ -z "$CMAKEVERSION" ]; then
	CMAKEVERSION="3.8"
fi

# array of repo URL's and related tags
repos ()
{
    cat <<EOF
https://github.com/Kurento/kms-cmake-utils.git              HEAD
https://github.com/ESTOS/kurento-module-creator.git         HEAD
https://github.com/Kurento/gstreamer.git                    0d6031b200e189b391d9c0882760109c1d8cf837
https://github.com/Kurento/gst-plugins-base.git             7b19cfd259967a5c37280a3adf71106edde4e888
https://github.com/ESTOS/jsoncpp.git                        HEAD
https://github.com/ESTOS/kms-jsonrpc.git                    wip/premerge
https://github.com/webmproject/libvpx.git                   v1.5.0
https://github.com/ESTOS/kms-core.git                       HEAD
https://github.com/libevent/libevent.git                    a73fb2f443ebf9687ee6ca81a6401d1f3751683f
https://github.com/ESTOS/kurento-media-server.git           HEAD
https://github.com/ESTOS/usrsctp.git                        e5c5d352b624333e606288ccf323aad8e38c9039
https://github.com/ESTOS/openwebrtc-gst-plugins.git         079ccd07956a33c8c5bcca1c1a39cc19b8167370
https://github.com/ESTOS/libnice.git                        75ed7e4d12032cab8f5b6e550e641d728a61136a
https://github.com/ESTOS/kms-elements.git                   HEAD
https://github.com/itseez/opencv.git                        2.4.13.1
https://github.com/ESTOS/kms-filters.git                    HEAD
https://github.com/Kurento/gst-plugins-good.git             9ee4248dcae02f570b8ca6d092a56155fdc47976
https://github.com/cisco/libsrtp.git                        v1.5.4
https://github.com/Kurento/gst-plugins-bad.git              3db37b1965c00e820babfcd3e8ee7a257198ef56
https://github.com/Kurento/gst-libav.git                    493eee49c7171e7fc0bf0110e30d445ba573dc5e
https://github.com/Kurento/gst-plugins-ugly.git             2685b0f252bf0ed6aa27a5c69e82e05289346ff1
EOF
}

setup_workspace()
{
    local url tag rname ldir
	# split url, local dir, and tag
	repos | while read url tag; do
		#url=${i%\!*}
		#tag=${i#*\!}
		rname=${url##*/}
		ldir=${rname%.git}

		# checkout/update workspace
		mkdir -p "$KMSWORKDIR/$ldir"
		pushd "$KMSWORKDIR/$ldir"
		if [ -d .git ]; then
			if [ "$url" == "$(git remote get-url origin)" ]; then
				# workspace exists -> fetching latest data
				git fetch --all
			else
				# unknown/wrong workspace -> cleanup
				rm -rf ./.git ./*
			fi
		fi
		if [ ! -d .git ]; then
			git clone "$url" .
		fi
		git checkout "$tag"
		popd
	done
}

build_kms-cmake-utils()
{
	mkdir -p "$KMSWORKDIR/kms-cmake-utils-build"
	pushd "$KMSWORKDIR/kms-cmake-utils-build"
	mingw32-cmake ../kms-cmake-utils/
	mingw32-make
	sudo mingw32-make install
	popd
}

build_kurento-module-creator()
{
	mkdir -p "$KMSWORKDIR/kurento-module-creator"
	pushd "$KMSWORKDIR/kurento-module-creator"
	make
    sudo make install
    popd
}

build_gstreamer()
{
	pushd "$KMSWORKDIR/gstreamer"
	./autogen.sh || true ## Ignore configuration errors                                                                                                                                                                                      
    mingw32-configure --disable-tools --disable-tests --disable-benchmarks --disable-examples \
                      --disable-debug --libexec=/usr/i686-w64-mingw32/sys-root/mingw/libexec
    make
    sudo make install
    popd
}

build_gst-plugins-base()
{
	pushd "$KMSWORKDIR/gst-plugins-base"
	./autogen.sh || true ## Ignore configuration errors                                                                                                                                                                                      
    mingw32-configure --disable-debug
    mingw32-make
    sudo mingw32-make install
    popd
}

build_jsoncpp()
{
	mkdir -p "$KMSWORKDIR/jsoncpp-build"
	pushd "$KMSWORKDIR/jsoncpp-build"
	mingw32-cmake -DCMAKE_BUILD_TYPE=Release ../jsoncpp
	mingw32-make
	sudo mingw32-make install
	popd
}

build_kms-jsonrpc()
{
	mkdir -p "$KMSWORKDIR/kms-jsonrpc-build"
	pushd "$KMSWORKDIR/kms-jsonrpc-build"
	mingw32-cmake -DCMAKE_BUILD_TYPE=Release \
				  -DCMAKE_MODULE_PATH=/usr/i686-w64-mingw32/sys-root/mingw/share/cmake-$CMAKEVERSION/Modules/ \
				  ../kms-jsonrpc
	mingw32-make
	sudo mingw32-make install
	popd
}

build_libvpx()
{
	pushd "$KMSWORKDIR/libvpx"
	eval `rpm --eval %{mingw32_env}`
	export AS=yasm
	./configure --target=x86-win32-gcc --prefix=/usr/i686-w64-mingw32/sys-root/mingw/
	mingw32-make
	sudo mingw32-make install
	popd
}

build_kms-core()
{
	mkdir -p "$KMSWORKDIR/kms-core-build"
	pushd "$KMSWORKDIR/kms-core-build"
	mingw32-cmake -DCMAKE_BUILD_TYPE=Release \
				  -DCMAKE_MODULE_PATH=/usr/i686-w64-mingw32/sys-root/mingw/share/cmake-$CMAKEVERSION/Modules/ \
				  -DCMAKE_INSTALL_PREFIX=/usr/i686-w64-mingw32/sys-root/mingw \
				  -DKURENTO_MODULES_DIR=/usr/i686-w64-mingw32/sys-root/mingw/share/kurento/modules/ \
				  ../kms-core
	mingw32-make
	sudo mingw32-make install
	popd
}

build_libevent()
{
	pushd "$KMSWORKDIR/libevent"
	./autogen.sh || true ## However, you should not build using configured Makefile
	mingw32-configure
	mingw32-make
	sudo mingw32-make install
	popd
}

build_kurento-media-server()
{
	mkdir -p "$KMSWORKDIR/kurento-media-server-build"
	pushd "$KMSWORKDIR/kurento-media-server-build"
	mingw32-cmake -DCMAKE_BUILD_TYPE=Release \
				  -DCMAKE_MODULE_PATH=/usr/i686-w64-mingw32/sys-root/mingw/share/cmake-$CMAKEVERSION/Modules/ \
				  ../kurento-media-server
	mingw32-make
	sudo mingw32-make install
	popd
}

build_usrsctp()
{
	pushd "$KMSWORKDIR/usrsctp"
	./bootstrap
	mingw32-configure
	mingw32-make
	sudo mingw32-make install
	popd
}

build_openwebrtc-gst-plugins()
{
	pushd "$KMSWORKDIR/openwebrtc-gst-plugins"
	./autogen.sh || true ## Ignore configuration errors
	mingw32-configure
	mingw32-make
	sudo mingw32-make install
	sudo ln -s -f /usr/i686-w64-mingw32/sys-root/mingw/lib/libgstsctp-1.5.dll \
		 /usr/i686-w64-mingw32/sys-root/mingw/bin/libgstsctp-1.5.dll
	popd
}

build_libnice()
{
	pushd "$KMSWORKDIR/libnice"
	./autogen.sh || true ## Ignore configuration errors
	mingw32-configure
	mingw32-make
	sudo mingw32-make install
	popd
}

build_kms-elements()
{
	mkdir -p "$KMSWORKDIR/kms-elements-build"
	pushd "$KMSWORKDIR/kms-elements-build"
	mingw32-cmake -DCMAKE_BUILD_TYPE=Release \
				  -DCMAKE_MODULE_PATH=/usr/i686-w64-mingw32/sys-root/mingw/share/cmake-$CMAKEVERSION/Modules/ \
				  -DCMAKE_INSTALL_PREFIX=/usr/i686-w64-mingw32/sys-root/mingw \
				  -DKURENTO_MODULES_DIR=/usr/i686-w64-mingw32/sys-root/mingw/share/kurento/modules/ \
				  ../kms-elements
	mingw32-make
	sudo mingw32-make install
	popd
}

build_opencv()
{
	mkdir -p "$KMSWORKDIR/opencv-build"
	pushd "$KMSWORKDIR/opencv-build"
	mingw32-cmake \
		-DBUILD_PERF_TESTS=false \
		-DBUILD_TESTS=false \
		-DWITH_DSHOW=false \
		-DWITH_WIN32UI=false \
		-DWITH_OPENCL=false \
		-DWITH_VFW=false \
		-DBUILD_ZLIB=false \
		-DBUILD_TIFF=false \
		-DBUILD_JASPER=false \
		-DBUILD_JPEG=false \
		-DBUILD_PNG=false \
		-DBUILD_OPENEXR=false \
		-DWITH_FFMPEG=false \
		-DBUILD_opencv_flann=OFF \
		-DBUILD_opencv_photo=OFF \
		-DBUILD_opencv_video=OFF \
		-DBUILD_opencv_ml=OFF \
		../opencv
	sed -i 's/-isystem\ \/usr\/i686-w64-mingw32\/sys-root\/mingw\/include/ /g' \
		modules/core/CMakeFiles/opencv_core.dir/includes_CXX.rsp
	sed -i 's/-isystem\ \/usr\/i686-w64-mingw32\/sys-root\/mingw\/include\ / /g' \
		modules/highgui/CMakeFiles/opencv_highgui.dir/includes_CXX.rsp
	mingw32-make
	sudo mingw32-make install
	sudo cp unix-install/opencv.pc /usr/i686-w64-mingw32/sys-root/mingw/lib/pkgconfig/
	sudo ln -s -f /usr/i686-w64-mingw32/sys-root/mingw/x86/mingw/lib/libopencv_core2413.dll.a \
		 /usr/i686-w64-mingw32/sys-root/mingw/lib/libopencv_core.a
	sudo ln -s -f /usr/i686-w64-mingw32/sys-root/mingw/x86/mingw/lib/libopencv_highgui2413.dll.a \
		 /usr/i686-w64-mingw32/sys-root/mingw/lib/libopencv_highgui.a
	sudo ln -s -f /usr/i686-w64-mingw32/sys-root/mingw/x86/mingw/lib/libopencv_imgproc2413.dll.a \
		 /usr/i686-w64-mingw32/sys-root/mingw/lib/libopencv_imgproc.a
	sudo ln -s -f /usr/i686-w64-mingw32/sys-root/mingw/x86/mingw/lib/libopencv_objdetect2413.dll.a \
		 /usr/i686-w64-mingw32/sys-root/mingw/lib/libopencv_objdetect.a
	sudo ln -s -f /usr/i686-w64-mingw32/sys-root/mingw/x86/mingw/bin/libopencv_core2413.dll \
		 /usr/i686-w64-mingw32/sys-root/mingw/bin/libopencv_core2413.dll
	sudo ln -s -f /usr/i686-w64-mingw32/sys-root/mingw/x86/mingw/bin/libopencv_highgui2413.dll \
		 /usr/i686-w64-mingw32/sys-root/mingw/bin/libopencv_highgui2413.dll
	sudo ln -s -f /usr/i686-w64-mingw32/sys-root/mingw/x86/mingw/bin/libopencv_imgproc2413.dll \
		 /usr/i686-w64-mingw32/sys-root/mingw/bin/libopencv_imgproc2413.dll
	sudo ln -s -f /usr/i686-w64-mingw32/sys-root/mingw/x86/mingw/bin/libopencv_objdetect2413.dll \
		 /usr/i686-w64-mingw32/sys-root/mingw/bin/libopencv_objdetect2413.dll
	popd
}

build_kms-filters()
{
	mkdir -p "$KMSWORKDIR/kms-filters-build"
	pushd "$KMSWORKDIR/kms-filters-build"
	mingw32-cmake -DCMAKE_BUILD_TYPE=Release \
				  -DCMAKE_MODULE_PATH=/usr/i686-w64-mingw32/sys-root/mingw/share/cmake-$CMAKEVERSION/Modules/ \
				  -DCMAKE_INSTALL_PREFIX=/usr/i686-w64-mingw32/sys-root/mingw \
				  -DKURENTO_MODULES_DIR=/usr/i686-w64-mingw32/sys-root/mingw/share/kurento/modules/ \
				  -DCMAKE_C_FLAGS="-Wno-error=deprecated-declarations" \
				  ../kms-filters
	mingw32-make
	sudo mingw32-make install
	popd
}

build_gst-plugins-good()
{
	pushd "$KMSWORKDIR/gst-plugins-good"
	./autogen.sh || true ## Ignore configuration errors
	mingw32-configure \
		--disable-wavpack --disable-valgrind --disable-directsound \
		--disable-libcaca --disable-waveform \
		--libexec=/usr/i686-w64-mingw32/sys-root/mingw/libexec \
		--disable-debug --disable-gtk-doc --disable-examples
	printf "all:\ninstall:\nclean:\nuninstall:\n" > tests/Makefile
	mingw32-make
	sudo mingw32-make install
	popd
}

build_libsrtp()
{
	pushd "$KMSWORKDIR/libsrtp"
	mingw32-configure
	mingw32-make
	sudo mingw32-make install
	popd
}

build_gst-plugins-bad()
{
	pushd "$KMSWORKDIR/gst-plugins-bad"
	./autogen.sh || true ## Ignore configuration errors
	mingw32-configure \
		--disable-directsound --disable-direct3d --disable-debug \
		--disable-examples --disable-gtk-doc --disable-winscreencap \
		--disable-winks --disable-wasapi --disable-opencv
	sed -i 's/\buint\b/unsigned/g' ext/opencv/gstmotioncells.cpp ## We may need this later
	printf "all:\ninstall:\nclean:\nuninstall:\n" > tests/Makefile
	mingw32-make
	sudo mingw32-make install
	popd
}

build_gst-libav()
{
	pushd "$KMSWORKDIR/gst-libav"
	./autogen.sh || true ## Ignore configuration errors
    mingw32-configure
	mingw32-make
	sudo mingw32-make install
	popd
}

build_gst-plugins-ugly()
{
	pushd "$KMSWORKDIR/gst-plugins-ugly"
	./autogen.sh || true ## Ignore configuration errors
	mingw32-configure \
		--libexec=/usr/i686-w64-mingw32/sys-root/mingw/libexec \
		--enable-debug --disable-gtk-doc --disable-examples
	mingw32-make
	sudo mingw32-make install
	popd
}

build()
{
	build_kms-cmake-utils
	build_kurento-module-creator
	build_gstreamer
	build_gst-plugins-base
	build_jsoncpp
	build_kms-jsonrpc
	build_libvpx
	build_kms-core
	build_libevent
	build_kurento-media-server
	build_usrsctp
	build_openwebrtc-gst-plugins
	build_libnice
	build_kms-elements
	build_opencv
	build_kms-filters
	build_gst-plugins-good
	build_libsrtp
	build_gst-plugins-bad
	build_gst-libav
	build_gst-plugins-ugly
}

dist()
{
	mkdir -p "$KMSDISTDIR"
	pushd "$KMSDISTDIR"

	mkdir -p bin/
	mkdir -p lib/gstreamer-1.5/
	mkdir -p lib/kurento/modules/
	mkdir -p etc/kurento/modules/kurento/

	local PREF=/usr/i686-w64-mingw32/sys-root/mingw

	cp $PREF/bin/kurento-media-server.exe bin/kurento-media-server.exe
	cp $PREF/bin/libpcre-1.dll bin/
	cp $PREF/bin/iconv.dll bin/
	cp $PREF/bin/libatk-1.0-0.dll bin/
	cp $PREF/bin/libboost_filesystem-mt.dll bin/
	cp $PREF/bin/libboost_log-mt.dll bin/
	cp $PREF/bin/libboost_log_setup-mt.dll bin/
	cp $PREF/bin/libboost_program_options-mt.dll bin/
	cp $PREF/bin/libboost_regex-mt.dll bin/
	cp $PREF/bin/libboost_system-mt.dll bin/
	cp $PREF/bin/libboost_thread-mt.dll bin/
	cp $PREF/bin/libbz2-1.dll bin/
	cp $PREF/bin/libcairo-2.dll bin/
	cp $PREF/bin/libcairo-gobject-2.dll bin/
	cp $PREF/bin/libcrypto-10.dll bin/
	cp $PREF/bin/libepoxy-0.dll bin/
	cp $PREF/bin/libexpat-1.dll bin/
	cp $PREF/bin/libffi-6.dll bin/
	cp $PREF/bin/libfontconfig-1.dll bin/
	cp $PREF/bin/libfreetype-6.dll bin/
	cp $PREF/bin/libgcc_s_sjlj-1.dll bin/
	cp $PREF/bin/libgdk-3-0.dll bin/
	cp $PREF/bin/libgdk_pixbuf-2.0-0.dll bin/
	cp $PREF/bin/libgio-2.0-0.dll bin/
	cp $PREF/bin/libglib-2.0-0.dll bin/
	cp $PREF/bin/libglibmm-2.4-1.dll bin/
	cp $PREF/bin/libgmodule-2.0-0.dll bin/
	cp $PREF/bin/libgobject-2.0-0.dll bin/
	# cp $PREF/bin/libgsm-1.dll bin/
	cp $PREF/bin/libgstadaptivedemux-1.5-0.dll bin/
	cp $PREF/bin/libgstapp-1.5-0.dll bin/
	cp $PREF/bin/libgstaudio-1.5-0.dll bin/
	cp $PREF/bin/libgstbadaudio-1.5-0.dll bin/
	cp $PREF/bin/libgstbadbase-1.5-0.dll bin/
	cp $PREF/bin/libgstbadvideo-1.5-0.dll bin/
	cp $PREF/bin/libgstbase-1.5-0.dll bin/
	cp $PREF/bin/libgstbasecamerabinsrc-1.5-0.dll bin/
	cp $PREF/bin/libgstcodecparsers-1.5-0.dll bin/
	cp $PREF/bin/libgstfft-1.5-0.dll bin/
	cp $PREF/bin/libgstgl-1.5-0.dll bin/
	cp $PREF/bin/libgstmpegts-1.5-0.dll bin/
	cp $PREF/bin/libgstnet-1.5-0.dll bin/
	cp $PREF/bin/libgstpbutils-1.5-0.dll bin/
	cp $PREF/bin/libgstphotography-1.5-0.dll bin/
	cp $PREF/bin/libgstreamer-1.5-0.dll bin/
	cp $PREF/bin/libgstriff-1.5-0.dll bin/
	cp $PREF/bin/libgstrtp-1.5-0.dll bin/
	cp $PREF/bin/libgstrtsp-1.5-0.dll bin/
	cp $PREF/bin/libgstsctp-1.5.dll bin/
	cp $PREF/bin/libgstsdp-1.5-0.dll bin/
	cp $PREF/bin/libgsttag-1.5-0.dll bin/
	cp $PREF/bin/libgsturidownloader-1.5-0.dll bin/
	cp $PREF/bin/libgstvideo-1.5-0.dll bin/
	cp $PREF/bin/libgtk-3-0.dll bin/
	cp $PREF/bin/libHalf-12.dll bin/
	cp $PREF/bin/libIex-2_2-12.dll bin/
	cp $PREF/bin/libIlmImf-2_2-22.dll bin/
	cp $PREF/bin/libIlmThread-2_2-12.dll bin/
	cp $PREF/bin/libintl-8.dll bin/
	cp $PREF/bin/libjasper-1.dll bin/
	cp $PREF/bin/libjpeg-62.dll bin/
	cp $PREF/bin/libjsonrpc.dll bin/
	cp $PREF/bin/libkmscoreimpl.dll bin/
	cp $PREF/bin/libkmselementsimpl.dll bin/
	cp $PREF/bin/libkmsfiltersimpl.dll bin/
	cp $PREF/bin/libkmsgstcommons.dll bin/
	cp $PREF/bin/libkmsjsoncpp.dll bin/
	cp $PREF/bin/libkmsrtpsync.dll bin/
	cp $PREF/bin/libkmssdpagent.dll bin/
	cp $PREF/bin/libkmswebrtcendpointlib.dll bin/
	cp $PREF/bin/libnettle-6.dll bin/
	cp $PREF/bin/libnice-10.dll bin/
	cp $PREF/bin/libogg-0.dll bin/
	cp $PREF/bin/libopencv_core2413.dll bin/
	cp $PREF/bin/libopencv_highgui2413.dll bin/
	cp $PREF/bin/libopencv_imgproc2413.dll bin/
	cp $PREF/bin/libopencv_objdetect2413.dll bin/
	cp $PREF/bin/libopus-0.dll bin/
	cp $PREF/bin/liborc-0.4-0.dll bin/
	cp $PREF/bin/liborc-test-0.4-0.dll bin/
	cp $PREF/bin/libpango-1.0-0.dll bin/
	cp $PREF/bin/libpangocairo-1.0-0.dll bin/
	cp $PREF/bin/libpangowin32-1.0-0.dll bin/
	cp $PREF/bin/libpixman-1-0.dll bin/
	cp $PREF/bin/libpng16-16.dll bin/
	cp $PREF/bin/libsigc-2.0-0.dll bin/
	cp $PREF/bin/libsoup-2.4-1.dll bin/
	cp $PREF/bin/libspeex-1.dll bin/
	cp $PREF/bin/libsqlite3-0.dll bin/
	cp $PREF/bin/libssl-10.dll bin/
	cp $PREF/bin/libstdc++-6.dll bin/
	cp $PREF/bin/libtiff-5.dll bin/
	cp $PREF/bin/libvorbis-0.dll bin/
	cp $PREF/bin/libvorbisenc-2.dll bin/
	cp $PREF/bin/libwavpack-1.dll bin/
	cp $PREF/bin/libwebrtcdataproto.dll bin/
	cp $PREF/bin/libwinpthread-1.dll bin/
	cp $PREF/bin/libxml2-2.dll bin/
	cp $PREF/bin/zlib1.dll bin/
	cp $PREF/lib/gstreamer-1.5/libfacedetector.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libfaceoverlay.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaccurip.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstadder.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstadpcmdec.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstadpcmenc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaiff.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstalaw.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstalpha.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstalphacolor.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstapetag.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstapp.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstasf.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstasfmux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaudioconvert.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaudiofx.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaudiofxbad.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaudiomixer.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaudioparsers.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaudiorate.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaudioresample.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaudiotestsrc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstaudiovisualizers.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstauparse.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstautoconvert.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstautodetect.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstavi.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstbayer.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstbz2.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstcairo.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstcamerabin2.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstcoloreffects.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstcompositor.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstcoreelements.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstcoretracers.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstcutter.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstd3dvideosink.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstdashdemux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstdataurisrc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstdebug.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstdebugutilsbad.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstdeinterlace.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstdirectsoundsink.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstdirectsoundsrc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstdtls.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstdtmf.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstdvbsuboverlay.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstdvdlpcmdec.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstdvdspu.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstdvdsub.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgsteffectv.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstencodebin.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstequalizer.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstfestival.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstfieldanalysis.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstflv.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstflxdec.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstfreeverb.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstfrei0r.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstgaudieffects.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstgdkpixbuf.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstgdp.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstgeometrictransform.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstgio.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstgoom.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstgoom2k1.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstgsm.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstgtksink.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgsthls.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgsticydemux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstid3demux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstid3tag.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstimagefreeze.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstinter.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstinterlace.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstinterleave.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstisomp4.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstivfparse.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstivtc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstjp2kdecimator.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstjpeg.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstjpegformat.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstlevel.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmatroska.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmidi.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmpegpsdemux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmpegpsmux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmpegtsdemux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmpegtsmux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmulaw.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmultifile.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmultipart.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstmxf.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstnavigationtest.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstnetsim.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstnice15.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstogg.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstopenexr.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstopengl.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstopus.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstopusparse.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstpango.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstpcapparse.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstplayback.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstpng.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstpnm.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstrawparse.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstremovesilence.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstreplaygain.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstrfbsrc.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstrmdemux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstrtp.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstrtpmanager.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstrtponvif.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstrtsp.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsdpelem.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsegmentclip.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstshapewipe.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsiren.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsmooth.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsmoothstreaming.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsmpte.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsouphttpsrc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstspectrum.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstspeed.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstspeex.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsrtp.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgststereo.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsubenc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstsubparse.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgsttcp.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgsttypefindfunctions.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstudp.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideobox.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideoconvert.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideocrop.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideofilter.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideofiltersbad.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideoframe_audiolevel.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideomixer.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideoparsersbad.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideorate.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideorepair.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideoscale.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideosignal.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvideotestsrc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvmnc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvolume.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstvorbis.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstwasapi.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstwaveformsink.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstwavenc.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstwavpack.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstwavparse.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstwinscreencap.dll lib/gstreamer-1.5/
	# cp $PREF/lib/gstreamer-1.5/libgstxingmux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgsty4mdec.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgsty4menc.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libgstyadif.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libimageoverlay.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libkmscoreplugins.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libkmselementsplugins.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/liblogooverlay.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libmovementdetector.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libopencvfilter.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/librecorderendpoint.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/librtcpdemux.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/librtpendpoint.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libvp8parse.dll lib/gstreamer-1.5/
	cp $PREF/lib/gstreamer-1.5/libwebrtcendpoint.dll lib/gstreamer-1.5/
	cp $PREF/lib/kurento/modules/libkmscoremodule.dll lib/kurento/modules/
	cp $PREF/lib/kurento/modules/libkmselementsmodule.dll lib/kurento/modules/
	cp $PREF/lib/kurento/modules/libkmsfiltersmodule.dll lib/kurento/modules/
	cp $PREF/etc/kurento/kurento.conf.json etc/kurento/
	sed -i 's/\/\/.*//' etc/kurento/kurento.conf.json
	cp $PREF/etc/kurento/modules/kurento/*.* etc/kurento/modules/kurento/
	sed -i 's/\/\/.*//' etc/kurento/modules/kurento/SdpEndpoint.conf.json
	# cp $PREF/bin/libkmschromaimpl.dll ../kms-windows-git/bin/
	# cp $PREF/lib/gstreamer-1.5/libchroma.dll ../kms-windows-git/lib/gstreamer-1.5/
	# cp $PREF/lib/kurento/modules/libkmschromamodule.dll ../kms-windows-git/lib/kurento/modules/

	popd
}

case "$1" in
	setup)
		setup_workspace
		;;
	build)
		build
		;;
	build_*)
		$1
		;;
	dist)
		dist
		;;
	all)
		setup_workspace
		build
		dist
		;;
	*)
		echo ""
		echo "Usage:"
		echo " kms-windows-port.sh setup       setup workspace (pull/update all git repos)"
		echo " kms-windows-port.sh build       build all components"
		echo " kms-windows-port.sh build_COMP  build component COMP only (e.g. gst-plugins-base)"
		echo " kms-windows-port.sh dist        create dist directory"
		echo ""
		echo " kms-windows-port.sh all         setup, build, and dist"
		echo ""
		echo "Environment:"
		echo " KMSWORKDIR       local working directory (defaults to 'cwd'/kms-windows-port/work)"
		echo " KMSDISTDIR       dist directory (defaults to 'cwd'/kms-windows-port/dist)"
		echo " CMAKEVERSION     cmake version (default: 3.9)"
		echo ""
		;;
esac

# Editor hints for emacs:
#
# Local Variables:
# indent-tabs-mode:t
# tab-width:4
# End:
# 
# NO CODE BELOW THIS!
