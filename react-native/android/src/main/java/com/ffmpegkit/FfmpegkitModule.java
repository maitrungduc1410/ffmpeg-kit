/*
 * Copyright (c) 2021-2022 Taner Sener
 *
 * This file is part of FFmpegKit.
 *
 * FFmpegKit is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FFmpegKit is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with FFmpegKit.  If not, see <http://www.gnu.org/licenses/>.
 */

package com.ffmpegkit;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.arthenica.ffmpegkit.AbiDetect;
import com.arthenica.ffmpegkit.AbstractSession;
import com.arthenica.ffmpegkit.FFmpegKit;
import com.arthenica.ffmpegkit.FFmpegKitConfig;
import com.arthenica.ffmpegkit.FFmpegSession;
import com.arthenica.ffmpegkit.FFprobeKit;
import com.arthenica.ffmpegkit.FFprobeSession;
import com.arthenica.ffmpegkit.Level;
import com.arthenica.ffmpegkit.LogRedirectionStrategy;
import com.arthenica.ffmpegkit.MediaInformation;
import com.arthenica.ffmpegkit.MediaInformationJsonParser;
import com.arthenica.ffmpegkit.MediaInformationSession;
import com.arthenica.ffmpegkit.Packages;
import com.arthenica.ffmpegkit.ReturnCode;
import com.arthenica.ffmpegkit.Session;
import com.arthenica.ffmpegkit.SessionState;
import com.arthenica.ffmpegkit.Signal;
import com.arthenica.ffmpegkit.Statistics;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

public class FfmpegkitModule extends NativeFfmpegkitSpec {
  public static final String NAME = "Ffmpegkit";
  public static final String LIBRARY_NAME = "ffmpeg-kit-react-native";
  public static final String PLATFORM_NAME = "android";

  // LOG CLASS
  public static final String KEY_LOG_SESSION_ID = "sessionId";
  public static final String KEY_LOG_LEVEL = "level";
  public static final String KEY_LOG_MESSAGE = "message";

  // STATISTICS CLASS
  public static final String KEY_STATISTICS_SESSION_ID = "sessionId";
  public static final String KEY_STATISTICS_VIDEO_FRAME_NUMBER = "videoFrameNumber";
  public static final String KEY_STATISTICS_VIDEO_FPS = "videoFps";
  public static final String KEY_STATISTICS_VIDEO_QUALITY = "videoQuality";
  public static final String KEY_STATISTICS_SIZE = "size";
  public static final String KEY_STATISTICS_TIME = "time";
  public static final String KEY_STATISTICS_BITRATE = "bitrate";
  public static final String KEY_STATISTICS_SPEED = "speed";

  // SESSION CLASS
  public static final String KEY_SESSION_ID = "sessionId";
  public static final String KEY_SESSION_CREATE_TIME = "createTime";
  public static final String KEY_SESSION_START_TIME = "startTime";
  public static final String KEY_SESSION_COMMAND = "command";
  public static final String KEY_SESSION_TYPE = "type";
  public static final String KEY_SESSION_MEDIA_INFORMATION = "mediaInformation";

  // SESSION TYPE
  public static final int SESSION_TYPE_FFMPEG = 1;
  public static final int SESSION_TYPE_FFPROBE = 2;
  public static final int SESSION_TYPE_MEDIA_INFORMATION = 3;

  // EVENTS
  public static final String EVENT_LOG_CALLBACK_EVENT = "FFmpegKitLogCallbackEvent";
  public static final String EVENT_STATISTICS_CALLBACK_EVENT = "FFmpegKitStatisticsCallbackEvent";
  public static final String EVENT_COMPLETE_CALLBACK_EVENT = "FFmpegKitCompleteCallbackEvent";

  // REQUEST CODES
  public static final int READABLE_REQUEST_CODE = 10000;
  public static final int WRITABLE_REQUEST_CODE = 20000;

  private static final int asyncWriteToPipeConcurrencyLimit = 10;

  private final AtomicBoolean logsEnabled;
  private final AtomicBoolean statisticsEnabled;
  private final ExecutorService asyncExecutorService;

