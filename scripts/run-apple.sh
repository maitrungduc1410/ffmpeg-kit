#!/bin/bash

# ENABLE COMMON FUNCTIONS
source "${BASEDIR}"/scripts/function-"${FFMPEG_KIT_BUILD_TYPE}".sh || return 1

LIB_NAME=$1
ENABLED_LIBRARY_PATH="${LIB_INSTALL_BASE}/${LIB_NAME}"

# DELETE THE PREVIOUS BUILD OF THE LIBRARY
if [ -d "${ENABLED_LIBRARY_PATH}" ]; then
  rm -rf "${ENABLED_LIBRARY_PATH}" || return 1
fi

# PREPARE PATHS & DEFINE ${INSTALL_PKG_CONFIG_DIR}
SCRIPT_PATH="${BASEDIR}/scripts/apple/${LIB_NAME}.sh"
set_toolchain_paths "${LIB_NAME}"

# SET BUILD FLAGS
HOST=$(get_host)
# Xcode 26's clang defaults to C23, where an empty parameter list "()" means "(void)".
# That breaks old K&R-style declarations in several external libraries (e.g. shine's
# "void shine_mdct_initialise();" vs its definition that takes an argument), failing with
# "conflicting types". Pin C17 (clang's previous default) so these legacy C sources build as
# they always did. This flag comes after the autoconf-injected "-std=gnu23", so it wins.
# Only external libraries are affected; ffmpeg and ffmpeg-kit set their own standard.
export CFLAGS="$(get_cflags "${LIB_NAME}") -std=gnu17"
export CXXFLAGS=$(get_cxxflags "${LIB_NAME}")
export LDFLAGS=$(get_ldflags "${LIB_NAME}")
export PKG_CONFIG_LIBDIR="${INSTALL_PKG_CONFIG_DIR}"

cd "${BASEDIR}"/src/"${LIB_NAME}" || return 1

LIB_INSTALL_PREFIX="${ENABLED_LIBRARY_PATH}"
BUILD_DIR=$(get_cmake_build_directory)
CMAKE_SYSTEM_NAME=$(get_apple_cmake_system_name)

echo -e "----------------------------------------------------------------"
echo -e "\nINFO: Building ${LIB_NAME} for ${HOST} with the following environment variables\n"
env
echo -e "----------------------------------------------------------------\n"
echo -e "INFO: System information\n"
echo -e "INFO: $(uname -a)\n"
echo -e "----------------------------------------------------------------\n"

rm -rf "${LIB_INSTALL_PREFIX}" || return 1
rm -rf "${BUILD_DIR}" || return 1

# EXECUTE BUILD SCRIPT OF EACH ENABLED LIBRARY
source "${SCRIPT_PATH}"