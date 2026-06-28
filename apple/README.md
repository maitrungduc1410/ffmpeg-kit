# FFmpegKit for iOS — API Usage

This page covers how to use `FFmpegKit` in an iOS app. For the list of packages,
licensing and platform support, see the [project README](../README.md).

## Installation

Add the `FFmpegKit` dependency to your `Podfile`:

```ruby
pod 'ffmpeg-mobile-full', '~> 7.1.5'
```

Replace `ffmpeg-mobile-full` with the package you need: `ffmpeg-mobile-min`, `ffmpeg-mobile-https`,
`ffmpeg-mobile-audio`, `ffmpeg-mobile-video` or `ffmpeg-mobile-full`.

## API

1. Execute synchronous `FFmpeg` commands.

    ```objectivec
    #include <ffmpegkit/FFmpegKit.h>

    FFmpegSession *session = [FFmpegKit execute:@"-i file1.mp4 -c:v mpeg4 file2.mp4"];
    ReturnCode *returnCode = [session getReturnCode];
    if ([ReturnCode isSuccess:returnCode]) {

        // SUCCESS

    } else if ([ReturnCode isCancel:returnCode]) {

        // CANCEL

    } else {

        // FAILURE
        NSLog(@"Command failed with state %@ and rc %@.%@", [FFmpegKitConfig sessionStateToString:[session getState]], returnCode, [session getFailStackTrace]);

    }
    ```

2. Each `execute` call (sync or async) creates a new session. Access every detail about your execution from the
   session created.

    ```objectivec
    FFmpegSession *session = [FFmpegKit execute:@"-i file1.mp4 -c:v mpeg4 file2.mp4"];

    // Unique session id created for this execution
    long sessionId = [session getSessionId];

    // Command arguments as a single string
    NSString *command = [session getCommand];

    // Command arguments
    NSArray *arguments = [session getArguments];

    // State of the execution. Shows whether it is still running or completed
    SessionState state = [session getState];

    // Return code for completed sessions. Will be null if session is still running or ends with a failure
    ReturnCode *returnCode = [session getReturnCode];

    NSDate *startTime =[session getStartTime];
    NSDate *endTime =[session getEndTime];
    long duration =[session getDuration];

    // Console output generated for this execution
    NSString *output = [session getOutput];

    // The stack trace if FFmpegKit fails to run a command
    NSString *failStackTrace = [session getFailStackTrace];

    // The list of logs generated for this execution
    NSArray *logs = [session getLogs];

    // The list of statistics generated for this execution
    NSArray *statistics = [session getStatistics];
    ```

3. Execute asynchronous `FFmpeg` commands by providing session specific `execute`/`log`/`session` callbacks.

    ```objectivec
    FFmpegSession* session = [FFmpegKit executeAsync:@"-i file1.mp4 -c:v mpeg4 file2.mp4" withCompleteCallback:^(FFmpegSession* session){
        SessionState state = [session getState];
        ReturnCode *returnCode = [session getReturnCode];

        // CALLED WHEN SESSION IS EXECUTED

        NSLog(@"FFmpeg process exited with state %@ and rc %@.%@", [FFmpegKitConfig sessionStateToString:state], returnCode, [session getFailStackTrace]);

    } withLogCallback:^(Log *log) {

        // CALLED WHEN SESSION PRINTS LOGS

    } withStatisticsCallback:^(Statistics *statistics) {

        // CALLED WHEN SESSION GENERATES STATISTICS

    }];
    ```

4. Execute `FFprobe` commands.

    - Synchronous

    ```objectivec
    FFprobeSession *session = [FFprobeKit execute:ffprobeCommand];

    if ([ReturnCode isSuccess:[session getReturnCode]]) {
        NSLog(@"Command failed. Please check output for the details.");
    }
    ```

   - Asynchronous

    ```objectivec
    [FFprobeKit executeAsync:ffmpegCommand withCompleteCallback:^(FFprobeSession* session) {

        CALLED WHEN SESSION IS EXECUTED

    }];
    ```

5. Get media information for a file.

    ```objectivec
    MediaInformationSession *mediaInformation = [FFprobeKit getMediaInformation:"<file path or uri>"];
    MediaInformation *mediaInformation =[mediaInformation getMediaInformation];
    ```

6. Stop ongoing `FFmpeg` operations.

   - Stop all executions
       ```objectivec
       [FFmpegKit cancel];
       ```
   - Stop a specific session
       ```objectivec
       [FFmpegKit cancel:sessionId];
       ```

7. Get previous `FFmpeg` and `FFprobe` sessions from session history.

    ```objectivec
    NSArray* sessions = [FFmpegKitConfig getSessions];
    for (int i = 0; i < [sessions count]; i++) {
        id<Session> session = [sessions objectAtIndex:i];
        NSLog(@"Session %d = id: %ld, startTime: %@, duration: %ld, state:%@, returnCode:%@.\n",
            i,
            [session getSessionId],
            [session getStartTime],
            [session getDuration],
            [FFmpegKitConfig sessionStateToString:[session getState]],
            [session getReturnCode]);
    }
    ```

8. Enable global callbacks.

    - Session type specific Complete Callbacks, called when an async session has been completed

        ```objectivec
        [FFmpegKitConfig enableFFmpegSessionCompleteCallback:^(FFmpegSession* session) {
            ...
        }];

        [FFmpegKitConfig enableFFprobeSessionCompleteCallback:^(FFprobeSession* session) {
            ...
        }];

        [FFmpegKitConfig enableMediaInformationSessionCompleteCallback:^(MediaInformationSession* session) {
            ...
        }];
        ```

    - Log Callback, called when a session generates logs

        ```objectivec
        [FFmpegKitConfig enableLogCallback:^(Log *log) {
            ...
        }];
        ```

    - Statistics Callback, called when a session generates statistics

        ```objectivec
        [FFmpegKitConfig enableStatisticsCallback:^(Statistics *statistics) {
            ...
        }];
        ```

9. Ignore the handling of a signal. Required by `Mono` and frameworks that use `Mono`, e.g. `Unity` and `Xamarin`.

    ```objectivec
    [FFmpegKitConfig ignoreSignal:SIGXCPU];
    ```

10. Register system fonts and custom font directories.

    ```objectivec
    [FFmpegKitConfig setFontDirectoryList:[NSArray arrayWithObjects:@"/System/Library/Fonts", @"<folder with fonts>", nil] with:nil];
    ```