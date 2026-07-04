# Patch notes

Changes in this community rebuild relative to upstream
[`arthenica/ffmpeg-kit`](https://github.com/arthenica/ffmpeg-kit), newest first.
For packages, licensing and platform support see the [project README](../README.md);
for releasing see the README's "Releasing" section.

## 8.1.2 — FFmpeg 7.1 → 8.1

Upgrades the bundled FFmpeg from `n7.1.5` to `n8.1.2` (arthenica's FFmpeg mirror) for
**both Android and iOS**. No FFmpegKit (Java/ObjC/JS) API or behaviour changes — but,
unlike the 6.0 → 7.1 bump, FFmpeg 8 **removed several public-API members** that
FFmpegKit's frozen command-line tool copies (`fftools_*.c`) still referenced, so those
copies had to be migrated to the FFmpeg 8 API (details below).

**Why the `fftools` copies needed changes.** FFmpegKit ships frozen copies of FFmpeg's
`fftools/` sources (the `ffmpeg`/`ffprobe` command-line front-ends) with in-process
hooks patched in. FFmpeg 8 deleted long-deprecated public API these copies used, so the
build failed with `no member named 'key_frame' in 'struct AVFrame'`,
`... 'ticks_per_frame' ...`, `... 'nb_side_data' in 'struct AVStream'` and
`av_stream_new_side_data` being undeclared. Upstream `ffmpeg-kit` is retired and never
produced FFmpeg-8 `fftools`, so the copies were re-synced from the community fork
[`ffmpegkit-maintained/ffmpeg-kit`](https://github.com/ffmpegkit-maintained/ffmpeg-kit)'s
`android-8.1-lts` tree, which had already rebased them onto FFmpeg 8. The ffmpeg-kit
patch header (cancel-by-id, `forward_report`, `ffmpeg_` prefixes) is preserved, so the
native wrapper interface is unchanged.

**Changed**

- **FFmpeg source pin** `n7.1.5` → `n8.1.2` (`scripts/source.sh`). No external library
  versions needed bumping.
- **`fftools_*` FFmpeg-8 API migration** — applied identically to all three platform
  copies (`android/ffmpeg-kit-android-lib/src/main/cpp`, `apple/src`, `linux/src`).
  Five files changed:
  - `fftools_ffmpeg.c`, `fftools_ffprobe.c`: `AVFrame.key_frame` /
    `top_field_first` / `interlaced_frame` → `AV_FRAME_FLAG_*` flags;
    `AVCodecContext.ticks_per_frame` removed; `AVStream.side_data` /
    `nb_side_data` and `av_stream_new_side_data()` →
    `AVCodecParameters.coded_side_data` / `nb_coded_side_data` with
    `av_packet_side_data_new()`; `FF_PROFILE_UNKNOWN` → `AV_PROFILE_UNKNOWN`;
    `AVFrame.pkt_pos`/`pkt_size` removed (reported as `N/A`); HDR-vivid three-spline
    params moved into an array.
  - `fftools_ffmpeg_demux.c`, `fftools_ffmpeg_filter.c`: `av_stream_new_side_data()` /
    `av_stream_get_side_data()` → the `av_packet_side_data_*` codecpar API; the
    `all_channel_counts` `abuffersink` option was removed in FFmpeg 8.
  - `fftools_opt_common.c`: `AV_CODEC_CAP_SUBFRAMES` and `AVFilter.process_command`
    were removed.
- **Dropped `--disable-postproc`** from the FFmpeg `configure` invocation
  (`scripts/android/ffmpeg.sh`, `scripts/apple/ffmpeg.sh`, `scripts/linux/ffmpeg.sh`).
  FFmpeg 8's `configure` removed that option and hard-errors on it (`Unknown option
  "--disable-postproc"`). It was a no-op for us anyway — `libpostproc` is GPL and stays
  disabled unless `--enable-gpl` is passed, which these no-GPL builds never do.
- **Version strings** bumped `7.1` → `8.1`:
  - Android native: `ffmpegkit.h` (`FFMPEG_KIT_VERSION`)
  - Android Java test-mode fallback: `NativeLoader.loadVersion()`
  - Android Gradle: `tools/android/build.gradle`, `tools/android/build.lts.gradle`
    (`versionName`), and the publish default in
    `android/ffmpeg-kit-android-lib/build.gradle` (`7.1.5` → `8.1.2`)
  - iOS: `apple/src/FFmpegKitConfig.m` (`FFmpegKitVersion`)
  - Linux: `linux/src/FFmpegKitConfig.h` (kept in sync; not published)
- **README** — "built against FFmpeg 7.1" → "FFmpeg 8.1" (7.1 / 6.0 remain available).

**Toolchain.** FFmpeg 8 dropped `yasm` in favour of `nasm` for x86/x86_64 assembly.
Both build workflows already install `nasm`, so no CI change is required (Android
`x86`/`x86_64` and the iOS simulator `x86_64` slice pick it up; arm64/armv7 are
unaffected).

**Heads-up for apps (FFmpeg 8 CLI changes).** FFmpegKit runs raw command strings, so
apps using options removed/changed in FFmpeg 8 must update them, notably:
`-vbsf`/`-absf`/`-sbsf` → `-bsf:v`/`-bsf:a`/`-bsf:s`; `-qscale` now applies to all
streams (use `-qscale:v` for the old behaviour); `-intra` removed (use `-g 0`);
`-vlang`/`-alang` removed (use `-metadata:s:… language=…`); and `-map_metadata`
now takes only an input specifier.

**Credit.** The FFmpeg-8 `fftools` migration was taken from the community, Android-focused
fork [`ffmpegkit-maintained/ffmpeg-kit`](https://github.com/ffmpegkit-maintained/ffmpeg-kit)
(`android-8.1-lts`), which had already rebased the frozen tool copies onto FFmpeg 8. Those
copies are OS-independent C, so the same files are used for the Android, iOS and Linux
builds here; the iOS side is validated independently.

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
