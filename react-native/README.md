# @mtd1410/ffmpegkit

FFmpegKit for React Native, built for the **New Architecture** (TurboModule + Codegen).

It wraps the prebuilt FFmpegKit native binaries:

- **Android** — Maven Central: `io.github.maitrungduc1410:ffmpeg-kit-<variant>:7.1.5`
- **iOS** — CocoaPods: `ffmpeg-mobile-<variant>` (`~> 7.1.5`)

Available variants: `min`, `https` (default), `audio`, `video`, `full`.

## Installation

```sh
npm install @mtd1410/ffmpegkit
```

This package requires React Native 0.76+ with the New Architecture enabled.

### Selecting a package variant

The default native variant is `https`. To use a different one:

**Android** — set the variant (and optionally the version) in your app's `android/build.gradle`:

```gradle
ext {
  ffmpegKitPackage = "full"   // min | https | audio | video | full
  ffmpegKitVersion = "7.1.5"
}
```

**iOS** — set the `FFMPEGKIT_PACKAGE` environment variable when installing pods:

```sh
cd ios && FFMPEGKIT_PACKAGE=full pod install
```

## Usage

1. Execute FFmpeg commands.

    ```js
    import { FFmpegKit, ReturnCode } from '@mtd1410/ffmpegkit';

    FFmpegKit.execute('-i file1.mp4 -c:v mpeg4 file2.mp4').then(async (session) => {
      const returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {

        // SUCCESS

      } else if (ReturnCode.isCancel(returnCode)) {

        // CANCEL

      } else {

        // ERROR

      }
    });
    ```

2. Each `execute` call creates a new session. Access every detail about your execution from the
   session created.

    ```js
    FFmpegKit.execute('-i file1.mp4 -c:v mpeg4 file2.mp4').then(async (session) => {

      // Unique session id created for this execution
      const sessionId = session.getSessionId();

      // Command arguments as a single string
      const command = session.getCommand();

      // Command arguments
      const commandArguments = session.getArguments();

      // State of the execution. Shows whether it is still running or completed
      const state = await session.getState();

      // Return code for completed sessions. Will be undefined if session is still running or FFmpegKit fails to run it
      const returnCode = await session.getReturnCode();

      const startTime = session.getStartTime();
      const endTime = await session.getEndTime();
      const duration = await session.getDuration();

      // Console output generated for this execution
      const output = await session.getOutput();

      // The stack trace if FFmpegKit fails to run a command
      const failStackTrace = await session.getFailStackTrace();

      // The list of logs generated for this execution
      const logs = await session.getLogs();

      // The list of statistics generated for this execution (only available on FFmpegSession)
      const statistics = await session.getStatistics();

    });
    ```

3. Execute `FFmpeg` commands by providing session specific `execute`/`log`/`session` callbacks.

    ```js
    FFmpegKit.executeAsync('-i file1.mp4 -c:v mpeg4 file2.mp4', session => {

      // CALLED WHEN SESSION IS EXECUTED

    }, log => {

      // CALLED WHEN SESSION PRINTS LOGS

    }, statistics => {

      // CALLED WHEN SESSION GENERATES STATISTICS

    });
    ```

4. Execute `FFprobe` commands.

    ```js
    import { FFprobeKit } from '@mtd1410/ffmpegkit';

    FFprobeKit.execute(ffprobeCommand).then(async (session) => {

      // CALLED WHEN SESSION IS EXECUTED

    });
    ```

5. Get media information for a file/url.

    ```js
    import { FFprobeKit, FFmpegKitConfig } from '@mtd1410/ffmpegkit';

    FFprobeKit.getMediaInformation(testUrl).then(async (session) => {
      const information = await session.getMediaInformation();

      if (information === undefined) {

        // CHECK THE FOLLOWING ATTRIBUTES ON ERROR
        const state = FFmpegKitConfig.sessionStateToString(await session.getState());
        const returnCode = await session.getReturnCode();
        const failStackTrace = await session.getFailStackTrace();
        const duration = await session.getDuration();
        const output = await session.getOutput();
      }
    });
    ```

6. Stop ongoing FFmpeg operations.

  - Stop all sessions
    ```js
    FFmpegKit.cancel();
    ```
  - Stop a specific session
    ```js
    FFmpegKit.cancel(sessionId);
    ```

7. (Android) Convert Storage Access Framework (SAF) Uris into paths that can be read or written by
`FFmpegKit` and `FFprobeKit`.

  - Reading a file:
    ```js
    FFmpegKitConfig.selectDocumentForRead('*/*').then(uri => {
        FFmpegKitConfig.getSafParameterForRead(uri).then(safUrl => {
            FFmpegKit.executeAsync(`-i ${safUrl} -c:v mpeg4 file2.mp4`);
        });
    });
    ```

  - Writing to a file:
    ```js
    FFmpegKitConfig.selectDocumentForWrite('video.mp4', 'video/*').then(uri => {
        FFmpegKitConfig.getSafParameterForWrite(uri).then(safUrl => {
            FFmpegKit.executeAsync(`-i file1.mp4 -c:v mpeg4 ${safUrl}`);
        });
    });
    ```

8. Get previous `FFmpeg`, `FFprobe` and `MediaInformation` sessions from the session history.

    ```js
    FFmpegKit.listSessions().then(sessionList => {
      sessionList.forEach(async session => {
        const sessionId = session.getSessionId();
      });
    });

    FFprobeKit.listFFprobeSessions().then(sessionList => {
      sessionList.forEach(async session => {
        const sessionId = session.getSessionId();
      });
    });

    FFprobeKit.listMediaInformationSessions().then(sessionList => {
      sessionList.forEach(async session => {
        const sessionId = session.getSessionId();
      });
    });
    ```

9. Enable global callbacks.

  - Session type specific Complete Callbacks, called when an async session has been completed

    ```js
    FFmpegKitConfig.enableFFmpegSessionCompleteCallback(session => {
      const sessionId = session.getSessionId();
    });

    FFmpegKitConfig.enableFFprobeSessionCompleteCallback(session => {
      const sessionId = session.getSessionId();
    });

    FFmpegKitConfig.enableMediaInformationSessionCompleteCallback(session => {
      const sessionId = session.getSessionId();
    });
    ```

  - Log Callback, called when a session generates logs

    ```js
    FFmpegKitConfig.enableLogCallback(log => {
      const message = log.getMessage();
    });
    ```

  - Statistics Callback, called when a session generates statistics

    ```js
    FFmpegKitConfig.enableStatisticsCallback(statistics => {
      const size = statistics.getSize();
    });
    ```

10. Register system fonts and custom font directories.

    ```js
    FFmpegKitConfig.setFontDirectoryList(["/system/fonts", "/System/Library/Fonts", "<folder with fonts>"]);
    ```

See the [Android](../android/README.md) and [Apple](../apple/README.md) READMEs for
the full FFmpegKit API reference (the JavaScript API mirrors the native one).

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

LGPL-3.0-or-later (same as FFmpegKit, no GPL libraries are bundled).

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
