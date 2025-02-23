#! /bin/bash
#
# OpenCV
# library of programming functions mainly aimed at real-time computer vision
# http://opencv.org
#
# uses a CMake build system
 
FORMULA_TYPES=( "osx" "ios" )
 
# define the version
VER=2.4.9
 
# tools for git use
GIT_URL=https://github.com/Itseez/opencv.git
GIT_TAG=$VER

# these paths don't really matter - they are set correctly further down
local LIB_FOLDER="$BUILD_ROOT_DIR/OpenCv"
local LIB_FOLDER32="$LIB_FOLDER-32"
local LIB_FOLDER64="$LIB_FOLDER-64"
local LIB_FOLDER_IOS="$LIB_FOLDER-IOS"
local LIB_FOLDER_IOS_SIM="$LIB_FOLDER-IOSIM"

 
# download the source code and unpack it into LIB_NAME
function download() {
  curl -Lk https://github.com/Itseez/opencv/archive/$VER.tar.gz -o opencv-$VER.tar.gz
  tar -xf opencv-$VER.tar.gz
  mv opencv-$VER opencv
  rm opencv*.tar.gz
}
 
# prepare the build environment, executed inside the lib src dir
function prepare() {
  : # noop

  # Patch for Clang for 2.4
  # https://github.com/Itseez/opencv/commit/35f96d6da76099d80180439c857a4abe5cb17966
  cd modules/legacy/src
  if patch -p0 -u -N --dry-run --silent < $FORMULA_DIR/patch.calibfilter.cpp.patch 2>/dev/null ; then
      patch -p0 -u < $FORMULA_DIR/patch.calibfilter.cpp.patch
  fi
  cd ../../../
}
 
