# Patch notes

Changes in this community rebuild relative to upstream
[`arthenica/ffmpeg-kit`](https://github.com/arthenica/ffmpeg-kit), newest first.
For packages, licensing and platform support see the [project README](../README.md);
for releasing see the README's "Releasing" section.

## 7.1.5 — FFmpeg 6.0 → 7.1

Upgrades the bundled FFmpeg from `n6.0` to `n7.1.5` (arthenica's FFmpeg mirror) for
**both Android and iOS**. No FFmpegKit API or behaviour changes — only the version
bump and the minimal fixes required to compile against FFmpeg 7.1.

**Why this is a small change.** FFmpegKit carries its own frozen fork of FFmpeg's
command-line tool sources (`fftools_*.c/.h`), which depend only on the public
`libavcodec` / `libavformat` / `libavutil` API. That public API is stable between
6.0 and 7.1, so the large internal `fftools` rewrite upstream did for the standalone
`ffmpeg` binary in 7.0 (new `ffmpeg_sched.c` / `ffmpeg_dec.c` / `ffmpeg_enc.c`) does
**not** affect us — those files are never compiled into the library. Our `fftools_*`
copies are therefore unchanged.

**Changed**

- **FFmpeg source pin** `n6.0` → `n7.1.5` (`scripts/source.sh`). No external library
  versions needed bumping.
- **`emms.h` path** — upstream moved `libavutil/x86/emms.h` to `libavutil/emms.h`
  between 6.0 and 7.x. Updated the header-copy line in `scripts/android/ffmpeg.sh`,
  `scripts/apple/ffmpeg.sh` and `scripts/linux/ffmpeg.sh`.
- **Missing `<string.h>` include** — `ffmpegkit.c` and `ffprobekit.c` (the Android JNI
  bridge, not copied from upstream) call `strlen`/`strcpy` without including
  `<string.h>`. This compiled under 6.0 only because an FFmpeg header transitively
  pulled it in; that path is gone in 7.1, so the include is now added explicitly.
- **iOS x86_64 `--cpu`** (`scripts/apple/ffmpeg.sh`) — the simulator/Catalyst x86_64
  builds passed `--cpu=x86_64` to FFmpeg's `configure`, which forwards it verbatim as
  `-march=x86_64`. FFmpeg 7.1's `configure` no longer normalises that, and Xcode 26's
  clang rejects `-march=x86_64` (it only accepts the hyphenated `x86-64`), so the
  configure C-compiler test fails. `TARGET_CPU` is now `x86-64`; `TARGET_ARCH` stays
  `x86_64` because FFmpeg's `--arch` still expects the underscored form. Android is
  unaffected (x86/x86_64 are disabled there).
- **Version strings** bumped `6.0` → `7.1`:
  - Android native: `ffmpegkit.h` (`FFMPEG_KIT_VERSION`)
  - Android Java test-mode fallback: `NativeLoader.loadVersion()`
  - Android Gradle: `tools/android/build.gradle`, `tools/android/build.lts.gradle`
    (`versionName`), and the publish default in
    `android/ffmpeg-kit-android-lib/build.gradle` (`7.1.5`)
  - iOS: `apple/src/FFmpegKitConfig.m` (`FFmpegKitVersion`)
  - Linux: `linux/src/FFmpegKitConfig.h` (kept in sync; not published)
- **README** — "FFmpeg up to v6" → "FFmpeg 7.1", and the usage examples bumped to
  the `7.1.5` artifacts.

**Credit.** The 6.0 → 7.1 port analysis (notably the confirmation that the `fftools`
rewrite does not affect the library, and the `emms.h` / `<string.h>` fixes) was
informed by the Android-only maintained fork
[`ffmpegkit-maintained/ffmpeg-kit`](https://github.com/ffmpegkit-maintained/ffmpeg-kit).
The iOS side of this upgrade is validated independently here.

## 6.0.x — Community rebuild baseline

Rebuilds and republishes the final upstream FFmpegKit `6.0` (FFmpeg `n6.0`) for
Android and iOS after the original project's retirement, under `LGPL v3.0` (no GPL
libraries). See the git tag for the exact 6.0 tree.
