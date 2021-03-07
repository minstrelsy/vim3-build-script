#!/bin/bash

#
# References: https://source.android.com/setup/build/devices#vim3_and_vim3l_boards
#

export SOURCE_PATH=$(pwd)
export ROOT_PATH=$(pwd)

BUILD_PRODUCT_FULLNAME=yukawa
BUILD_PRODUCT=yukawa
BUILD_VARIANT=userdebug
BUILD_TYPE=debug
BUILD_JOBS=4

CLEAN_BUILD="false"
FAST_BUILD="false"

USE_KERNEL_5_4="false"

show_help() {

cat << _END_HELP_

Usage: `basename $0` [options]

-p <p>  Set the build product. Default is '${BUILD_PRODUCT}'.
-v <v>  Set the build variant. Default is '${BUILD_VARIANT}'.
-j <n>  Set the amount of parallel build jobs to <n>. Default is '${BUILD_JOBS}'.
-k      Use kernel 5.4.
-f      Build a fast Android build.
-c      Build a clean Android build.
-u      Build a 'user' Android build.
-h      This help.
_END_HELP_
}

while getopts "p:v:kfcuj:h" opt; do
    case $opt in
    p)
        BUILD_PRODUCT=${OPTARG}
        ;;
    v)
        BUILD_VARIANT=${OPTARG}
        ;;
    k)
        USE_KERNEL_5_4="true"
        ;;
    f)
        FAST_BUILD="true"
        ;;
    c)
        CLEAN_BUILD="true"
        ;;
    u)
        BUILD_VARIANT=user
        BUILD_TYPE=release
        ;;
    j)
        BUILD_JOBS=${OPTARG}
        ;;
    h)
        show_help
        exit 0
        ;;
    esac
done

if [ -z "$SOURCE_PATH" ]
then
    echo "SOURCE_PATH is not set"
    show_help
    exit 1
fi

if [ -z "$BUILD_PRODUCT" ]
then
    echo "BUILD_PRODUCT is not set"
    show_help
    exit 1
fi

if [ -z "$BUILD_PRODUCT_FULLNAME" ]
then
    export BUILD_PRODUCT_FULLNAME=${BUILD_PRODUCT^}
fi

export VER_BUILD_INFO=$(date +%Y_%m_%d)
export JENKINS_BUILD_NUMBER=$(date +%s)
export BUILD_NUMBER=${BUILD_PRODUCT_FULLNAME^}_${VER_BUILD_INFO}_${JENKINS_BUILD_NUMBER}_${BUILD_TYPE}

# Show environment
echo ""
echo "========================================================="
echo "VER_BUILD_INFO=${VER_BUILD_INFO}"
echo "JENKINS_BUILD_NUMBER=${JENKINS_BUILD_NUMBER}"
echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "BUILD_PRODUCT_FULLNAME=${BUILD_PRODUCT_FULLNAME^}"
echo "BUILD_PRODUCT=${BUILD_PRODUCT}"
echo "BUILD_VARIANT=${BUILD_VARIANT}"
echo "BUILD_TYPE=${BUILD_TYPE}"
echo "BUILD_JOBS=${BUILD_JOBS}"
echo "JAVA_HOME=${JAVA_HOME}"
echo "ANDROID_HOME=${ANDROID_HOME}"
echo "ANDROID_NDK_HOME=${ANDROID_NDK_HOME}"
echo "ANDROID_NDK=${ANDROID_NDK}"
echo "USE_KERNEL_5_4=${USE_KERNEL_5_4}"
echo "========================================================="
echo ""

source ./build/envsetup.sh
lunch ${BUILD_PRODUCT}-${BUILD_VARIANT}

if [ "${CLEAN_BUILD}" == "true" ]; then
    echo ""
    echo "Doing a clean build"
    echo ""

    make clobber
else
    if [ "${FAST_BUILD}" == "true" ]; then
        echo ""
        echo "Doing a fast build"
        echo ""
    else
        rm -fr \
        out/.kati* \
        out/*.ninja \
        out/*.sh \
        out/dist \
        out/target/product/${BUILD_PRODUCT}/root \
        out/target/product/${BUILD_PRODUCT}/system \
        out/target/product/${BUILD_PRODUCT}/recovery \
        out/target/product/${BUILD_PRODUCT}/vendor \
        out/target/product/${BUILD_PRODUCT}/persist \
        out/target/product/${BUILD_PRODUCT}/system_other \
        out/target/product/${BUILD_PRODUCT}/signed \
        out/target/product/${BUILD_PRODUCT}/signed_encrypted \
        out/target/product/${BUILD_PRODUCT}/integrity \
        out/target/product/${BUILD_PRODUCT}/dex_bootjars \
        out/target/product/${BUILD_PRODUCT}/kernel \
        out/target/product/${BUILD_PRODUCT}/filesmap \
        out/target/product/${BUILD_PRODUCT}/OTA_Binary_Packs \
        out/target/product/${BUILD_PRODUCT}/OTA_Target_Files \
        out/target/product/${BUILD_PRODUCT}/*.json \
        out/target/product/${BUILD_PRODUCT}/*.txt \
        out/target/product/${BUILD_PRODUCT}/*.zip \
        out/target/product/${BUILD_PRODUCT}/*.img \
        out/target/product/${BUILD_PRODUCT}/*.elf \
        out/target/product/${BUILD_PRODUCT}/obj/ABL_OBJ \
        out/target/product/${BUILD_PRODUCT}/obj/ETC \
        out/target/product/${BUILD_PRODUCT}/obj/PACKAGING \
        out/target/product/${BUILD_PRODUCT}/obj/APPS \
        out/target/product/${BUILD_PRODUCT}/obj/vendor \
        out/target/product/${BUILD_PRODUCT}/obj/NOTICE* \
        out/target/product/${BUILD_PRODUCT}/obj/lib/vendor* \
        out/target/product/${BUILD_PRODUCT}/symbols/system \
        out/target/product/${BUILD_PRODUCT}/symbols/recovery \
        out/target/product/${BUILD_PRODUCT}/symbols/vendor
    fi
fi

rm -fr $SOURCE_PATH/build_HLOS_log.txt
touch $SOURCE_PATH/build_HLOS_log.txt

echo ""
echo "========================================================="
echo "    Building $BUILD_NUMBER images"
echo "========================================================="
echo ""

if [ "${USE_KERNEL_5_4}" == "true" ]; then
  make TARGET_USE_TABLET_LAUNCHER=true TARGET_VIM3=true TARGET_KERNEL_USE=5.4 dist -j ${BUILD_JOBS} 2>&1 | tee -a build_HLOS_log.txt
else
  make TARGET_USE_TABLET_LAUNCHER=true TARGET_VIM3=true dist -j ${BUILD_JOBS} 2>&1 | tee -a build_HLOS_log.txt
fi

echo ""
echo "========================================================="
echo "    Done building $BUILD_NUMBER images"
echo "========================================================="
echo ""

TMP_BUILD_RESULT=$(tail -50 build_HLOS_log.txt)

if [[ $TMP_BUILD_RESULT =~ "FAILED" ||  $TMP_BUILD_RESULT =~ "failed" ]]; then
	exit 1
fi
