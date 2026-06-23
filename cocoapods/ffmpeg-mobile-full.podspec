# FFmpegKit iOS - "full" package (LGPL v3.0, no GPL libraries).
#
# The xcframeworks are NOT committed to git; they are published as assets on the
# GitHub Release tagged ios-<version> by the iOS build workflow. CocoaPods therefore
# downloads ONLY this variant's zip (no sibling variants, no git history).
#
# Publish:  POD_VERSION=6.0.2 pod trunk push cocoapods/ffmpeg-mobile-full.podspec
# (POD_VERSION must match the GitHub Release tag, e.g. release "ios-6.0.2".)
Pod::Spec.new do |s|
  s.name             = "ffmpeg-mobile-full"
  s.version          = ENV["POD_VERSION"] || "6.0.2"
  s.summary          = "FFmpegKit iOS xcframeworks (full package)"
  s.description      = "Prebuilt FFmpeg/FFmpegKit xcframeworks for iOS. Community rebuild of arthenica/ffmpeg-kit, built up to FFmpeg 6 under LGPL v3.0."
  s.homepage         = "https://github.com/maitrungduc1410/ffmpeg-kit"
  s.license          = { :type => "LGPL-3.0", :file => "LICENSE" }
  s.author           = { "Duc Trung Mai" => "maitrungduc1410@gmail.com" }
  s.platform         = :ios, "12.1"

  s.source = {
    :http => "https://github.com/maitrungduc1410/ffmpeg-kit/releases/download/ios-#{s.version}/ffmpeg-mobile-full.zip"
  }

  # Apple system frameworks the FFmpeg libraries link against (enabled in COMMON_FLAGS).
  s.frameworks = "AudioToolbox", "AVFoundation", "CoreMedia", "VideoToolbox"
  # System libraries enabled via --enable-ios-bzip2 / --enable-ios-zlib / --enable-ios-libiconv.
  s.libraries  = "z", "bz2", "iconv"

  s.vendored_frameworks = [
    "libswscale.xcframework",
    "libswresample.xcframework",
    "libavutil.xcframework",
    "libavformat.xcframework",
    "libavfilter.xcframework",
    "libavdevice.xcframework",
    "libavcodec.xcframework",
    "ffmpegkit.xcframework"
  ]
end
