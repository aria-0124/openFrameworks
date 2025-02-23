#! /bin/bash
#
# Poco
# C++ with Batteries Included
# http://pocoproject.org/
#
# uses an autotools build system,
# specify specfic build configs in poco/config using ./configure --config=NAME

# define the version
VER=1.6.0-release

# tools for git use
GIT_URL=https://github.com/pocoproject/poco
GIT_TAG=poco-1.6.0-release

# For Poco Builds, we omit both Data/MySQL and Data/ODBC because they require
# 3rd Party libraries.  See https://github.com/pocoproject/poco/blob/develop/README
# for more information.

SHA=

# download the source code and unpack it into LIB_NAME
function download() {
	if [ "$SHA" == "" ] ; then
		echo "SHA=="" $GIT_URL"
		curl -Lk $GIT_URL/archive/$GIT_TAG.tar.gz -o poco-$GIT_TAG.tar.gz
		tar -xf poco-$GIT_TAG.tar.gz
		mv poco-$GIT_TAG poco
		rm poco*.tar.gz
	else
		echo $GIT_URL
		git clone $GIT_URL -b poco-$VER
	fi
}

# prepare the build environment, executed inside the lib src dir
function prepare() {

	if [ "$SHA" != "" ] ; then
		git reset --hard $SHA
	fi

	# make backups of the ios config files since we need to edit them
	if [ "$TYPE" == "ios" ] ; then
		mkdir -p lib/$TYPE
		mkdir -p lib/iPhoneOS

		cd build/config

		cp iPhoneSimulator-clang-libc++ iPhoneSimulator-clang-libc++.orig
		cp iPhone-clang-libc++ iPhone-clang-libc++.orig

		# fix using sed i636 reference and allow overloading variable
		sed -i .tmp "s|POCO_TARGET_OSARCH.* = .*|POCO_TARGET_OSARCH ?= i386|" iPhoneSimulator-clang-libc++
		sed -i .tmp "s|OSFLAGS            = -arch|OSFLAGS            ?= -arch|" iPhoneSimulator-clang-libc++
		sed -i .tmp "s|STATICOPT_CC    =|STATICOPT_CC    ?= -DNDEBUG -DPOCO_ENABLE_CPP11 -Os -fPIC|" iPhone-clang-libc++
		sed -i .tmp "s|STATICOPT_CXX   =|STATICOPT_CXX   ?= -DNDEBUG -DPOCO_ENABLE_CPP11 -Os -fPIC|" iPhone-clang-libc++
		sed -i .tmp "s|OSFLAGS                 = -arch|OSFLAGS                ?= -arch|" iPhone-clang-libc++
		sed -i .tmp "s|RELEASEOPT_CC   = -DNDEBUG -O2|RELEASEOPT_CC   =  -DNDEBUG -DPOCO_ENABLE_CPP11 -Os -fPIC|" iPhone-clang-libc++
		sed -i .tmp "s|RELEASEOPT_CXX  = -DNDEBUG -O |RELEASEOPT_CXX  =  -DNDEBUG -DPOCO_ENABLE_CPP11 -Os -fPIC|" iPhone-clang-libc++

		cd ../rules/
		cp compile compile.orig
		# Fix for making debug and release, making just release
		sed -i .tmp "s|all_static: static_debug static_release|all_static: static_release|" compile
		cd ../../

	elif [ "$TYPE" == "vs" ] ; then
		# Patch the components to exclude those that we aren't using.
		if patch -p0 -u -N --dry-run --silent < $FORMULA_DIR/components.patch 2>/dev/null ; then
			patch -p0 -u < $FORMULA_DIR/components.patch
		fi

		# Locate the path of the openssl libs distributed with openFrameworks.
		local OF_LIBS_OPENSSL="$LIBS_DIR/openssl/"

		# get the absolute path to the included openssl libs
		local OF_LIBS_OPENSSL_ABS_PATH=$(cd $(dirname $OF_LIBS_OPENSSL); pwd)/$(basename $OF_LIBS_OPENSSL)

		# convert the absolute path from unix to windows
		local OPENSSL_DIR=$(echo $OF_LIBS_OPENSSL_ABS_PATH | sed 's/^\///' | sed 's/\//\\/g' | sed 's/^./\0:/')

		# escape windows slashes and a few common escape sequences before passing to sed
		local OPENSSL_DIR=$(echo $OPENSSL_DIR | sed 's/\\/\\\\\\/g' | sed 's/\\\U/\\\\U/g' | sed 's/\\\l/\\\\l/g')

		# replace OPENSSL_DIR=C:\OpenSSL with our OPENSSL_DIR
		sed -i.tmp "s|C:\\\OpenSSL|$OPENSSL_DIR|g" buildwin.cmd

		# replace OPENSSL_LIB=%OPENSSL_DIR%\lib;%OPENSSL_DIR%\lib\VC with OPENSSL_LIB=%OPENSSL_DIR%\lib\vs
		sed -i.tmp "s|%OPENSSL_DIR%\\\lib;.*|%OPENSSL_DIR%\\\lib\\\vs|g" buildwin.cmd
	fi

}

