#!/bin/bash

# ALWAYS CLEAN THE PREVIOUS BUILD
make distclean 2>/dev/null 1>/dev/null

# REGENERATE BUILD FILES IF NECESSARY OR REQUESTED
if [[ ! -f "${BASEDIR}"/src/"${LIB_NAME}"/configure ]] || [[ ${RECONF_libuuid} -eq 1 ]]; then
  autoreconf_library "${LIB_NAME}" 1>>"${BASEDIR}"/build.log 2>&1 || return 1
fi

# NDK r27 ships clang 18, where calls to undeclared functions are errors by default
# (-Wimplicit-function-declaration). gen_uuid.c calls flock() without libuuid's configure
# detecting <sys/file.h> when cross-compiling, so downgrade it to a warning here.
# flock is available in the Android C library, so the symbol still links correctly.
export CFLAGS="${CFLAGS} -Wno-implicit-function-declaration"

./configure \
  --prefix="${LIB_INSTALL_PREFIX}" \
  --with-pic \
  --with-sysroot="${ANDROID_SYSROOT}" \
  --enable-static \
  --disable-shared \
  --disable-fast-install \
  --host="${HOST}" || return 1

make -j$(get_cpu_count) || return 1

make install || return 1

# CREATE PACKAGE CONFIG MANUALLY
create_uuid_package_config "1.0.3" || return 1