  public FfmpegkitModule(@Nullable ReactApplicationContext reactContext) {
    super(reactContext);

    this.logsEnabled = new AtomicBoolean(false);
    this.statisticsEnabled = new AtomicBoolean(false);
    this.asyncExecutorService = Executors.newFixedThreadPool(asyncWriteToPipeConcurrencyLimit);

    registerGlobalCallbacks();
  }

  @NonNull
  @Override
  public String getName() {
    return NAME;
  }

  protected void registerGlobalCallbacks() {
    FFmpegKitConfig.enableFFmpegSessionCompleteCallback(session -> emitOnFFmpegKitCompleteCallbackEvent(toMap(session)));

    FFmpegKitConfig.enableFFprobeSessionCompleteCallback(session -> emitOnFFmpegKitCompleteCallbackEvent(toMap(session)));

    FFmpegKitConfig.enableMediaInformationSessionCompleteCallback(session -> emitOnFFmpegKitCompleteCallbackEvent(toMap(session)));

    FFmpegKitConfig.enableLogCallback(log -> {
      if (logsEnabled.get()) {
        emitOnFFmpegKitLogCallbackEvent(toMap(log));
      }
    });

    FFmpegKitConfig.enableStatisticsCallback(statistics -> {
      if (statisticsEnabled.get()) {
        emitOnFFmpegKitStatisticsCallbackEvent(toMap(statistics));
      }
    });
  }

  // AbstractSession

