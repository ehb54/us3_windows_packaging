#!/bin/bash

# usage: makesomo.sh [--qmake | --cmake] [make options]
#   --qmake  build SOMO with qmake (the default)
#   --cmake  build SOMO with CMake (cmake --preset qt5-msys2); needs an
#            ultrascan3 tree with SOMO's CMake build
#            (us_somo/develop/CMakePresets.json) and a Windows build of cmake
#            (setup.pl --cmake installs one)
BUILDSYS=qmake
case "$1" in
  --qmake) BUILDSYS=qmake; shift ;;
  --cmake) BUILDSYS=cmake; shift ;;
esac

MKARGS="$@"
if [ $# -eq 0 ]; then
  MKARGS="-j 7"
  if [ `uname -s|grep -ci "mingw"` -ne 0 ]; then
    MKARGS="-j 2"
  fi
fi
export MAKE="make ${MKARGS}"

if [ -z "$ULTRASCAN" ]; then
    ULTRASCAN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    echo "Notice: the ULTRASCAN environment variable was not set, so using $ULTRASCAN"
fi

if [ ! -d "$ULTRASCAN/us_somo" ]; then
    echo "Error: $ULTRASCAN/us_somo is not a directory"
    exit -1;
fi

ISMAC=0
FIXMAC=""
if [ "`uname -s`" = "Darwin" ]; then
  ISMAC=1
  FIXMAC=./fix-mac-make.sh
fi

ISWIN=0
if [ `uname -s|grep -ci "msys"` -ne 0 ]; then
  ISWIN=1
fi
if [ `uname -s|grep -ci "mingw"` -ne 0 ]; then
  ISWIN=1
fi
if [ `uname -s|grep -ci "cygwin"` -ne 0 ]; then
  ISWIN=2
fi

# cmake for --cmake: on Windows the one setup.pl --cmake installs, if there is
# one (it must be a Windows build of cmake, not MSYS's), else the one on the PATH
CMAKE=cmake
if [ $ISWIN -eq 1 ]; then
  for c in $HOME/src/cmake-*-windows-x86_64/bin/cmake.exe; do
    [ -x "$c" ] && CMAKE="$c"
  done
fi

DIR=$(pwd)
NBERR=0
##SOMO3=`(cd $ULTRASCAN/../ULTRASCAN_somo;pwd)`
SOMO3=`(cd $ULTRASCAN/us_somo;pwd)`

if [ $ISWIN -eq 1 ] && [ "$BUILDSYS" = "qmake" ]; then
  # Run revision and qmake in Cygwin window
  cd $SOMO3/develop
  pwd
  ./version.sh
  ./revision.sh
  mkdir ../bin 2> /dev/null
  qmake us_somo.pro
  cp Makefile Makefile-all
  cp Makefile.Release Makefile.R-all
  cp Makefile.Debug Makefile.D-all
  qmake libus_somo.pro
  cp Makefile Makefile-lib
  cp Makefile.Release Makefile.R-lib
  cp Makefile.Debug Makefile.D-lib
  cd $SOMO3/develop
  ls -l Make*
#  echo "QMAKE complete. Rerun $0 in MSYS (MINGW32) window"
#  exit 0
fi

if [ $ISWIN -eq 1 ]; then
  # Run makes for lib,all in MSYS window
  cd $SOMO3/develop
  echo current path for somo compiling is `pwd`
  if [ "$BUILDSYS" = "cmake" ]; then
    if [ ! -f CMakePresets.json ]; then
      echo "Error: $SOMO3/develop has no CMakePresets.json, so this tree cannot build SOMO with CMake; use qmake"
      exit -1
    fi
    "$CMAKE" --preset qt5-msys2 || exit -1
    # MAKE (exported above for qmake's makefiles) and MAKEFLAGS (set by qt5env)
    # would force -j into every sub-make, so make gets the options only here
    ( unset MAKE MAKEFLAGS; "$CMAKE" --build --preset qt5-msys2 -- ${MKARGS} ) || exit -1
    # the build is in build/qt5-msys2: put the programs and the DLL where qmake does
    mkdir -p ../bin
    cp -p build/qt5-msys2/bin/*.exe build/qt5-msys2/bin/*.dll ../bin/
  else
    qmake libus_somo.pro
    # cp Makefile-lib Makefile
    # cp Makefile.R-lib Makefile.Release
    # cp Makefile.D-lib Makefile.Debug
    make
    # cp Makefile-all Makefile
    # cp Makefile.R-all Makefile.Release
    # cp Makefile.D-all Makefile.Debug
    qmake us_somo.pro
    make
  fi
  echo "MAKE of somo complete"
  cd ../
  ls -l ./bin
  echo cp -p bin/* $ULTRASCAN/bin/
  cp -p bin/* $ULTRASCAN/bin/
  echo cp -p add_to_bin/* $ULTRASCAN/bin/
  cp -p add_to_bin/* $ULTRASCAN/bin/
  echo cp -rp etc $ULTRASCAN
  cp -rp etc $ULTRASCAN
  echo mkdir $ULTRASCAN/somo
  mkdir $ULTRASCAN/somo 2> /dev/null
  echo rsync -av --exclude .svn --exclude .git $SOMO3/somo/demo $ULTRASCAN/somo
  rsync -av --exclude .svn --exclude .git $SOMO3/somo/demo $ULTRASCAN/somo/
  echo rsync -av --exclude .svn --exclude .git $SOMO3/somo/doc $ULTRASCAN/somo
  rsync -av --exclude .svn --exclude .git $SOMO3/somo/doc $ULTRASCAN/somo/
  exit 0
fi

# Do makes for Linux,Mac
echo "rsync -av --exclude .svn $SOMO3/etc $ULTRASCAN"
rsync -av --exclude .svn $SOMO3/etc $ULTRASCAN

cd $SOMO3/develop
sh version.sh
qmake us_somo.pro
cp -p Makefile  Makefile-all
qmake libus_somo.pro
cp -p Makefile  Makefile-lib
${MAKE} -f Makefile-lib
${MAKE} -f Makefile-all
cd $SOMO3

if [ $ISMAC -ne 0 ]; then
  echo "RUN libnames, appnames"
  ./somo_libnames.sh
  ./somo_appnames.sh
fi

# symlink bin64 to bin util somo is updated to drop bin64                                                                                                                                                             
if [ "`uname -s`" = "Linux" ]; then
    SOMOBIN64="$ULTRASCAN/bin64"
    SOMOBIN="$ULTRASCAN/bin"

    if [ -L ${SOMOBIN64} ] ; then
        if [ -e ${SOMOBIN64} ] ; then
            echo "${SOMOBIN64} - symlink ok"
        else
            echo "ERROR: ${SOMOBIN64} is a broken link, manually fix"
        fi
    elif [ -e ${SOMOBIN64} ] ; then
        echo "ERROR: ${SOMOBIN64} - not a symlink, manually fix"
    else
        echo "creating ${SOMOBIN64} symlink"
        ln -s ${SOMOBIN} ${SOMOBIN64}
    fi
fi

ls -lrt ./lib ./bin64
echo ""
echo "rsync -av --exclude .svn $SOMO3/lib/ $ULTRASCAN/lib"
rsync -av --exclude .svn $SOMO3/lib/ $ULTRASCAN/lib
echo "rsync -av --exclude .svn $SOMO3/bin64/ $ULTRASCAN/bin"
rsync -av --exclude .svn $SOMO3/bin64/ $ULTRASCAN/bin
echo rsync -av --exclude .svn $SOMO3/add_to_bin/ $ULTRASCAN/bin
rsync -av --exclude .svn $SOMO3/add_to_bin/ $ULTRASCAN/bin
echo rsync -av --exclude .svn $SOMO3/etc/ $ULTRASCAN/etc
rsync -av --exclude .svn $SOMO3/etc/ $ULTRASCAN/etc
echo ""
echo "MAKE of somo complete"

exit 0