function build_osx() {

  SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version` 
  set -e
  CURRENTPATH=`pwd`

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

  mkdir -p "$CURRENTPATH/build/$TYPE/"
  
  echo "--------------------"

  isBuilding=true;
 

  echo "Running cmake"
  if [ "$1" == "64" ] ; then
    LOG="$CURRENTPATH/build/$TYPE/opencv2-x86_64-${VER}.log"
    echo "Log:" >> "${LOG}" 2>&1
    while $isBuilding; do theTail="$(tail -n 1 ${LOG})"; echo $theTail | cut -c -70 ; echo "...";sleep 30; done & # fix for 10 min time out travis

    set +e
    cmake . -DCMAKE_INSTALL_PREFIX=$LIB_FOLDER64 \
      -DGLFW_BUILD_UNIVERSAL=ON \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=10.7 \
      -DCMAKE_OSX_ARCHITECTURES="x86_64" \
      -DENABLE_FAST_MATH=ON \
      -DCMAKE_CXX_FLAGS="-fvisibility-inlines-hidden -stdlib=libc++ -O3" \
      -DCMAKE_C_FLAGS="-fvisibility-inlines-hidden -stdlib=libc++ -O3" \
      -DCMAKE_BUILD_TYPE="Release" \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_DOCS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_FAT_JAVA_LIB=OFF \
      -DBUILD_JASPER=OFF \
      -DBUILD_PACKAGE=OFF \
      -DBUILD_opencv_java=OFF \
      -DBUILD_opencv_python=OFF \
      -DBUILD_opencv_apps=OFF \
      -DBUILD_JPEG=OFF \
      -DBUILD_PNG=OFF \
      -DWITH_1394=OFF \
      -DWITH_CARBON=OFF \
      -DWITH_JPEG=OFF \
      -DWITH_PNG=OFF \
      -DWITH_FFMPEG=OFF \
      -DWITH_OPENCL=OFF \
      -DWITH_OPENCLAMDBLAS=OFF \
      -DWITH_OPENCLAMDFFT=OFF \
      -DWITH_GIGEAPI=OFF \
      -DWITH_CUDA=OFF \
      -DWITH_CUFFT=OFF \
      -DWITH_JASPER=OFF \
      -DWITH_LIBV4L=OFF \
      -DWITH_IMAGEIO=OFF \
      -DWITH_IPP=OFF \
      -DWITH_OPENNI=OFF \
      -DWITH_QT=OFF \
      -DWITH_QUICKTIME=OFF \
      -DWITH_V4L=OFF \
      -DWITH_PVAPI=OFF \
      -DBUILD_TESTS=OFF \
      -DBUILD_PERF_TESTS=OFF >> "${LOG}" 2>&1

      if [ $? != 0 ];
      then
        tail -n 10 "${LOG}"
        echo "Problem while CMAKE - Please check ${LOG}"
        exit 1
      else
        tail -n 10 "${LOG}"
        echo "CMAKE Successful for x86_64"
      fi
  elif [ "$1" == "32" ] ; then
    LOG="$CURRENTPATH/build/$TYPE/opencv2-i386-${VER}.log"
    while $isBuilding; do theTail="$(tail -n 1 ${LOG})"; echo $theTail | cut -c -70 ; echo "...";sleep 30; done & # fix for 10 min time out travis
    echo "Log:" >> "${LOG}" 2>&1
    set +e
    # NB - using a special BUILD_ROOT_DIR
    cmake . -DCMAKE_INSTALL_PREFIX=$LIB_FOLDER32 \
      -DGLFW_BUILD_UNIVERSAL=ON \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=10.6 \
      -DCMAKE_OSX_ARCHITECTURES="i386" \
      -DENABLE_FAST_MATH=ON \
      -DCMAKE_CXX_FLAGS="-fvisibility-inlines-hidden -stdlib=libstdc++ -O3" \
      -DCMAKE_C_FLAGS="-fvisibility-inlines-hidden -stdlib=libstdc++ -O3" \
      -DCMAKE_BUILD_TYPE="Release" \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_DOCS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_FAT_JAVA_LIB=OFF \
      -DBUILD_JASPER=OFF \
      -DBUILD_PACKAGE=OFF \
      -DBUILD_opencv_java=OFF \
      -DBUILD_opencv_python=OFF \
      -DBUILD_opencv_apps=OFF \
      -DBUILD_JPEG=OFF \
      -DBUILD_PNG=OFF \
      -DWITH_1394=OFF \
      -DWITH_CARBON=OFF \
      -DWITH_FFMPEG=OFF \
      -DWITH_OPENCL=OFF \
      -DWITH_OPENCLAMDBLAS=OFF \
      -DWITH_OPENCLAMDFFT=OFF \
      -DWITH_GIGEAPI=OFF \
      -DWITH_CUDA=OFF \
      -DWITH_CUFFT=OFF \
      -DWITH_JASPER=OFF \
      -DWITH_JPEG=OFF \
      -DWITH_PNG=OFF \
      -DWITH_LIBV4L=OFF \
      -DWITH_IMAGEIO=OFF \
      -DWITH_IPP=OFF \
      -DWITH_OPENNI=OFF \
      -DWITH_QT=OFF \
      -DWITH_QUICKTIME=OFF \
      -DWITH_V4L=OFF \
      -DWITH_PVAPI=OFF \
      -DBUILD_TESTS=OFF \
      -DBUILD_PERF_TESTS=OFF >> "${LOG}" 2>&1

      if [ $? != 0 ];
      then
        tail -n 10 "${LOG}"
        echo "Problem while CMAKE - Please check ${LOG}"
        exit 1
      else
        tail -n 10 "${LOG}"
        echo "CMAKE Successful for i386"
      fi
  fi

  echo "--------------------"
  echo "Running make clean"
 
  make clean >> "${LOG}" 2>&1
  if [ $? != 0 ];
    then
      tail -n 10 "${LOG}"
      echo "Problem while make clean- Please check ${LOG}"
      exit 1
    else
      tail -n 10 "${LOG}"
      echo "Make Clean Successful"
  fi

  echo "--------------------"
  echo "Running make"
  make >> "${LOG}" 2>&1
  if [ $? != 0 ];
    then
      tail -n 10 "${LOG}"
      echo "Problem while make - Please check ${LOG}"
      exit 1
    else
      tail -n 10 "${LOG}"
      echo "Make  Successful"
  fi
  echo "--------------------"
  echo "Running make install"
  make install >> "${LOG}" 2>&1
    if [ $? != 0 ];
      then
        tail -n 10 "${LOG}"
        echo "Problem while make install - Please check ${LOG}"
        exit 1
      else
        tail -n 10 "${LOG}"
        echo "Make install Successful"
    fi

    isBuilding=false;
}




function make_universal_binary() {
  shopt -s nullglob

  src1="$1"
  src2="$2"
  dst="$3"

  libs="$src1/lib/libopencv*.a"

  for lib in $libs
  do
    fname=$(basename "$lib"); 
    otherLib="$src2/lib/$fname"
    echo "lipoing $fname"
    lipo -create $lib $otherLib -o "$dst/lib/$fname" || true
  done

  thirdparty="$src1/share/OpenCV/3rdparty/lib/*.a"

  for lib in $thirdparty
  do
    fname=$(basename "$lib"); 
    otherLib="$src2/share/OpenCV/3rdparty/lib/$fname"
    echo "lipoing $fname"
    lipo -create $lib $otherLib -o "$dst/lib/$fname" || true
  done

  outputlist="$dst/lib/lib*.a"

  libtool -static $outputlist -o "$dst/lib/opencv.a"
}

# executed inside the lib src dir
function build() {
  rm -f CMakeCache.txt
 
  LIB_FOLDER="$BUILD_ROOT_DIR/$TYPE/FAT/OpenCv"
  LIB_FOLDER32="$BUILD_ROOT_DIR/$TYPE/32bit/OpenCv"
  LIB_FOLDER64="$BUILD_ROOT_DIR/$TYPE/64bit/OpenCv"

  if [ "$TYPE" == "osx" ] ; then
    # 64-bit OF transition, build x86-64 and i386 separately
    rm -f CMakeCache.txt
    build_osx "64";
    rm -f CMakeCache.txt
    build_osx "32";

	 mkdir -p $LIB_FOLDER/include
	 mkdir -p $LIB_FOLDER/lib
 
    # lipo shit together
    make_universal_binary "$LIB_FOLDER64" "$LIB_FOLDER32" "$LIB_FOLDER" 

    # copy headers
    cp -R $LIB_FOLDER64/include/opencv $LIB_FOLDER/include/opencv
    cp -R $LIB_FOLDER64/include/opencv2 $LIB_FOLDER/include/opencv2
  fi

  if [ "$TYPE" == "ios" ] ; then

    local LIB_FOLDER_IOS="$BUILD_ROOT_DIR/$TYPE/iOS/OpenCv"
    local LIB_FOLDER_IOS_SIM="$BUILD_ROOT_DIR/$TYPE/iOS_SIMULATOR/OpenCv"


    # This was quite helpful as a reference: https://github.com/x2on/OpenSSL-for-iPhone
    # Refer to the other script if anything drastic changes for future versions
    SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version` 
    set -e
    CURRENTPATH=`pwd`
    
    DEVELOPER=$XCODE_DEV_ROOT
    TOOLCHAIN=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain
    VERSION=$VER

    local IOS_ARCHS="i386 x86_64 armv7 arm64" #armv7s
    local STDLIB="libc++"
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



    export THECOMPILER=$TOOLCHAIN/usr/bin
     
    

      # loop through architectures! yay for loops!
    for IOS_ARCH in ${IOS_ARCHS}
    do
      # make sure backed up
       rm -f CMakeCache.txt
      MIN_IOS_VERSION=$IOS_MIN_SDK_VER
        # min iOS version for arm64 is iOS 7

        if [[ "${IOS_ARCH}" == "arm64" || "${IOS_ARCH}" == "x86_64" ]]; then
          MIN_IOS_VERSION=7.0 # 7.0 as this is the minimum for these architectures
        elif [ "${IOS_ARCH}" == "i386" ]; then
          MIN_IOS_VERSION=5.1 # 6.0 to prevent start linking errors
        fi
        export IPHONE_SDK_VERSION_MIN=$IOS_MIN_SDK_VER

      
      echo "The compiler: $THECOMPILER"
      MIN_TYPE=-miphoneos-version-min=
      if [[ "${IOS_ARCH}" == "i386" || "${IOS_ARCH}" == "x86_64" ]];
      then
        PLATFORM="iPhoneSimulator"
        ISSIM="TRUE"
        MIN_TYPE=-mios-simulator-version-min=
      else
        PLATFORM="iPhoneOS"
        ISSIM="FALSE"
      fi

      
      export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
      export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
      export BUILD_TOOLS="${DEVELOPER}"

      mkdir -p "$CURRENTPATH/build/$TYPE/$IOS_ARCH"
      LOG="$CURRENTPATH/build/$TYPE/$IOS_ARCH/opencv2-$IOS_ARCH-${VER}.log"
      set +e


      isBuilding=true;
      echo "Log:" >> "${LOG}" 2>&1
      while $isBuilding; do theTail="$(tail -n 1 ${LOG})"; echo $theTail | cut -c -70 ; echo "...";sleep 30; done & # fix for 10 min time out travis



      cmake . -DCMAKE_INSTALL_PREFIX="$CURRENTPATH/build/$TYPE/$IOS_ARCH" \
      -DIOS=1 \
      -DAPPLE=1 \
      -DUNIX=1 \
      -DCMAKE_CXX_COMPILER=$THECOMPILER/clang++ \
      -DCMAKE_CC_COMPILER=$THECOMPILER/clang \
      -DIPHONESIMULATOR=$ISSIM \
      -DCMAKE_CXX_COMPILER_WORKS="TRUE" \
      -DCMAKE_C_COMPILER_WORKS="TRUE" \
      -DSDKVER="${SDKVERSION}" \
      -DCMAKE_IOS_DEVELOPER_ROOT="${CROSS_TOP}" \
      -DDEVROOT="${CROSS_TOP}" \
      -DSDKROOT="${CROSS_SDK}" \
      -DCMAKE_OSX_SYSROOT="${CROSS_TOP}/SDKs/${CROSS_SDK}" \
      -DCMAKE_OSX_ARCHITECTURES="${IOS_ARCH}" \
      -DCMAKE_XCODE_EFFECTIVE_PLATFORMS="-$PLATFORM" \
      -DGLFW_BUILD_UNIVERSAL=ON \
      -DENABLE_FAST_MATH=ON \
      -DCMAKE_CXX_FLAGS="-stdlib=libc++ -fvisibility=hidden -fPIC -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -DNDEBUG -Os $MIN_TYPE$IPHONE_SDK_VERSION_MIN" \
      -DCMAKE_C_FLAGS="-stdlib=libc++ -fvisibility=hidden -fPIC -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -DNDEBUG -Os $MIN_TYPE$IPHONE_SDK_VERSION_MIN"  \
      -DCMAKE_BUILD_TYPE="Release" \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_DOCS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_FAT_JAVA_LIB=OFF \
      -DBUILD_JASPER=OFF \
      -DBUILD_PACKAGE=OFF \
      -DBUILD_opencv_java=OFF \
      -DBUILD_opencv_python=OFF \
      -DBUILD_opencv_apps=OFF \
      -DBUILD_JPEG=OFF \
      -DBUILD_PNG=OFF \
      -DWITH_1394=OFF \
      -DWITH_JPEG=OFF \
      -DWITH_PNG=OFF \
      -DWITH_CARBON=OFF \
      -DWITH_FFMPEG=OFF \
      -DWITH_OPENCL=OFF \
      -DWITH_OPENCLAMDBLAS=OFF \
      -DWITH_OPENCLAMDFFT=OFF \
      -DWITH_GIGEAPI=OFF \
      -DWITH_CUDA=OFF \
      -DWITH_CUFFT=OFF \
      -DWITH_JASPER=OFF \
      -DWITH_LIBV4L=OFF \
      -DWITH_IMAGEIO=OFF \
      -DWITH_IPP=OFF \
      -DWITH_OPENNI=OFF \
      -DWITH_QT=OFF \
      -DWITH_QUICKTIME=OFF \
      -DWITH_V4L=OFF \
      -DWITH_PVAPI=OFF \
      -DBUILD_TESTS=OFF \
      -DBUILD_PERF_TESTS=OFF >> "${LOG}" 2>&1

      if [ $? != 0 ];
      then
        tail -n 10 "${LOG}"
        echo "Problem while CMAKE - Please check ${LOG}"
        exit 1
      else
        tail -n 10 "${LOG}"
        echo "CMAKE Successful for ${IOS_ARCH}"
      fi

    echo "--------------------"
    echo "Running make clean for ${IOS_ARCH}"
    make clean >> "${LOG}" 2>&1
    if [ $? != 0 ];
      then
        tail -n 10 "${LOG}"
        echo "Problem while make clean- Please check ${LOG}"
        exit 1
      else
        tail -n 10 "${LOG}"
        echo "Make Clean Successful for ${IOS_ARCH}"
    fi

    echo "--------------------"
    echo "Running make for ${IOS_ARCH}"
    make >> "${LOG}" 2>&1
    if [ $? != 0 ];
      then
        tail -n 10 "${LOG}"
        echo "Problem while make - Please check ${LOG}"
        exit 1
      else
        tail -n 10 "${LOG}"
        echo "Make  Successful for ${IOS_ARCH}"
    fi

    echo "--------------------"
    echo "Running make install for ${IOS_ARCH}"
    make install >> "${LOG}" 2>&1
    if [ $? != 0 ];
      then
        tail -n 10 "${LOG}"
        echo "Problem while make install - Please check ${LOG}"
        exit 1
      else
        tail -n 10 "${LOG}"
        echo "Make install Successful for ${IOS_ARCH}"
    fi

    rm -f CMakeCache.txt
    unset CROSS_TOP CROSS_SDK BUILD_TOOLS
    isBuilding=false;


    done

    mkdir -p lib/$TYPE
    echo "--------------------"
    echo "Creating Fat Libs"
    cd build/iOS
    # link into universal lib, strip "lib" from filename
    local lib
    rm -rf i386/lib/pkgconfig

    for lib in $( ls -1 i386/lib) ; do
      local renamedLib=$(echo $lib | sed 's|lib||')
      if [ ! -e $renamedLib ] ; then
        lipo -c armv7/lib/$lib arm64/lib/$lib i386/lib/$lib x86_64/lib/$lib -o "$CURRENTPATH/lib/$TYPE/$renamedLib"
      fi
    done

    cd ../../
    echo "--------------------"
    echo "Copying includes"
    cp -R "build/$TYPE/x86_64/include/" "lib/include/"

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

  # end if iOS
  fi 

}


# executed inside the lib src dir, first arg $1 is the dest libs dir root
function copy() {

  LIB_FOLDER="$BUILD_ROOT_DIR/$TYPE/FAT/OpenCv"

  # prepare headers directory if needed
  mkdir -p $1/include
 
  # prepare libs directory if needed
  mkdir -p $1/lib/$TYPE
 
  if [ "$TYPE" == "osx" ] ; then
    # Standard *nix style copy.
    # copy headers
    cp -R $LIB_FOLDER/include/ $1/include/
 
    # copy lib
    cp -R $LIB_FOLDER/lib/opencv.a $1/lib/$TYPE/
  fi

  if [ "$TYPE" == "ios" ] ; then
    # Standard *nix style copy.
    # copy headers

    cp -Rv lib/include/ $1/include/
    mkdir -p $1/lib/$TYPE
    cp -v lib/$TYPE/*.a $1/lib/$TYPE
  fi

  # copy license file
  rm -rf $1/license # remove any older files if exists
  mkdir -p $1/license
  cp -v LICENSE $1/license/

}
 
# executed inside the lib src dir
function clean() {
  if [ "$TYPE" == "osx" ] ; then
    make clean;
  fi
}
