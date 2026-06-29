require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "RNFfmpegkit"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/maitrungduc1410/ffmpeg-kit.git", :tag => "react-native-#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift,cpp}"
  s.private_header_files = "ios/**/*.h"

  # FFmpegKit native binary variant. Defaults to "https"; override at `pod install`
  # time with e.g. FFMPEGKIT_PACKAGE=full to pull a different prebuilt package.
  # Available: min, https, audio, video, full (published as ffmpeg-mobile-<variant>).
  ffmpegkit_package = ENV["FFMPEGKIT_PACKAGE"] || "https"
  # FFmpegKit native version. Defaults to this package's version (package.json),
  # so iOS matches the installed @mtd1410/react-native-ffmpegkit release. Override
  # at `pod install` time with e.g. FFMPEGKIT_VERSION=6.0.6 to pin another version.
  ffmpegkit_version = ENV["FFMPEGKIT_VERSION"] || s.version.to_s
  s.dependency "ffmpeg-mobile-#{ffmpegkit_package}", "~> #{ffmpegkit_version}"

  install_modules_dependencies(s)
end
