#import <FfmpegkitSpec/FfmpegkitSpec.h>

// Inherits from the codegen-generated SpecBase (instead of NSObject) so the
// generated emitOn...Event methods are available for delivering FFmpegKit's
// global log / statistics / complete callbacks to JavaScript.
@interface RNFfmpegkit : NativeFfmpegkitSpecBase <NativeFfmpegkitSpec>

@end
