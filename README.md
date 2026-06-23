# FFmpegKit (community rebuild)

> A community-maintained rebuild of [`arthenica/ffmpeg-kit`](https://github.com/arthenica/ffmpeg-kit) for **Android** and **iOS**.

## About

The original [`ffmpeg-kit`](https://github.com/arthenica/ffmpeg-kit) by Arthenica has been **officially retired** — the project is no longer maintained and all of its previously released prebuilt binaries are being removed from the package registries.

Because our applications still depend on it, this repository **rebuilds and republishes** the binaries so they remain installable.

A few important notes:

- **No GPL builds.** To avoid `GPL` licensing obligations, no `GPL`-licensed libraries (e.g. `x264`, `x265`, `xvidcore`, `vid.stab`) are enabled and no `-gpl` packages are published. Everything here is built under `LGPL v3.0`.
- **FFmpeg version.** Currently built against **FFmpeg up to v6**.
- **Platforms.** Only **Android** and **iOS** are supported and published.

## Usage

Replace `min` with whichever package (`min`, `https`, `audio`, `video`, `full`) you need.
For the full API (running commands, sessions, callbacks, FFprobe, etc.) see the per-platform guides:

- **Android API usage** → [`android/README.md`](android/README.md)
- **iOS API usage** → [`apple/README.md`](apple/README.md)

### iOS (CocoaPods)

```ruby
# Podfile
pod 'ffmpeg-mobile-min', '~> 6.0'
# pod 'ffmpeg-mobile-https', '~> 6.0'
# pod 'ffmpeg-mobile-audio', '~> 6.0'
# pod 'ffmpeg-mobile-video', '~> 6.0'
# pod 'ffmpeg-mobile-full',  '~> 6.0'
```

See [`apple/README.md`](apple/README.md) for the iOS API.

### Android (Gradle)

Published to Maven Central under the `io.github.maitrungduc1410` group.

```groovy
dependencies {
    implementation 'io.github.maitrungduc1410:ffmpeg-kit-min:6.0.1'
    // implementation 'io.github.maitrungduc1410:ffmpeg-kit-https:6.0.1'
    // implementation 'io.github.maitrungduc1410:ffmpeg-kit-audio:6.0.1'
    // implementation 'io.github.maitrungduc1410:ffmpeg-kit-video:6.0.1'
    // implementation 'io.github.maitrungduc1410:ffmpeg-kit-full:6.0.1'
}
```

See [`android/README.md`](android/README.md) for the Android API.

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