# executed inside the lib src dir
function build() {

	if [ "$TYPE" == "osx" ] ; then
		local BUILD_OPTS="--no-tests --no-samples --static --omit=CppUnit,CppUnit/WinTestRunner,Data/MySQL,Data/ODBC,PageCompiler,PageCompiler/File2Page,CppParser,PDF,PocoDoc,ProGen"

		CURRENTPATH=`pwd`
		mkdir -p "$CURRENTPATH/build/$TYPE/LOG"
		LOG="$CURRENTPATH/build/$TYPE/poco-configure-i386-${VER}.log"
		set +e

		echo "--------------------"
		echo "Making Poco-${VER}"
		echo "--------------------"
		echo "Configuring for i386 libstdc++ ..."

		# 32 bit
		# For OS 10.9+ we must explicitly set libstdc++ for the 32-bit OSX build.
		./configure $BUILD_OPTS --cflags=-stdlib=libstdc++ --config=Darwin32 > "${LOG}" 2>&1
		if [ $? != 0 ];
		then
			tail -n 100 "${LOG}"
	    	echo "Problem while configuring - Please check ${LOG}"
	    	exit 1
	    else
	    	tail -n 100 "${LOG}"
	    	echo "Configure Successful"
	    fi
	    echo "--------------------"
		echo "Running make"
		LOG="$CURRENTPATH/build/$TYPE/poco-make-i386-${VER}.log"
		make >> "${LOG}" 2>&1
		if [ $? != 0 ];
		then
			tail -n 100 "${LOG}"
	    	echo "Problem while make - Please check ${LOG}"
	    	exit 1
	    else
	    	tail -n 100 "${LOG}"
	    	echo "Make Successful"
	    fi

		# 64 bit
		export POCO_ENABLE_CPP11=1
		LOG="$CURRENTPATH/build/$TYPE/poco-configure-x86_64-${VER}.log"
		./configure $BUILD_OPTS --config=Darwin64-clang-libc++  > "${LOG}" 2>&1
		if [ $? != 0 ];
		then
			tail -n 100 "${LOG}"
	    	echo "Problem while configuring - Please check ${LOG}"
	    	exit 1
	    else
	    	tail -n 100 "${LOG}"
	    	echo "Configure Successful"
	    fi
	    echo "--------------------"
		echo "Running make"
		LOG="$CURRENTPATH/build/$TYPE/poco-make-x86_64-${VER}.log"
		make >> "${LOG}" 2>&1
		if [ $? != 0 ];
		then
			tail -n 100 "${LOG}"
	    	echo "Problem while make - Please check ${LOG}"
	    	exit 1
	    else
	    	tail -n 100 "${LOG}"
	    	echo "Make Successful"
	    fi

		unset POCO_ENABLE_CPP11

		cd lib/Darwin

		# delete debug builds
		rm i386/*d.a
		rm x86_64/*d.a

		# link into universal lib, strip "lib" from filename
		local lib
		for lib in $( ls -1 i386) ; do
			local renamedLib=$(echo $lib | sed 's|lib||')
			if [ ! -e $renamedLib ] ; then
				lipo -c i386/$lib x86_64/$lib -o $renamedLib
			fi
		done

	elif [ "$TYPE" == "vs" ] ; then
		cmd //c buildwin.cmd ${VS_VER}0 build static_md both Win32 nosamples notests

	elif [ "$TYPE" == "win_cb" ] ; then
		local BUILD_OPTS="--no-tests --no-samples --static --omit=CppUnit,CppUnit/WinTestRunner,Data/MySQL,Data/ODBC,PageCompiler,PageCompiler/File2Page,CppParser,PDF,PocoDoc,ProGen"

		# Locate the path of the openssl libs distributed with openFrameworks.
		local OF_LIBS_OPENSSL="$LIBS_DIR/openssl/"

		# get the absolute path to the included openssl libs
		local OF_LIBS_OPENSSL_ABS_PATH=$(cd $(dirname $OF_LIBS_OPENSSL); pwd)/$(basename $OF_LIBS_OPENSSL)

		local OPENSSL_INCLUDE=$OF_LIBS_OPENSSL_ABS_PATH/include
		local OPENSSL_LIBS=$OF_LIBS_OPENSSL_ABS_PATH/lib/win_cb

		./configure $BUILD_OPTS \
					--include-path=$OPENSSL_INCLUDE \
					--library-path=$OPENSSL_LIBS \
					--config=MinGW

		make

		# Delete debug libs.
		lib/MinGW/i686/*d.a

	elif [ "$TYPE" == "ios" ] ; then


		SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`
		set -e
		CURRENTPATH=`pwd`

		DEVELOPER=$XCODE_DEV_ROOT
		TOOLCHAIN=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain
		VERSION=$VER

		local IOS_ARCHS="i386 x86_64 armv7 arm64"
		echo "--------------------"
		echo $CURRENTPATH

		# Validate environment
		case $XCODE_DEV_ROOT in
		     *\ * )
		           echo "Your Xcode path contains whitespaces, which is not supported."
		           exit 1
		          ;;
		esac
		case $CURRENTPATH in
		     *\ * )
		           echo "Your path contains whitespaces, which is not supported by 'make install'."
		           exit 1
		          ;;
		esac

		echo "------------"
		# To Fix: global:62: *** Current working directory not under $PROJECT_BASE.  Stop. make
		echo "Note: For Poco, make sure to call it with lowercase poco name: ./apothecary -t ios update poco"
		echo "----------"

		local BUILD_POCO_CONFIG_IPHONE=iPhone-clang-libc++
		local BUILD_POCO_CONFIG_SIMULATOR=iPhoneSimulator-clang-libc++

		# Locate the path of the openssl libs distributed with openFrameworks.
		local OF_LIBS_OPENSSL="$LIBS_DIR/openssl/"

		# get the absolute path to the included openssl libs
		local OF_LIBS_OPENSSL_ABS_PATH=$(cd $(dirname $OF_LIBS_OPENSSL); pwd)/$(basename $OF_LIBS_OPENSSL)

		local OPENSSL_INCLUDE=$OF_LIBS_OPENSSL_ABS_PATH/include
		local OPENSSL_LIBS=$OF_LIBS_OPENSSL_ABS_PATH/lib/ios

		local BUILD_OPTS="--no-tests --no-samples --static --omit=CppUnit,CppUnit/WinTestRunner,Data/MySQL,Data/ODBC,PageCompiler,PageCompiler/File2Page,CppParser,PDF,PocoDoc,ProGen --include-path=$OPENSSL_INCLUDE --library-path=$OPENSSL_LIBS"

		STATICOPT_CC=-fPIC
		STATICOPT_CXX=-fPIC

		# loop through architectures! yay for loops!
		for IOS_ARCH in ${IOS_ARCHS}
		do
			MIN_IOS_VERSION=$IOS_MIN_SDK_VER
		    # min iOS version for arm64 is iOS 7

		    if [[ "${IOS_ARCH}" == "arm64" || "${IOS_ARCH}" == "x86_64" ]]; then
		    	MIN_IOS_VERSION=7.0 # 7.0 as this is the minimum for these architectures
		    elif [ "${IOS_ARCH}" == "i386" ]; then
		    	MIN_IOS_VERSION=5.1 # 6.0 to prevent start linking errors
		    fi
		    export IPHONE_SDK_VERSION_MIN=$IOS_MIN_SDK_VER

			export POCO_TARGET_OSARCH=$IOS_ARCH

			MIN_TYPE=-miphoneos-version-min=
			if [[ "${IOS_ARCH}" == "i386" || "${IOS_ARCH}" == "x86_64" ]];
			then
				PLATFORM="iPhoneSimulator"
				BUILD_POCO_CONFIG=$BUILD_POCO_CONFIG_SIMULATOR
				MIN_TYPE=-mios-simulator-version-min=
			else
				PLATFORM="iPhoneOS"
				BUILD_POCO_CONFIG=$BUILD_POCO_CONFIG_SIMULATOR
			fi

			export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
			export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
			export BUILD_TOOLS="${DEVELOPER}"

			mkdir -p "$CURRENTPATH/build/$TYPE/$IOS_ARCH"
			LOG="$CURRENTPATH/build/$TYPE/$IOS_ARCH/poco-$IOS_ARCH-${VER}.log"
			set +e

			if [[ "${IOS_ARCH}" == "i386" || "${IOS_ARCH}" == "x86_64" ]];
			then
				export OSFLAGS="-arch $POCO_TARGET_OSARCH -fPIC -DPOCO_ENABLE_CPP11 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} $MIN_TYPE$IPHONE_SDK_VERSION_MIN"
			else
				export OSFLAGS="-arch $POCO_TARGET_OSARCH -fPIC -DPOCO_ENABLE_CPP11 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} $MIN_TYPE$IPHONE_SDK_VERSION_MIN"
			fi
			echo "--------------------"
			echo "Making Poco-${VER} for ${PLATFORM} ${SDKVERSION} ${IOS_ARCH} : iOS Minimum=$MIN_IOS_VERSION"
			echo "--------------------"
			echo "Configuring for ${IOS_ARCH} ..."
			./configure $BUILD_OPTS --config=$BUILD_POCO_CONFIG_IPHONE > "${LOG}" 2>&1

			if [ $? != 0 ]; then
				tail -n 100 "${LOG}"
		    	echo "Problem while configure - Please check ${LOG}"
		    	exit 1
		    else
		    	echo "Configure successful"
		    fi
		    echo "--------------------"
		    echo "Running make for ${IOS_ARCH}"
			make >> "${LOG}" 2>&1
			if [ $? != 0 ];
		    then
		    	tail -n 100 "${LOG}"
		    	echo "Problem while make - Please check ${LOG}"
		    	exit 1
		    else
		    	tail -n 10 "${LOG}"
		    	echo "Make Successful for ${IOS_ARCH}"
		    fi
			unset POCO_TARGET_OSARCH IPHONE_SDK_VERSION_MIN OSFLAGS
			unset CROSS_TOP CROSS_SDK BUILD_TOOLS

			echo "--------------------"

		done

		cd lib/iPhoneOS
		# link into universal lib, strip "lib" from filename
		local lib
		for lib in $( ls -1 i386) ; do
			local renamedLib=$(echo $lib | sed 's|lib||')
			if [ ! -e $renamedLib ] ; then
				lipo -c armv7/$lib arm64/$lib i386/$lib x86_64/$lib -o ../ios/$renamedLib
			fi
		done

		cd ../../

		echo "--------------------"
		echo "Stripping any lingering symbols"

		cd lib/$TYPE
		SLOG="$CURRENTPATH/lib/$TYPE-stripping.log"
		local TOBESTRIPPED
		for TOBESTRIPPED in $( ls -1) ; do
			strip -x $TOBESTRIPPED >> "${SLOG}" 2>&1
			if [ $? != 0 ];
		    then
		    	tail -n 100 "${SLOG}"
		    	echo "Problem while stripping lib - Please check ${SLOG}"
		    	exit 1
		    else
		    	echo "Strip Successful for ${SLOG}"
		    fi
		done

		cd ../../

		echo "--------------------"
		echo "Reseting changed files back to originals"
		cd build/config
		cp iPhoneSimulator-clang-libc++.orig iPhoneSimulator-clang-libc++
		cp iPhone-clang-libc++.orig iPhone-clang-libc++
		cd ../rules/
		cp compile.orig compile
		cd ../../
		echo "--------------------"

		echo "Completed."

	elif [ "$TYPE" == "android" ] ; then
		local BUILD_OPTS="--no-tests --no-samples --static --omit=CppUnit,CppUnit/WinTestRunner,Data/MySQL,Data/ODBC,PageCompiler,PageCompiler/File2Page,CppParser,PDF,PocoDoc,ProGen"

		local OF_LIBS_OPENSSL="$LIBS_DIR/openssl/"

		# get the absolute path to the included openssl libs
		local OF_LIBS_OPENSSL_ABS_PATH=$(cd $(dirname $OF_LIBS_OPENSSL); pwd)/$(basename $OF_LIBS_OPENSSL)

		local OPENSSL_INCLUDE=$OF_LIBS_OPENSSL_ABS_PATH/include
		local OPENSSL_LIBS=$OF_LIBS_OPENSSL_ABS_PATH/lib/

		local BUILD_OPTS="--no-tests --no-samples --static --omit=CppUnit,CppUnit/WinTestRunner,Data/MySQL,Data/ODBC,PageCompiler,PageCompiler/File2Page,CppParser,PDF,PocoDoc,ProGen"

        export PATH=$PATH:$PWD/AndroidToolchain/bin
		if patch -p0 -u -N --dry-run --silent < $FORMULA_DIR/android.patch 2>/dev/null ; then
			patch -p0 -u < $FORMULA_DIR/android.patch
		fi

        #armv7
		source $LIBS_DIR/openFrameworksCompiled/project/android/paths.make
        rm -rf AndroidToolchain
        $NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-21 --install-dir=./AndroidToolchain --toolchain=arm-linux-androideabi-4.9
		./configure $BUILD_OPTS \
					--include-path=$OPENSSL_INCLUDE \
					--library-path=$OPENSSL_LIBS/armeabi-v7a \
					--config=Android

        make clean
		make ANDROID_ABI=armeabi-v7a

        #x86
		source $LIBS_DIR/openFrameworksCompiled/project/android/paths.make
        rm -rf AndroidToolchain
        $NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-21 --install-dir=./AndroidToolchain --toolchain=x86-4.9
		./configure $BUILD_OPTS \
					--include-path=$OPENSSL_INCLUDE \
					--library-path=$OPENSSL_LIBS/x86 \
					--config=Android

        make clean
		make ANDROID_ABI=x86

		echo `pwd`

		rm -v lib/Android/armeabi-v7a/*d.a
		rm -v lib/Android/x86/*d.a

		export PATH=$OLD_PATH

	elif [ "$TYPE" == "linux" ] ; then
		local BUILD_OPTS="--no-tests --no-samples --static --omit=CppUnit,CppUnit/WinTestRunner,Data/MySQL,Data/ODBC,PageCompiler,PageCompiler/File2Page,CppParser,PDF,PocoDoc,ProGen"
		./configure $BUILD_OPTS
		make
		# delete debug builds
		rm lib/Linux/$(uname -m)/*d.a
	elif [ "$TYPE" == "linux64" ] ; then
		local BUILD_OPTS="--no-tests --no-samples --static --omit=CppUnit,CppUnit/WinTestRunner,Data/MySQL,Data/ODBC,PageCompiler,PageCompiler/File2Page,CppParser,PDF,PocoDoc,ProGen"
		./configure $BUILD_OPTS
		make
		# delete debug builds
		rm lib/Linux/x86_64/*d.a
	elif [ "$TYPE" == "linuxarmv6l" ] ; then
		local BUILD_OPTS="--no-tests --no-samples --static --omit=CppUnit,CppUnit/WinTestRunner,Data/MySQL,Data/ODBC,PageCompiler,PageCompiler/File2Page,CppParser,PDF,PocoDoc,ProGen"
		./configure $BUILD_OPTS
		make
		# delete debug builds
		rm lib/Linux/armv6l/*d.a
	elif [ "$TYPE" == "linuxarmv7l" ] ; then
		local BUILD_OPTS="--no-tests --no-samples --static --omit=CppUnit,CppUnit/WinTestRunner,Data/MySQL,Data/ODBC,PageCompiler,PageCompiler/File2Page,CppParser,PDF,PocoDoc,ProGen"
		./configure $BUILD_OPTS
		make
		# delete debug builds
		rm lib/Linux/armv7l/*d.a
	else
		echoWarning "TODO: build $TYPE lib"
	fi
}

# executed inside the lib src dir, first arg $1 is the dest libs dir root
function copy() {

	# headers
	mkdir -pv $1/include/Poco
	cp -Rv Crypto/include/Poco/Crypto $1/include/Poco
	cp -Rv Data/include/Poco/Data $1/include/Poco
	cp -Rv Data/SQLite/include/Poco/Data $1/include/Poco
	cp -Rv Foundation/include/Poco/* $1/include/Poco
	cp -Rv JSON/include/Poco/JSON $1/include/Poco
	cp -Rv MongoDB/include/Poco/MongoDB $1/include/Poco
	cp -Rv Net/include/Poco/Net $1/include/Poco
	cp -Rv NetSSL_OpenSSL/include/Poco/Net/* $1/include/Poco/Net
	cp -Rv SevenZip/include/Poco/SevenZip $1/include/Poco
	cp -Rv Util/include/Poco/Util $1/include/Poco
	cp -Rv XML/include/Poco/* $1/include/Poco
	cp -Rv Zip/include/Poco/Zip $1/include/Poco

	# libs
	if [ "$TYPE" == "osx" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v lib/Darwin/*.a $1/lib/$TYPE
	elif [ "$TYPE" == "ios" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v lib/$TYPE/*.a $1/lib/$TYPE
	elif [ "$TYPE" == "vs" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v lib/*.lib $1/lib/$TYPE
	elif [ "$TYPE" == "win_cb" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v lib/MinGW/i686/*.a $1/lib/$TYPE
	elif [ "$TYPE" == "linux" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v lib/Linux/$(uname -m)/*.a $1/lib/$TYPE
	elif [ "$TYPE" == "linux64" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v lib/Linux/x86_64/*.a $1/lib/$TYPE
	elif [ "$TYPE" == "linuxarmv6l" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v lib/Linux/armv6l/*.a $1/lib/$TYPE
	elif [ "$TYPE" == "linuxarmv7l" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v lib/Linux/armv7l/*.a $1/lib/$TYPE
	elif [ "$TYPE" == "android" ] ; then
		mkdir -p $1/lib/$TYPE/armeabi-v7a
		cp -v lib/Android/armeabi-v7a/*.a $1/lib/$TYPE/armeabi-v7a

		mkdir -p $1/lib/$TYPE/x86
		cp -v lib/Android/x86/*.a $1/lib/$TYPE/x86
	else
		echoWarning "TODO: copy $TYPE lib"
	fi

	# copy license file
	rm -rf $1/license # remove any older files if exists
	mkdir -p $1/license
	cp -v LICENSE $1/license/
}

# executed inside the lib src dir
function clean() {

	if [ "$TYPE" == "vs" ] ; then
		cmd //c buildwin.cmd ${VS_VER}0 clean static_md both Win32 nosamples notests
	elif [ "$TYPE" == "android" ] ; then
		export PATH=$PATH:$ANDROID_TOOLCHAIN_ANDROIDEABI/bin:$ANDROID_TOOLCHAIN_X86/bin
		make clean ANDROID_ABI=armeabi
		make clean ANDROID_ABI=armeabi-v7a
		make clean ANDROID_ABI=x86
		unset PATH
	else
		make clean
	fi
}
