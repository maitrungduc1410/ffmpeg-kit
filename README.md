# FFmpegKit (community rebuild)

> A community-maintained rebuild of [`arthenica/ffmpeg-kit`](https://github.com/arthenica/ffmpeg-kit) for **Android** and **iOS**.

## Table of contents

- [About](#about)
- [Usage](#usage)
  - [iOS (CocoaPods)](#ios-cocoapods)
  - [Android (Gradle)](#android-gradle)
  - [React Native](#react-native)
- [Packages](#packages)
- [Releasing](#releasing)

## About

The original [`ffmpeg-kit`](https://github.com/arthenica/ffmpeg-kit) by Arthenica has been **officially retired** — the project is no longer maintained and all of its previously released prebuilt binaries are being removed from the package registries.

Because our applications still depend on it, this repository **rebuilds and republishes** the binaries so they remain installable.

A few important notes:

- **No GPL builds.** To avoid `GPL` licensing obligations, no `GPL`-licensed libraries (e.g. `x264`, `x265`, `xvidcore`, `vid.stab`) are enabled and no `-gpl` packages are published. Everything here is built under `LGPL v3.0`.
- **FFmpeg version.** Currently built against **FFmpeg 7.1**.
- **Platforms.** Only **Android** and **iOS** are supported and published.

## Usage

Replace `min` with whichever package (`min`, `https`, `audio`, `video`, `full`) you need.
For the full API (running commands, sessions, callbacks, FFprobe, etc.) see the per-platform guides.

### iOS (CocoaPods)

```ruby
# Podfile
pod 'ffmpeg-mobile-min', '~> 7.1'
# pod 'ffmpeg-mobile-https', '~> 7.1'
# pod 'ffmpeg-mobile-audio', '~> 7.1'
# pod 'ffmpeg-mobile-video', '~> 7.1'
# pod 'ffmpeg-mobile-full',  '~> 7.1'
```

See [`apple/README.md`](apple/README.md) for the iOS API.

### Android (Gradle)

Published to Maven Central under the `io.github.maitrungduc1410` group.

```groovy
dependencies {
    implementation 'io.github.maitrungduc1410:ffmpeg-kit-min:7.1.5'
    // implementation 'io.github.maitrungduc1410:ffmpeg-kit-https:7.1.5'
    // implementation 'io.github.maitrungduc1410:ffmpeg-kit-audio:7.1.5'
    // implementation 'io.github.maitrungduc1410:ffmpeg-kit-video:7.1.5'
    // implementation 'io.github.maitrungduc1410:ffmpeg-kit-full:7.1.5'
}
```

See [`android/README.md`](android/README.md) for the Android API.

### React Native

For React Native apps, use the **[`@mtd1410/ffmpegkit`](react-native/README.md)** package. It is built
for the **New Architecture** (TurboModule + Codegen) and wraps the same prebuilt binaries published here.

```sh
npm install @mtd1410/ffmpegkit
```

```js
import { FFmpegKit, ReturnCode } from '@mtd1410/ffmpegkit';

FFmpegKit.execute('-i file1.mp4 -c:v mpeg4 file2.mp4').then(async (session) => {
  const returnCode = await session.getReturnCode();

  if (ReturnCode.isSuccess(returnCode)) {
    // SUCCESS
  }
});
```

See [`react-native/README.md`](react-native/README.md) for installation, selecting a package variant,
and the full JavaScript API usage.

> Use the latest published version; the examples above may not reflect the most recent release.

## Packages

There are five packages, each enabling a different set of external and system libraries. Pick the smallest one that includes the features you need.

<table>
<thead>
<tr>
<th align="center"></th>
<th align="center"><sup>min</sup></th>
<th align="center"><sup>https</sup></th>
<th align="center"><sup>audio</sup></th>
<th align="center"><sup>video</sup></th>
<th align="center"><sup>full</sup></th>
</tr>
</thead>
<tbody>
<tr>
<td align="center"><sup>external libraries</sup></td>
<td align="center">-</td>
<td align="center"><sup>openssl</sup></td>
<td align="center"><sup>lame</sup><br><sup>libilbc</sup><br><sup>libvorbis</sup><br><sup>opencore-amr</sup><br><sup>opus</sup><br><sup>shine</sup><br><sup>soxr</sup><br><sup>speex</sup><br><sup>twolame</sup><br><sup>vo-amrwbenc</sup></td>
<td align="center"><sup>dav1d</sup><br><sup>fontconfig</sup><br><sup>freetype</sup><br><sup>fribidi</sup><br><sup>kvazaar</sup><br><sup>libass</sup><br><sup>libiconv</sup><br><sup>libtheora</sup><br><sup>libvpx</sup><br><sup>libwebp</sup><br><sup>snappy</sup><br><sup>zimg</sup></td>
<td align="center"><sup>dav1d</sup><br><sup>fontconfig</sup><br><sup>freetype</sup><br><sup>fribidi</sup><br><sup>kvazaar</sup><br><sup>lame</sup><br><sup>libass</sup><br><sup>libiconv</sup><br><sup>libilbc</sup><br><sup>libtheora</sup><br><sup>libvorbis</sup><br><sup>libvpx</sup><br><sup>libwebp</sup><br><sup>libxml2</sup><br><sup>opencore-amr</sup><br><sup>openssl</sup><br><sup>opus</sup><br><sup>shine</sup><br><sup>snappy</sup><br><sup>soxr</sup><br><sup>speex</sup><br><sup>twolame</sup><br><sup>vo-amrwbenc</sup><br><sup>zimg</sup></td>
</tr>
<tr>
<td align="center"><sup>android system libraries</sup></td>
<td align="center" colspan=5><sup>zlib</sup><br><sup>MediaCodec</sup></td>
</tr>
<tr>
<td align="center"><sup>ios system libraries</sup></td>
<td align="center" colspan=5><sup>bzip2</sup><br><sup>AudioToolbox</sup><br><sup>AVFoundation</sup><br><sup>iconv</sup><br><sup>VideoToolbox</sup><br><sup>zlib</sup></td>
</tr>
</tbody>
</table>

- On `iOS`, `iconv` is provided by the system, so `libiconv` listed above applies to the `Android` builds only.

## Releasing

> For maintainers. The platform builds run automatically on push (`android build scripts` / `ios build scripts`) and upload their artifacts. Releasing is a separate, **manual** step that reuses those artifacts — nothing is rebuilt.

Run **Actions → `publish` → Run workflow** and set:

- `release_version` — e.g. `6.0.6` (used for the release tags, the CocoaPods version, and the Maven version).
- `publish_ios` / `publish_android` — toggle either platform on/off.
- `ios_build_run_id` / `android_build_run_id` — optional; leave blank to use the latest successful build on `main`, or pin a specific build run to publish from.
- `source_repo` — optional; `owner/repo` to pull the prebuilt artifacts from instead of this repo (e.g. a clone repo where CI runs the long builds, so the main repo only spends quota on publishing). Requires a `CLONE_REPO_TOKEN` secret — a PAT that can read that repo's Actions (a classic PAT with `public_repo`, or a fine-grained PAT created under the source repo's owner with Actions: Read). Leave blank to use this repo.

What it does:

- **GitHub Releases** — iOS xcframework zips on tag `ios-<version>` (consumed by CocoaPods), Android `.aar`s on tag `android-<version>` (direct-download mirror).
- **CocoaPods** — pushes the five `ffmpeg-mobile-*` podspecs to trunk.
- **Maven Central** — publishes the five `io.github.maitrungduc1410:ffmpeg-kit-*` artifacts.

Required repository secrets: `COCOAPODS_TRUNK_TOKEN` (iOS) and `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`, `GPG_SIGNING_KEY`, `GPG_SIGNING_KEY_ID`, `GPG_SIGNING_PASSWORD` (Android). Optionally `CLONE_REPO_TOKEN` when `source_repo` is used.