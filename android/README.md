# FFmpegKit for Android — API Usage

This page covers how to use `FFmpegKit` in an Android app. For the list of packages,
licensing and platform support, see the [project README](../README.md).

## Installation

Declare `mavenCentral` and add the `FFmpegKit` dependency to your `build.gradle`:

```groovy
repositories {
    mavenCentral()
}

dependencies {
    implementation 'io.github.maitrungduc1410:ffmpeg-kit-full:6.0.1'
}
```

Replace `ffmpeg-kit-full` with the package you need: `ffmpeg-kit-min`, `ffmpeg-kit-https`,
`ffmpeg-kit-audio`, `ffmpeg-kit-video` or `ffmpeg-kit-full`.

## API

1. Execute synchronous `FFmpeg` commands.

    ```java
    import com.arthenica.ffmpegkit.FFmpegKit;

    FFmpegSession session = FFmpegKit.execute("-i file1.mp4 -c:v mpeg4 file2.mp4");
    if (ReturnCode.isSuccess(session.getReturnCode())) {

        // SUCCESS

    } else if (ReturnCode.isCancel(session.getReturnCode())) {

        // CANCEL

    } else {

        // FAILURE
        Log.d(TAG, String.format("Command failed with state %s and rc %s.%s", session.getState(), session.getReturnCode(), session.getFailStackTrace()));

    }
    ```

2. Each `execute` call (sync or async) creates a new session. Access every detail about your execution from the
   session created.

    ```java
    FFmpegSession session = FFmpegKit.execute("-i file1.mp4 -c:v mpeg4 file2.mp4");

    // Unique session id created for this execution
    long sessionId = session.getSessionId();

    // Command arguments as a single string
    String command = session.getCommand();

    // Command arguments
    String[] arguments = session.getArguments();

    // State of the execution. Shows whether it is still running or completed
    SessionState state = session.getState();

    // Return code for completed sessions. Will be null if session is still running or ends with a failure
    ReturnCode returnCode = session.getReturnCode();

    Date startTime = session.getStartTime();
    Date endTime = session.getEndTime();
    long duration = session.getDuration();

    // Console output generated for this execution
    String output = session.getOutput();

    // The stack trace if FFmpegKit fails to run a command
    String failStackTrace = session.getFailStackTrace();

    // The list of logs generated for this execution
    List<com.arthenica.ffmpegkit.Log> logs = session.getLogs();

    // The list of statistics generated for this execution
    List<Statistics> statistics = session.getStatistics();
    ```

3. Execute asynchronous `FFmpeg` commands by providing session specific `execute`/`log`/`session` callbacks.

    ```java
    FFmpegKit.executeAsync("-i file1.mp4 -c:v mpeg4 file2.mp4", new FFmpegSessionCompleteCallback() {

        @Override
        public void apply(FFmpegSession session) {
            SessionState state = session.getState();
            ReturnCode returnCode = session.getReturnCode();

            // CALLED WHEN SESSION IS EXECUTED

            Log.d(TAG, String.format("FFmpeg process exited with state %s and rc %s.%s", state, returnCode, session.getFailStackTrace()));
        }
    }, new LogCallback() {

        @Override
        public void apply(com.arthenica.ffmpegkit.Log log) {

            // CALLED WHEN SESSION PRINTS LOGS

        }
    }, new StatisticsCallback() {

        @Override
        public void apply(Statistics statistics) {

            // CALLED WHEN SESSION GENERATES STATISTICS

        }
    });
    ```

4. Execute `FFprobe` commands.

    - Synchronous

    ```java
    FFprobeSession session = FFprobeKit.execute(ffprobeCommand);

    if (!ReturnCode.isSuccess(session.getReturnCode())) {
        Log.d(TAG, "Command failed. Please check output for the details.");
    }
    ```

    - Asynchronous

    ```java
    FFprobeKit.executeAsync(ffprobeCommand, new FFprobeSessionCompleteCallback() {

        @Override
        public void apply(FFprobeSession session) {

            CALLED WHEN SESSION IS EXECUTED

        }
    });
    ```

5. Get media information for a file.

    ```java
    MediaInformationSession mediaInformation = FFprobeKit.getMediaInformation("<file path or uri>");
    mediaInformation.getMediaInformation();
    ```

6. Stop ongoing `FFmpeg` operations.

    - Stop all executions
        ```java
        FFmpegKit.cancel();
        ```
    - Stop a specific session
        ```java
        FFmpegKit.cancel(sessionId);
        ```

7. Convert Storage Access Framework (SAF) Uris into paths that can be read or written by `FFmpegKit`.
   - Reading a file:

        ```java
        Uri safUri = intent.getData();
        String inputVideoPath = FFmpegKitConfig.getSafParameterForRead(requireContext(), safUri);
        FFmpegKit.execute("-i " + inputVideoPath + " -c:v mpeg4 file2.mp4");
        ```

    - Writing to a file:

        ```java
        Uri safUri = intent.getData();
        String outputVideoPath = FFmpegKitConfig.getSafParameterForWrite(requireContext(), safUri);
        FFmpegKit.execute("-i file1.mp4 -c:v mpeg4 " + outputVideoPath);
        ```

   - Writing to a file in a custom mode.

       ```java
       Uri safUri = intent.getData();
       String path = FFmpegKitConfig.getSafParameter(requireContext(), safUri, "rw");
       FFmpegKit.execute("-i file1.mp4 -c:v mpeg4 " + path);
       ```

8. Get previous `FFmpeg` and `FFprobe` sessions from session history.

    ```java
    List<Session> sessions = FFmpegKitConfig.getSessions();
    for (int i = 0; i < sessions.size(); i++) {
        Session session = sessions.get(i);
        Log.d(TAG, String.format("Session %d = id:%d, startTime:%s, duration:%s, state:%s, returnCode:%s.",
              i,
              session.getSessionId(),
              session.getStartTime(),
              session.getDuration(),
              session.getState(),
              session.getReturnCode()));
    }
    ```

9. Enable global callbacks.

    - Session type specific Complete Callbacks, called when an async session has been completed

        ```java
        FFmpegKitConfig.enableFFmpegSessionCompleteCallback(new FFmpegSessionCompleteCallback() {

            @Override
            public void apply(FFmpegSession session) {

            }
        });

        FFmpegKitConfig.enableFFprobeSessionCompleteCallback(new FFprobeSessionCompleteCallback() {

            @Override
            public void apply(FFprobeSession session) {

            }
        });

        FFmpegKitConfig.enableMediaInformationSessionCompleteCallback(new MediaInformationSessionCompleteCallback() {

            @Override
            public void apply(MediaInformationSession session) {

            }
        });
        ```

    - Log Callback, called when a session generates logs

        ```java
        FFmpegKitConfig.enableLogCallback(new LogCallback() {

            @Override
            public void apply(final com.arthenica.ffmpegkit.Log log) {
                ...
            }
        });
        ```

    - Statistics Callback, called when a session generates statistics

        ```java
        FFmpegKitConfig.enableStatisticsCallback(new StatisticsCallback() {

            @Override
            public void apply(final Statistics newStatistics) {
                ...
            }
        });
        ```

10. Ignore the handling of a signal. Required by `Mono` and frameworks that use `Mono`, e.g. `Unity` and `Xamarin`.

    ```java
    FFmpegKitConfig.ignoreSignal(Signal.SIGXCPU);
    ```

11. Register system fonts and custom font directories.

    ```java
    FFmpegKitConfig.setFontDirectoryList(context, Arrays.asList("/system/fonts", "<folder with fonts>"), Collections.EMPTY_MAP);
    ```