  @Override
  public void abstractSessionGetEndTime(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      final Date endTime = session.getEndTime();
      if (endTime == null) {
        promise.resolve(null);
      } else {
        promise.resolve((double) endTime.getTime());
      }
    }
  }

  @Override
  public void abstractSessionGetDuration(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      promise.resolve((double) session.getDuration());
    }
  }

  @Override
  public void abstractSessionGetAllLogs(final double sessionId, final double waitTimeout, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      final int timeout;
      if (isValidPositiveNumber(waitTimeout)) {
        timeout = (int) waitTimeout;
      } else {
        timeout = AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT;
      }
      final List<com.arthenica.ffmpegkit.Log> allLogs = session.getAllLogs(timeout);
      promise.resolve(toLogArray(allLogs));
    }
  }

  @Override
  public void abstractSessionGetLogs(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      final List<com.arthenica.ffmpegkit.Log> allLogs = session.getLogs();
      promise.resolve(toLogArray(allLogs));
    }
  }

  @Override
  public void abstractSessionGetAllLogsAsString(final double sessionId, final double waitTimeout, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      final int timeout;
      if (isValidPositiveNumber(waitTimeout)) {
        timeout = (int) waitTimeout;
      } else {
        timeout = AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT;
      }
      final String allLogsAsString = session.getAllLogsAsString(timeout);
      promise.resolve(allLogsAsString);
    }
  }

  @Override
  public void abstractSessionGetState(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      promise.resolve(session.getState().ordinal());
    }
  }

  @Override
  public void abstractSessionGetReturnCode(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      final ReturnCode returnCode = session.getReturnCode();
      if (returnCode == null) {
        promise.resolve(null);
      } else {
        promise.resolve(returnCode.getValue());
      }
    }
  }

  @Override
  public void abstractSessionGetFailStackTrace(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      promise.resolve(session.getFailStackTrace());
    }
  }

  @Override
  public void abstractSessionThereAreAsynchronousMessagesInTransmit(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      promise.resolve(session.thereAreAsynchronousMessagesInTransmit());
    }
  }

  // ArchDetect

  @Override
  public void getArch(final Promise promise) {
    promise.resolve(AbiDetect.getAbi());
  }

  // FFmpegSession

  @Override
  public void ffmpegSession(final ReadableArray readableArray, final Promise promise) {
    promise.resolve(toMap(FFmpegSession.create(toArgumentsArray(readableArray), null, null, null, LogRedirectionStrategy.NEVER_PRINT_LOGS)));
  }

  @Override
  public void ffmpegSessionGetAllStatistics(final double sessionId, final double waitTimeout, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      if (session.isFFmpeg()) {
        final int timeout;
        if (isValidPositiveNumber(waitTimeout)) {
          timeout = (int) waitTimeout;
        } else {
          timeout = AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT;
        }
        final List<Statistics> allStatistics = ((FFmpegSession) session).getAllStatistics(timeout);
        promise.resolve(toStatisticsArray(allStatistics));
      } else {
        promise.reject("NOT_FFMPEG_SESSION", "A session is found but it does not have the correct type.");
      }
    }
  }

  @Override
  public void ffmpegSessionGetStatistics(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      if (session.isFFmpeg()) {
        final List<Statistics> statistics = ((FFmpegSession) session).getStatistics();
        promise.resolve(toStatisticsArray(statistics));
      } else {
        promise.reject("NOT_FFMPEG_SESSION", "A session is found but it does not have the correct type.");
      }
    }
  }

  // FFprobeSession

  @Override
  public void ffprobeSession(final ReadableArray readableArray, final Promise promise) {
    promise.resolve(toMap(FFprobeSession.create(toArgumentsArray(readableArray), null, null, LogRedirectionStrategy.NEVER_PRINT_LOGS)));
  }

  // MediaInformationSession

  @Override
  public void mediaInformationSession(final ReadableArray readableArray, final Promise promise) {
    promise.resolve(toMap(MediaInformationSession.create(toArgumentsArray(readableArray), null, null)));
  }

  @Override
  public void getMediaInformation(final double sessionId, final Promise promise) {
    final Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      if (session.isMediaInformation()) {
        final MediaInformationSession mediaInformationSession = (MediaInformationSession) session;
        final MediaInformation mediaInformation = mediaInformationSession.getMediaInformation();
        if (mediaInformation != null) {
          promise.resolve(toMap(mediaInformation));
        } else {
          promise.resolve(null);
        }
      } else {
        promise.reject("NOT_MEDIA_INFORMATION_SESSION", "A session is found but it does not have the correct type.");
      }
    }
  }

  // MediaInformationJsonParser

  @Override
  public void mediaInformationJsonParserFrom(final String ffprobeJsonOutput, final Promise promise) {
    try {
      final MediaInformation mediaInformation = MediaInformationJsonParser.fromWithError(ffprobeJsonOutput);
      promise.resolve(toMap(mediaInformation));
    } catch (JSONException e) {
      Log.i(LIBRARY_NAME, "Parsing MediaInformation failed.", e);
      promise.resolve(null);
    }
  }

  // FFmpegKitConfig

  @Override
  public void enableRedirection(final Promise promise) {
    enableLogs();
    enableStatistics();
    FFmpegKitConfig.enableRedirection();
    promise.resolve(null);
  }

  @Override
  public void disableRedirection(final Promise promise) {
    FFmpegKitConfig.disableRedirection();
    promise.resolve(null);
  }

  @Override
  public void enableLogs(final Promise promise) {
    enableLogs();
    promise.resolve(null);
  }

  @Override
  public void disableLogs(final Promise promise) {
    disableLogs();
    promise.resolve(null);
  }

  @Override
  public void enableStatistics(final Promise promise) {
    enableStatistics();
    promise.resolve(null);
  }

  @Override
  public void disableStatistics(final Promise promise) {
    disableStatistics();
    promise.resolve(null);
  }

  @Override
  public void setFontconfigConfigurationPath(final String path, final Promise promise) {
    FFmpegKitConfig.setFontconfigConfigurationPath(path);
    promise.resolve(null);
  }

  @Override
  public void setFontDirectory(final String fontDirectoryPath, final ReadableMap fontNameMap, final Promise promise) {
    final ReactApplicationContext reactContext = getReactApplicationContext();
    if (reactContext != null) {
      FFmpegKitConfig.setFontDirectory(reactContext, fontDirectoryPath, toMap(fontNameMap));
      promise.resolve(null);
    } else {
      promise.reject("INVALID_CONTEXT", "React context is not initialized.");
    }
  }

  @Override
  public void setFontDirectoryList(final ReadableArray readableArray, final ReadableMap fontNameMap, final Promise promise) {
    final ReactApplicationContext reactContext = getReactApplicationContext();
    if (reactContext != null) {
      FFmpegKitConfig.setFontDirectoryList(reactContext, Arrays.asList(toArgumentsArray(readableArray)), toMap(fontNameMap));
      promise.resolve(null);
    } else {
      promise.reject("INVALID_CONTEXT", "React context is not initialized.");
    }
  }

  @Override
  public void registerNewFFmpegPipe(final Promise promise) {
    final ReactApplicationContext reactContext = getReactApplicationContext();
    if (reactContext != null) {
      promise.resolve(FFmpegKitConfig.registerNewFFmpegPipe(reactContext));
    } else {
      promise.reject("INVALID_CONTEXT", "React context is not initialized.");
    }
  }

  @Override
  public void closeFFmpegPipe(final String ffmpegPipePath, final Promise promise) {
    FFmpegKitConfig.closeFFmpegPipe(ffmpegPipePath);
    promise.resolve(null);
  }

  @Override
  public void getFFmpegVersion(final Promise promise) {
    promise.resolve(FFmpegKitConfig.getFFmpegVersion());
  }

  @Override
  public void isLTSBuild(final Promise promise) {
    promise.resolve(FFmpegKitConfig.isLTSBuild());
  }

  @Override
  public void getBuildDate(final Promise promise) {
    promise.resolve(FFmpegKitConfig.getBuildDate());
  }

  @Override
  public void setEnvironmentVariable(final String variableName, final String variableValue, final Promise promise) {
    FFmpegKitConfig.setEnvironmentVariable(variableName, variableValue);
    promise.resolve(null);
  }

  @Override
  public void ignoreSignal(final double signalValue, final Promise promise) {
    Signal signal = null;

    if ((int) signalValue == Signal.SIGINT.getValue()) {
      signal = Signal.SIGINT;
    } else if ((int) signalValue == Signal.SIGQUIT.getValue()) {
      signal = Signal.SIGQUIT;
    } else if ((int) signalValue == Signal.SIGPIPE.getValue()) {
      signal = Signal.SIGPIPE;
    } else if ((int) signalValue == Signal.SIGTERM.getValue()) {
      signal = Signal.SIGTERM;
    } else if ((int) signalValue == Signal.SIGXCPU.getValue()) {
      signal = Signal.SIGXCPU;
    }

    if (signal != null) {
      FFmpegKitConfig.ignoreSignal(signal);
      promise.resolve(null);
    } else {
      promise.reject("INVALID_SIGNAL", "Signal value not supported.");
    }
  }

  @Override
  public void ffmpegSessionExecute(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      if (session.isFFmpeg()) {
        final FFmpegSessionExecuteTask ffmpegSessionExecuteTask = new FFmpegSessionExecuteTask((FFmpegSession) session, promise);
        asyncExecutorService.submit(ffmpegSessionExecuteTask);
      } else {
        promise.reject("NOT_FFMPEG_SESSION", "A session is found but it does not have the correct type.");
      }
    }
  }

  @Override
  public void ffprobeSessionExecute(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      if (session.isFFprobe()) {
        final FFprobeSessionExecuteTask ffprobeSessionExecuteTask = new FFprobeSessionExecuteTask((FFprobeSession) session, promise);
        asyncExecutorService.submit(ffprobeSessionExecuteTask);
      } else {
        promise.reject("NOT_FFPROBE_SESSION", "A session is found but it does not have the correct type.");
      }
    }
  }

  @Override
  public void mediaInformationSessionExecute(final double sessionId, final double waitTimeout, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      if (session.isMediaInformation()) {
        final int timeout;
        if (isValidPositiveNumber(waitTimeout)) {
          timeout = (int) waitTimeout;
        } else {
          timeout = AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT;
        }
        final MediaInformationSessionExecuteTask mediaInformationSessionExecuteTask = new MediaInformationSessionExecuteTask((MediaInformationSession) session, timeout, promise);
        asyncExecutorService.submit(mediaInformationSessionExecuteTask);
      } else {
        promise.reject("NOT_MEDIA_INFORMATION_SESSION", "A session is found but it does not have the correct type.");
      }
    }
  }

  @Override
  public void asyncFFmpegSessionExecute(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      if (session.isFFmpeg()) {
        FFmpegKitConfig.asyncFFmpegExecute((FFmpegSession) session);
        promise.resolve(null);
      } else {
        promise.reject("NOT_FFMPEG_SESSION", "A session is found but it does not have the correct type.");
      }
    }
  }

  @Override
  public void asyncFFprobeSessionExecute(final double sessionId, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      if (session.isFFprobe()) {
        FFmpegKitConfig.asyncFFprobeExecute((FFprobeSession) session);
        promise.resolve(null);
      } else {
        promise.reject("NOT_FFPROBE_SESSION", "A session is found but it does not have the correct type.");
      }
    }
  }

  @Override
  public void asyncMediaInformationSessionExecute(final double sessionId, final double waitTimeout, final Promise promise) {
    Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      if (session.isMediaInformation()) {
        final int timeout;
        if (isValidPositiveNumber(waitTimeout)) {
          timeout = (int) waitTimeout;
        } else {
          timeout = AbstractSession.DEFAULT_TIMEOUT_FOR_ASYNCHRONOUS_MESSAGES_IN_TRANSMIT;
        }
        FFmpegKitConfig.asyncGetMediaInformationExecute((MediaInformationSession) session, timeout);
        promise.resolve(null);
      } else {
        promise.reject("NOT_MEDIA_INFORMATION_SESSION", "A session is found but it does not have the correct type.");
      }
    }
  }

  @Override
  public void getLogLevel(final Promise promise) {
    promise.resolve(toInt(FFmpegKitConfig.getLogLevel()));
  }

  @Override
  public void setLogLevel(final double level, final Promise promise) {
    FFmpegKitConfig.setLogLevel(Level.from((int) level));
    promise.resolve(null);
  }

  @Override
  public void getSessionHistorySize(final Promise promise) {
    promise.resolve(FFmpegKitConfig.getSessionHistorySize());
  }

  @Override
  public void setSessionHistorySize(final double sessionHistorySize, final Promise promise) {
    FFmpegKitConfig.setSessionHistorySize((int) sessionHistorySize);
    promise.resolve(null);
  }

  @Override
  public void getSession(final double sessionId, final Promise promise) {
    final Session session = FFmpegKitConfig.getSession((long) sessionId);
    if (session == null) {
      promise.reject("SESSION_NOT_FOUND", "Session not found.");
    } else {
      promise.resolve(toMap(session));
    }
  }

  @Override
  public void getLastSession(final Promise promise) {
    final Session session = FFmpegKitConfig.getLastSession();
    promise.resolve(toMap(session));
  }

  @Override
  public void getLastCompletedSession(final Promise promise) {
    final Session session = FFmpegKitConfig.getLastCompletedSession();
    promise.resolve(toMap(session));
  }

  @Override
  public void getSessions(final Promise promise) {
    promise.resolve(toSessionArray(FFmpegKitConfig.getSessions()));
  }

  @Override
  public void clearSessions(final Promise promise) {
    FFmpegKitConfig.clearSessions();
    promise.resolve(null);
  }

  @Override
  public void getSessionsByState(final double sessionState, final Promise promise) {
    promise.resolve(toSessionArray(FFmpegKitConfig.getSessionsByState(toSessionState((int) sessionState))));
  }

  @Override
  public void messagesInTransmit(final double sessionId, final Promise promise) {
    promise.resolve(FFmpegKitConfig.messagesInTransmit((long) sessionId));
  }

  @Override
  public void getPlatform(final Promise promise) {
    promise.resolve(PLATFORM_NAME);
  }

  @Override
  public void writeToPipe(final String inputPath, final String namedPipePath, final Promise promise) {
    final WriteToPipeTask asyncTask = new WriteToPipeTask(inputPath, namedPipePath, promise);
    asyncExecutorService.submit(asyncTask);
  }

  @Override
  public void selectDocument(final boolean writable, final String title, final String type, final ReadableArray extraTypes, final Promise promise) {
    final ReactApplicationContext reactContext = getReactApplicationContext();

    final Intent intent;
    if (writable) {
      intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
      intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
    } else {
      intent = new Intent(Intent.ACTION_GET_CONTENT);
      intent.addCategory(Intent.CATEGORY_OPENABLE);
      intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
    }

    if (type != null) {
      intent.setType(type);
    } else {
      intent.setType("*/*");
    }

    if (title != null) {
      intent.putExtra(Intent.EXTRA_TITLE, title);
    }

    if (extraTypes != null) {
      intent.putExtra(Intent.EXTRA_MIME_TYPES, toArgumentsArray(extraTypes));
    }

    if (reactContext != null) {
      final Activity currentActivity = reactContext.getCurrentActivity();

      if (currentActivity != null) {
        reactContext.addActivityEventListener(new BaseActivityEventListener() {

          @Override
          public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            reactContext.removeActivityEventListener(this);

            Log.d(LIBRARY_NAME, String.format("selectDocument using parameters writable: %s, type: %s, title: %s and extra types: %s completed with requestCode: %d, resultCode: %d, data: %s.", writable, type, title, extraTypes == null ? null : Arrays.toString(toArgumentsArray(extraTypes)), requestCode, resultCode, data == null ? null : data.toString()));

            if (requestCode == READABLE_REQUEST_CODE || requestCode == WRITABLE_REQUEST_CODE) {
              if (resultCode == Activity.RESULT_OK) {
                if (data == null) {
                  promise.resolve(null);
                } else {
                  final Uri uri = data.getData();
                  promise.resolve(uri == null ? null : uri.toString());
                }
              } else {
                promise.reject("SELECT_CANCELLED", String.valueOf(resultCode));
              }
            } else {
              super.onActivityResult(activity, requestCode, resultCode, data);
            }
          }
        });

        try {
          currentActivity.startActivityForResult(intent, writable ? WRITABLE_REQUEST_CODE : READABLE_REQUEST_CODE);
        } catch (final Exception e) {
          Log.i(LIBRARY_NAME, String.format("Failed to selectDocument using parameters writable: %s, type: %s, title: %s and extra types: %s!", writable, type, title, extraTypes == null ? null : Arrays.toString(toArgumentsArray(extraTypes))), e);
          promise.reject("SELECT_FAILED", e.getMessage());
        }
      } else {
        Log.w(LIBRARY_NAME, String.format("Cannot selectDocument using parameters writable: %s, type: %s, title: %s and extra types: %s. Current activity is null.", writable, type, title, extraTypes == null ? null : Arrays.toString(toArgumentsArray(extraTypes))));
        promise.reject("INVALID_ACTIVITY", "Activity is null.");
      }
    } else {
      Log.w(LIBRARY_NAME, String.format("Cannot selectDocument using parameters writable: %s, type: %s, title: %s and extra types: %s. React context is null.", writable, type, title, extraTypes == null ? null : Arrays.toString(toArgumentsArray(extraTypes))));
      promise.reject("INVALID_CONTEXT", "Context is null.");
    }
  }

  @Override
  public void getSafParameter(final String uriString, final String openMode, final Promise promise) {
    final ReactApplicationContext reactContext = getReactApplicationContext();

    final Uri uri = Uri.parse(uriString);
    if (uri == null) {
      Log.w(LIBRARY_NAME, String.format("Cannot getSafParameter using parameters uriString: %s, openMode: %s. Uri string cannot be parsed.", uriString, openMode));
      promise.reject("GET_SAF_PARAMETER_FAILED", "Uri string cannot be parsed.");
    } else {
      final String safParameter = FFmpegKitConfig.getSafParameter(reactContext, uri, openMode);
      Log.d(LIBRARY_NAME, String.format("getSafParameter using parameters uriString: %s, openMode: %s completed with saf parameter: %s.", uriString, openMode, safParameter));
      promise.resolve(safParameter);
    }
  }

  // FFmpegKit

  @Override
  public void cancel(final Promise promise) {
    FFmpegKit.cancel();
    promise.resolve(null);
  }

  @Override
  public void cancelSession(final double sessionId, final Promise promise) {
    FFmpegKit.cancel((long) sessionId);
    promise.resolve(null);
  }

  @Override
  public void getFFmpegSessions(final Promise promise) {
    promise.resolve(toSessionArray(FFmpegKit.listSessions()));
  }

  // FFprobeKit

  @Override
  public void getFFprobeSessions(final Promise promise) {
    promise.resolve(toSessionArray(FFprobeKit.listFFprobeSessions()));
  }

  @Override
  public void getMediaInformationSessions(final Promise promise) {
    promise.resolve(toSessionArray(FFprobeKit.listMediaInformationSessions()));
  }

  // Packages

  @Override
  public void getPackageName(final Promise promise) {
    promise.resolve(Packages.getPackageName());
  }

  @Override
  public void getExternalLibraries(final Promise promise) {
    promise.resolve(toStringArray(Packages.getExternalLibraries()));
  }

  @Override
  public void uninit(final Promise promise) {
    this.asyncExecutorService.shutdown();
    promise.resolve(null);
  }

  // Helpers

  protected void enableLogs() {
    logsEnabled.compareAndSet(false, true);
  }

  protected void disableLogs() {
    logsEnabled.compareAndSet(true, false);
  }

  protected void enableStatistics() {
    statisticsEnabled.compareAndSet(false, true);
  }

  protected void disableStatistics() {
    statisticsEnabled.compareAndSet(true, false);
  }

  protected static int toInt(final Level level) {
    return (level == null) ? Level.AV_LOG_TRACE.getValue() : level.getValue();
  }

  protected static WritableMap toMap(final Session session) {
    if (session == null) {
      return null;
    }

    final WritableMap sessionMap = Arguments.createMap();

    sessionMap.putDouble(KEY_SESSION_ID, session.getSessionId());
    sessionMap.putDouble(KEY_SESSION_CREATE_TIME, toLong(session.getCreateTime()));
    sessionMap.putDouble(KEY_SESSION_START_TIME, toLong(session.getStartTime()));
    sessionMap.putString(KEY_SESSION_COMMAND, session.getCommand());

    if (session.isFFmpeg()) {
      sessionMap.putDouble(KEY_SESSION_TYPE, SESSION_TYPE_FFMPEG);
    } else if (session.isFFprobe()) {
      sessionMap.putDouble(KEY_SESSION_TYPE, SESSION_TYPE_FFPROBE);
    } else if (session.isMediaInformation()) {
      final MediaInformationSession mediaInformationSession = (MediaInformationSession) session;
      final MediaInformation mediaInformation = mediaInformationSession.getMediaInformation();
      if (mediaInformation != null) {
        sessionMap.putMap(KEY_SESSION_MEDIA_INFORMATION, toMap(mediaInformation));
      }
      sessionMap.putDouble(KEY_SESSION_TYPE, SESSION_TYPE_MEDIA_INFORMATION);
    }

    return sessionMap;
  }

  protected static long toLong(final Date date) {
    if (date != null) {
      return date.getTime();
    } else {
      return 0;
    }
  }

  protected static SessionState toSessionState(final int value) {
    switch (value) {
      case 0:
        return SessionState.CREATED;
      case 1:
        return SessionState.RUNNING;
      case 2:
        return SessionState.FAILED;
      case 3:
      default:
        return SessionState.COMPLETED;
    }
  }

  protected static WritableArray toStringArray(final List<String> list) {
    final WritableArray array = Arguments.createArray();

    if (list != null) {
      for (String item : list) {
        array.pushString(item);
      }
    }

    return array;
  }

  protected static Map<String, String> toMap(final ReadableMap readableMap) {
    final Map<String, String> map = new HashMap<>();

    if (readableMap != null) {
      final ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
      while (iterator.hasNextKey()) {
        final String key = iterator.nextKey();
        final ReadableType type = readableMap.getType(key);

        if (type == ReadableType.String) {
          map.put(key, readableMap.getString(key));
        }
      }
    }

    return map;
  }

  protected static WritableMap toMap(final com.arthenica.ffmpegkit.Log log) {
    final WritableMap logMap = Arguments.createMap();

    logMap.putDouble(KEY_LOG_SESSION_ID, log.getSessionId());
    logMap.putDouble(KEY_LOG_LEVEL, toInt(log.getLevel()));
    logMap.putString(KEY_LOG_MESSAGE, log.getMessage());

    return logMap;
  }

  protected static WritableMap toMap(final Statistics statistics) {
    final WritableMap statisticsMap = Arguments.createMap();

    if (statistics != null) {
      statisticsMap.putDouble(KEY_STATISTICS_SESSION_ID, statistics.getSessionId());
      statisticsMap.putDouble(KEY_STATISTICS_VIDEO_FRAME_NUMBER, statistics.getVideoFrameNumber());
      statisticsMap.putDouble(KEY_STATISTICS_VIDEO_FPS, statistics.getVideoFps());
      statisticsMap.putDouble(KEY_STATISTICS_VIDEO_QUALITY, statistics.getVideoQuality());
      statisticsMap.putDouble(KEY_STATISTICS_SIZE, statistics.getSize());
      statisticsMap.putDouble(KEY_STATISTICS_TIME, statistics.getTime());
      statisticsMap.putDouble(KEY_STATISTICS_BITRATE, statistics.getBitrate());
      statisticsMap.putDouble(KEY_STATISTICS_SPEED, statistics.getSpeed());
    }

    return statisticsMap;
  }

  protected static WritableMap toMap(final MediaInformation mediaInformation) {
    if (mediaInformation != null) {
      WritableMap map = Arguments.createMap();

      JSONObject allProperties = mediaInformation.getAllProperties();
      if (allProperties != null) {
        map = toMap(allProperties);
      }

      return map;
    } else {
      return null;
    }
  }

  protected static WritableMap toMap(final JSONObject jsonObject) {
    final WritableMap map = Arguments.createMap();

    if (jsonObject != null) {
      Iterator<String> keys = jsonObject.keys();
      while (keys.hasNext()) {
        String key = keys.next();
        Object value = jsonObject.opt(key);
        if (value != null) {
          if (value instanceof JSONArray) {
            map.putArray(key, toList((JSONArray) value));
          } else if (value instanceof JSONObject) {
            map.putMap(key, toMap((JSONObject) value));
          } else if (value instanceof String) {
            map.putString(key, (String) value);
          } else if (value instanceof Number) {
            if (value instanceof Integer) {
              map.putInt(key, (Integer) value);
            } else {
              map.putDouble(key, ((Number) value).doubleValue());
            }
          } else if (value instanceof Boolean) {
            map.putBoolean(key, (Boolean) value);
          } else {
            Log.i(LIBRARY_NAME, String.format("Cannot map json key %s using value %s:%s", key, value.toString(), value.getClass().toString()));
          }
        }
      }
    }

    return map;
  }

  protected static WritableArray toList(final JSONArray array) {
    final WritableArray list = Arguments.createArray();

    for (int i = 0; i < array.length(); i++) {
      Object value = array.opt(i);
      if (value != null) {
        if (value instanceof JSONArray) {
          list.pushArray(toList((JSONArray) value));
        } else if (value instanceof JSONObject) {
          list.pushMap(toMap((JSONObject) value));
        } else if (value instanceof String) {
          list.pushString((String) value);
        } else if (value instanceof Number) {
          if (value instanceof Integer) {
            list.pushInt((Integer) value);
          } else {
            list.pushDouble(((Number) value).doubleValue());
          }
        } else if (value instanceof Boolean) {
          list.pushBoolean((Boolean) value);
        } else {
          Log.i(LIBRARY_NAME, String.format("Cannot map json value %s:%s", value.toString(), value.getClass().toString()));
        }
      }
    }

    return list;
  }

  protected static String[] toArgumentsArray(final ReadableArray readableArray) {
    final List<String> arguments = new ArrayList<>();
    for (int i = 0; i < readableArray.size(); i++) {
      final ReadableType type = readableArray.getType(i);

      if (type == ReadableType.String) {
        arguments.add(readableArray.getString(i));
      }
    }

    return arguments.toArray(new String[0]);
  }

  protected static WritableArray toSessionArray(final List<? extends Session> sessionList) {
    final WritableArray sessionArray = Arguments.createArray();

    for (int i = 0; i < sessionList.size(); i++) {
      sessionArray.pushMap(toMap(sessionList.get(i)));
    }

    return sessionArray;
  }

  protected static WritableArray toLogArray(final List<com.arthenica.ffmpegkit.Log> logList) {
    final WritableArray logArray = Arguments.createArray();

    for (int i = 0; i < logList.size(); i++) {
      logArray.pushMap(toMap(logList.get(i)));
    }

    return logArray;
  }

  protected static WritableArray toStatisticsArray(final List<com.arthenica.ffmpegkit.Statistics> statisticsList) {
    final WritableArray statisticsArray = Arguments.createArray();

    for (int i = 0; i < statisticsList.size(); i++) {
      statisticsArray.pushMap(toMap(statisticsList.get(i)));
    }

    return statisticsArray;
  }

  protected static boolean isValidPositiveNumber(final double value) {
    return (value >= 0);
  }

}
