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

#import "RNFfmpegkit.h"

#import <ffmpegkit/FFmpegKitConfig.h>
#import <ffmpegkit/FFmpegKit.h>
#import <ffmpegkit/FFprobeKit.h>
#import <ffmpegkit/ArchDetect.h>
#import <ffmpegkit/MediaInformation.h>
#import <ffmpegkit/Packages.h>

static NSString *const PLATFORM_NAME = @"ios";

// LOG CLASS
static NSString *const KEY_LOG_SESSION_ID = @"sessionId";
static NSString *const KEY_LOG_LEVEL = @"level";
static NSString *const KEY_LOG_MESSAGE = @"message";

// STATISTICS CLASS
static NSString *const KEY_STATISTICS_SESSION_ID = @"sessionId";
static NSString *const KEY_STATISTICS_VIDEO_FRAME_NUMBER = @"videoFrameNumber";
static NSString *const KEY_STATISTICS_VIDEO_FPS = @"videoFps";
static NSString *const KEY_STATISTICS_VIDEO_QUALITY = @"videoQuality";
static NSString *const KEY_STATISTICS_SIZE = @"size";
static NSString *const KEY_STATISTICS_TIME = @"time";
static NSString *const KEY_STATISTICS_BITRATE = @"bitrate";
static NSString *const KEY_STATISTICS_SPEED = @"speed";

// SESSION CLASS
static NSString *const KEY_SESSION_ID = @"sessionId";
static NSString *const KEY_SESSION_CREATE_TIME = @"createTime";
static NSString *const KEY_SESSION_START_TIME = @"startTime";
static NSString *const KEY_SESSION_COMMAND = @"command";
static NSString *const KEY_SESSION_TYPE = @"type";
static NSString *const KEY_SESSION_MEDIA_INFORMATION = @"mediaInformation";

// SESSION TYPE
static int const SESSION_TYPE_FFMPEG = 1;
static int const SESSION_TYPE_FFPROBE = 2;
static int const SESSION_TYPE_MEDIA_INFORMATION = 3;

extern int const AbstractSessionDefaultTimeoutForAsynchronousMessagesInTransmit;

@implementation RNFfmpegkit {
  BOOL logsEnabled;
  BOOL statisticsEnabled;
  dispatch_queue_t asyncDispatchQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        logsEnabled = false;
        statisticsEnabled = false;
        asyncDispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

        [self registerGlobalCallbacks];
    }

    return self;
}

- (void)registerGlobalCallbacks {
  [FFmpegKitConfig enableFFmpegSessionCompleteCallback:^(FFmpegSession* session){
    [self emitOnFFmpegKitCompleteCallbackEvent:[RNFfmpegkit toSessionDictionary:session]];
  }];

  [FFmpegKitConfig enableFFprobeSessionCompleteCallback:^(FFprobeSession* session){
    [self emitOnFFmpegKitCompleteCallbackEvent:[RNFfmpegkit toSessionDictionary:session]];
  }];

  [FFmpegKitConfig enableMediaInformationSessionCompleteCallback:^(MediaInformationSession* session){
    [self emitOnFFmpegKitCompleteCallbackEvent:[RNFfmpegkit toSessionDictionary:session]];
  }];

  [FFmpegKitConfig enableLogCallback: ^(Log* log){
    if (self->logsEnabled) {
      [self emitOnFFmpegKitLogCallbackEvent:[RNFfmpegkit toLogDictionary:log]];
    }
  }];

  [FFmpegKitConfig enableStatisticsCallback:^(Statistics* statistics){
    if (self->statisticsEnabled) {
      [self emitOnFFmpegKitStatisticsCallbackEvent:[RNFfmpegkit toStatisticsDictionary:statistics]];
    }
  }];
}

// AbstractSession

- (void)abstractSessionGetEndTime:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
      NSDate* endTime = [session getEndTime];
      if (endTime == nil) {
        resolve(nil);
      } else {
        resolve([NSNumber numberWithDouble:[endTime timeIntervalSince1970]*1000]);
      }
    }
}

- (void)abstractSessionGetDuration:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
      resolve([NSNumber numberWithLong:[session getDuration]]);
    }
}

- (void)abstractSessionGetAllLogs:(double)sessionId waitTimeout:(double)waitTimeout resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
      int timeout;
      if ([RNFfmpegkit isValidPositiveNumber:waitTimeout]) {
        timeout = (int)waitTimeout;
      } else {
        timeout = AbstractSessionDefaultTimeoutForAsynchronousMessagesInTransmit;
      }
      NSArray* allLogs = [session getAllLogsWithTimeout:timeout];
      resolve([RNFfmpegkit toLogArray:allLogs]);
    }
}

- (void)abstractSessionGetLogs:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
      NSArray* logs = [session getLogs];
      resolve([RNFfmpegkit toLogArray:logs]);
    }
}

- (void)abstractSessionGetAllLogsAsString:(double)sessionId waitTimeout:(double)waitTimeout resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
      int timeout;
      if ([RNFfmpegkit isValidPositiveNumber:waitTimeout]) {
        timeout = (int)waitTimeout;
      } else {
        timeout = AbstractSessionDefaultTimeoutForAsynchronousMessagesInTransmit;
      }
      NSString* allLogsAsString = [session getAllLogsAsStringWithTimeout:timeout];
      resolve(allLogsAsString);
    }
}

- (void)abstractSessionGetState:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
      resolve([RNFfmpegkit sessionStateToNumber:[session getState]]);
    }
}

- (void)abstractSessionGetReturnCode:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
      ReturnCode* returnCode = [session getReturnCode];
      if (returnCode == nil) {
        resolve(nil);
      } else {
        resolve([NSNumber numberWithInt:[returnCode getValue]]);
      }
    }
}

- (void)abstractSessionGetFailStackTrace:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
      resolve([session getFailStackTrace]);
    }
}

- (void)abstractSessionThereAreAsynchronousMessagesInTransmit:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
      resolve([NSNumber numberWithBool:[session thereAreAsynchronousMessagesInTransmit]]);
    }
}

// ArchDetect

- (void)getArch:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([ArchDetect getArch]);
}

// FFmpegSession

- (void)ffmpegSession:(NSArray *)commandArguments resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    FFmpegSession* session = [FFmpegSession create:commandArguments withCompleteCallback:nil withLogCallback:nil withStatisticsCallback:nil withLogRedirectionStrategy:LogRedirectionStrategyNeverPrintLogs];
    resolve([RNFfmpegkit toSessionDictionary:session]);
}

- (void)ffmpegSessionGetAllStatistics:(double)sessionId waitTimeout:(double)waitTimeout resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        if ([session isFFmpeg]) {
            int timeout;
            if ([RNFfmpegkit isValidPositiveNumber:waitTimeout]) {
              timeout = (int)waitTimeout;
            } else {
              timeout = AbstractSessionDefaultTimeoutForAsynchronousMessagesInTransmit;
            }
            NSArray* allStatistics = [(FFmpegSession*)session getAllStatisticsWithTimeout:timeout];
            resolve([RNFfmpegkit toStatisticsArray:allStatistics]);
        } else {
            reject(@"NOT_FFMPEG_SESSION", @"A session is found but it does not have the correct type.", nil);
        }
    }
}

- (void)ffmpegSessionGetStatistics:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        if ([session isFFmpeg]) {
            NSArray* statistics = [(FFmpegSession*)session getStatistics];
            resolve([RNFfmpegkit toStatisticsArray:statistics]);
        } else {
            reject(@"NOT_FFMPEG_SESSION", @"A session is found but it does not have the correct type.", nil);
        }
    }
}

// FFprobeSession

- (void)ffprobeSession:(NSArray *)commandArguments resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    FFprobeSession* session = [FFprobeSession create:commandArguments withCompleteCallback:nil withLogCallback:nil withLogRedirectionStrategy:LogRedirectionStrategyNeverPrintLogs];
    resolve([RNFfmpegkit toSessionDictionary:session]);
}

// MediaInformationSession

- (void)mediaInformationSession:(NSArray *)commandArguments resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    MediaInformationSession* session = [MediaInformationSession create:commandArguments withCompleteCallback:nil withLogCallback:nil];
    resolve([RNFfmpegkit toSessionDictionary:session]);
}

- (void)getMediaInformation:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
        reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        if ([session isMediaInformation]) {
            MediaInformationSession *mediaInformationSession = (MediaInformationSession*)session;
            resolve([RNFfmpegkit toMediaInformationDictionary:[mediaInformationSession getMediaInformation]]);
        } else {
            reject(@"NOT_MEDIA_INFORMATION_SESSION", @"A session is found but it does not have the correct type.", nil);
        }
    }
}

// MediaInformationJsonParser

- (void)mediaInformationJsonParserFrom:(NSString *)ffprobeJsonOutput resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    @try {
        MediaInformation* mediaInformation = [MediaInformationJsonParser fromWithError:ffprobeJsonOutput];
        resolve([RNFfmpegkit toMediaInformationDictionary:mediaInformation]);
    } @catch (NSException *exception) {
        NSLog(@"Parsing MediaInformation failed: %@.\n", [NSString stringWithFormat:@"%@\n%@", [exception userInfo], [exception callStackSymbols]]);
        resolve(nil);
    }
}

// FFmpegKitConfig

- (void)enableRedirection:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [self enableLogs];
    [self enableStatistics];
    [FFmpegKitConfig enableRedirection];
    resolve(nil);
}

- (void)disableRedirection:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKitConfig disableRedirection];
    resolve(nil);
}

- (void)enableLogs:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [self enableLogs];
    resolve(nil);
}

- (void)disableLogs:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [self disableLogs];
    resolve(nil);
}

- (void)enableStatistics:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [self enableStatistics];
    resolve(nil);
}

- (void)disableStatistics:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [self disableStatistics];
    resolve(nil);
}

- (void)setFontconfigConfigurationPath:(NSString *)path resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKitConfig setFontconfigConfigurationPath:path];
    resolve(nil);
}

- (void)setFontDirectory:(NSString *)fontDirectoryPath fontNameMap:(NSDictionary *)fontNameMap resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKitConfig setFontDirectory:fontDirectoryPath with:fontNameMap];
    resolve(nil);
}

- (void)setFontDirectoryList:(NSArray *)fontDirectoryList fontNameMap:(NSDictionary *)fontNameMap resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKitConfig setFontDirectoryList:fontDirectoryList with:fontNameMap];
    resolve(nil);
}

- (void)registerNewFFmpegPipe:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([FFmpegKitConfig registerNewFFmpegPipe]);
}

- (void)closeFFmpegPipe:(NSString *)ffmpegPipePath resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKitConfig closeFFmpegPipe:ffmpegPipePath];
    resolve(nil);
}

- (void)getFFmpegVersion:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([FFmpegKitConfig getFFmpegVersion]);
}

- (void)isLTSBuild:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([NSNumber numberWithInt:[FFmpegKitConfig isLTSBuild]]);
}

- (void)getBuildDate:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([FFmpegKitConfig getBuildDate]);
}

- (void)setEnvironmentVariable:(NSString *)variableName variableValue:(NSString *)variableValue resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKitConfig setEnvironmentVariable:variableName value:variableValue];
    resolve(nil);
}

- (void)ignoreSignal:(double)signalValue resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    int signalValueInt = (int)signalValue;
    if ((signalValueInt == SignalInt) || (signalValueInt == SignalQuit) || (signalValueInt == SignalPipe) || (signalValueInt == SignalTerm) || (signalValueInt == SignalXcpu)) {
        resolve(nil);
    } else {
        reject(@"INVALID_SIGNAL", @"Signal value not supported.", nil);
    }
}

- (void)ffmpegSessionExecute:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        if ([session isFFmpeg]) {
            dispatch_async(asyncDispatchQueue, ^{
                [FFmpegKitConfig ffmpegExecute:(FFmpegSession*)session];
                resolve(nil);
            });
        } else {
            reject(@"NOT_FFMPEG_SESSION", @"A session is found but it does not have the correct type.", nil);
        }
    }
}

- (void)ffprobeSessionExecute:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        if ([session isFFprobe]) {
            dispatch_async(asyncDispatchQueue, ^{
                [FFmpegKitConfig ffprobeExecute:(FFprobeSession*)session];
                resolve(nil);
            });
        } else {
            reject(@"NOT_FFPROBE_SESSION", @"A session is found but it does not have the correct type.", nil);
        }
    }
}

- (void)mediaInformationSessionExecute:(double)sessionId waitTimeout:(double)waitTimeout resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        if ([session isMediaInformation]) {
            int timeout;
            if ([RNFfmpegkit isValidPositiveNumber:waitTimeout]) {
              timeout = (int)waitTimeout;
            } else {
              timeout = AbstractSessionDefaultTimeoutForAsynchronousMessagesInTransmit;
            }
            dispatch_async(asyncDispatchQueue, ^{
                [FFmpegKitConfig getMediaInformationExecute:(MediaInformationSession*)session withTimeout:timeout];
                resolve(nil);
            });
        } else {
            reject(@"NOT_MEDIA_INFORMATION_SESSION", @"A session is found but it does not have the correct type.", nil);
        }
    }
}

- (void)asyncFFmpegSessionExecute:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        if ([session isFFmpeg]) {
            [FFmpegKitConfig asyncFFmpegExecute:(FFmpegSession*)session];
            resolve(nil);
        } else {
            reject(@"NOT_FFMPEG_SESSION", @"A session is found but it does not have the correct type.", nil);
        }
    }
}

- (void)asyncFFprobeSessionExecute:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        if ([session isFFprobe]) {
            [FFmpegKitConfig asyncFFprobeExecute:(FFprobeSession*)session];
            resolve(nil);
        } else {
            reject(@"NOT_FFPROBE_SESSION", @"A session is found but it does not have the correct type.", nil);
        }
    }
}

- (void)asyncMediaInformationSessionExecute:(double)sessionId waitTimeout:(double)waitTimeout resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
      reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        if ([session isMediaInformation]) {
            int timeout;
            if ([RNFfmpegkit isValidPositiveNumber:waitTimeout]) {
              timeout = (int)waitTimeout;
            } else {
              timeout = AbstractSessionDefaultTimeoutForAsynchronousMessagesInTransmit;
            }
            [FFmpegKitConfig asyncGetMediaInformationExecute:(MediaInformationSession*)session withTimeout:timeout];
            resolve(nil);
        } else {
            reject(@"NOT_MEDIA_INFORMATION_SESSION", @"A session is found but it does not have the correct type.", nil);
        }
    }
}

- (void)getLogLevel:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([NSNumber numberWithInt:[FFmpegKitConfig getLogLevel]]);
}

- (void)setLogLevel:(double)level resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKitConfig setLogLevel:(int)level];
    resolve(nil);
}

- (void)getSessionHistorySize:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([NSNumber numberWithInt:[FFmpegKitConfig getSessionHistorySize]]);
}

- (void)setSessionHistorySize:(double)sessionHistorySize resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKitConfig setSessionHistorySize:(int)sessionHistorySize];
    resolve(nil);
}

- (void)getSession:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    AbstractSession* session = (AbstractSession*)[FFmpegKitConfig getSession:(long)sessionId];
    if (session == nil) {
        reject(@"SESSION_NOT_FOUND", @"Session not found.", nil);
    } else {
        resolve([RNFfmpegkit toSessionDictionary:session]);
    }
}

- (void)getLastSession:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([RNFfmpegkit toSessionDictionary:[FFmpegKitConfig getLastSession]]);
}

- (void)getLastCompletedSession:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([RNFfmpegkit toSessionDictionary:[FFmpegKitConfig getLastCompletedSession]]);
}

- (void)getSessions:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([RNFfmpegkit toSessionArray:[FFmpegKitConfig getSessions]]);
}

- (void)clearSessions:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKitConfig clearSessions];
    resolve(nil);
}

- (void)getSessionsByState:(double)sessionState resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([RNFfmpegkit toSessionArray:[FFmpegKitConfig getSessionsByState:(SessionState)(int)sessionState]]);
}

- (void)messagesInTransmit:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([NSNumber numberWithInt:[FFmpegKitConfig messagesInTransmit:(long)sessionId]]);
}

- (void)getPlatform:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve(PLATFORM_NAME);
}

- (void)writeToPipe:(NSString *)inputPath namedPipePath:(NSString *)namedPipePath resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    dispatch_async(asyncDispatchQueue, ^{

        NSLog(@"Starting copy %@ to pipe %@ operation.\n", inputPath, namedPipePath);

        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath: inputPath];
        if (fileHandle == nil) {
            NSLog(@"Failed to open file %@.\n", inputPath);
            reject(@"Copy failed", [NSString stringWithFormat:@"Failed to open file %@.", inputPath], nil);
            return;
        }

        NSFileHandle *pipeHandle = [NSFileHandle fileHandleForWritingAtPath: namedPipePath];
        if (pipeHandle == nil) {
            NSLog(@"Failed to open pipe %@.\n", namedPipePath);
            reject(@"Copy failed", [NSString stringWithFormat:@"Failed to open pipe %@.", namedPipePath], nil);
            [fileHandle closeFile];
            return;
        }

        int BUFFER_SIZE = 4096;
        unsigned long readBytes = 0;
        unsigned long totalBytes = 0;
        double startTime = CACurrentMediaTime();

        @try {
            [fileHandle seekToFileOffset: 0];

            do {
                NSData *data = [fileHandle readDataOfLength:BUFFER_SIZE];
                readBytes = [data length];
                if (readBytes > 0) {
                    totalBytes += readBytes;
                    [pipeHandle writeData:data];
                }
            } while (readBytes > 0);

            double endTime = CACurrentMediaTime();

            NSLog(@"Copying %@ to pipe %@ operation completed successfully. %lu bytes copied in %f seconds.\n", inputPath, namedPipePath, totalBytes, (endTime - startTime)/1000);

            resolve([NSNumber numberWithInt:0]);

        } @catch (NSException *e) {
            NSLog(@"Copy failed %@.\n", [e reason]);
            reject(@"Copy failed", [NSString stringWithFormat:@"Copy %@ to %@ failed with error %@.", inputPath, namedPipePath, [e reason]], nil);
        } @finally {
            [fileHandle closeFile];
            [pipeHandle closeFile];
        }
    });
}

- (void)selectDocument:(BOOL)writable title:(NSString *)title type:(NSString *)type extraTypes:(NSArray *)extraTypes resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    reject(@"Not Supported", @"Not supported on iOS platform.", nil);
}

- (void)getSafParameter:(NSString *)uriString openMode:(NSString *)openMode resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    reject(@"Not Supported", @"Not supported on iOS platform.", nil);
}

// FFmpegKit

- (void)cancel:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKit cancel];
    resolve(nil);
}

- (void)cancelSession:(double)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [FFmpegKit cancel:(long)sessionId];
    resolve(nil);
}

- (void)getFFmpegSessions:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([RNFfmpegkit toSessionArray:[FFmpegKit listSessions]]);
}

// FFprobeKit

- (void)getFFprobeSessions:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([RNFfmpegkit toSessionArray:[FFprobeKit listFFprobeSessions]]);
}

- (void)getMediaInformationSessions:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([RNFfmpegkit toSessionArray:[FFprobeKit listMediaInformationSessions]]);
}

// Packages

- (void)getPackageName:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([Packages getPackageName]);
}

- (void)getExternalLibraries:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([Packages getExternalLibraries]);
}

- (void)uninit:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve(nil);
}

// Helpers

- (void)enableLogs {
    logsEnabled = true;
}

- (void)disableLogs {
    logsEnabled = false;
}

- (void)enableStatistics {
    statisticsEnabled = true;
}

- (void)disableStatistics {
    statisticsEnabled = false;
}

+ (NSDictionary*)toSessionDictionary:(id<Session>) session {
    if (session != nil) {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

        dictionary[KEY_SESSION_ID] = [NSNumber numberWithLong: [session getSessionId]];
        dictionary[KEY_SESSION_CREATE_TIME] = [NSNumber numberWithDouble:[[session getCreateTime] timeIntervalSince1970]*1000];
        dictionary[KEY_SESSION_START_TIME] = [NSNumber numberWithDouble:[[session getStartTime] timeIntervalSince1970]*1000];
        dictionary[KEY_SESSION_COMMAND] = [session getCommand];

        if ([session isFFmpeg]) {
          dictionary[KEY_SESSION_TYPE] = [NSNumber numberWithInt:SESSION_TYPE_FFMPEG];
        } else if ([session isFFprobe]) {
          dictionary[KEY_SESSION_TYPE] = [NSNumber numberWithInt:SESSION_TYPE_FFPROBE];
        } else if ([session isMediaInformation]) {
          MediaInformationSession *mediaInformationSession = (MediaInformationSession*)session;
          dictionary[KEY_SESSION_MEDIA_INFORMATION] = [RNFfmpegkit toMediaInformationDictionary:[mediaInformationSession getMediaInformation]];
          dictionary[KEY_SESSION_TYPE] = [NSNumber numberWithInt:SESSION_TYPE_MEDIA_INFORMATION];
        }

        return dictionary;
    } else {
        return nil;
    }
}

+ (NSDictionary*)toLogDictionary:(Log*)log {
    if (log != nil) {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

        dictionary[KEY_LOG_SESSION_ID] = [NSNumber numberWithLong: [log getSessionId]];
        dictionary[KEY_LOG_LEVEL] = [NSNumber numberWithInt: [log getLevel]];
        dictionary[KEY_LOG_MESSAGE] = [log getMessage];

        return dictionary;
    } else {
        return nil;
    }
}

+ (NSDictionary*)toStatisticsDictionary:(Statistics*)statistics {
    if (statistics != nil) {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

        dictionary[KEY_STATISTICS_SESSION_ID] = [NSNumber numberWithLong: [statistics getSessionId]];
        dictionary[KEY_STATISTICS_VIDEO_FRAME_NUMBER] = [NSNumber numberWithInt: [statistics getVideoFrameNumber]];
        dictionary[KEY_STATISTICS_VIDEO_FPS] = [NSNumber numberWithFloat: [statistics getVideoFps]];
        dictionary[KEY_STATISTICS_VIDEO_QUALITY] = [NSNumber numberWithFloat: [statistics getVideoQuality]];
        dictionary[KEY_STATISTICS_SIZE] = [NSNumber numberWithLong: [statistics getSize]];
        dictionary[KEY_STATISTICS_TIME] = [NSNumber numberWithDouble: [statistics getTime]];
        dictionary[KEY_STATISTICS_BITRATE] = [NSNumber numberWithDouble: [statistics getBitrate]];
        dictionary[KEY_STATISTICS_SPEED] = [NSNumber numberWithDouble: [statistics getSpeed]];

        return dictionary;
    } else {
        return nil;
    }
}

+ (NSDictionary*)toMediaInformationDictionary:(MediaInformation*)mediaInformation {
    if (mediaInformation != nil) {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

        NSDictionary* allProperties = [mediaInformation getAllProperties];
        if (allProperties != nil) {
            for(NSString *key in [allProperties allKeys]) {
                dictionary[key] = [allProperties objectForKey:key];
            }
        }

        return dictionary;
    } else {
        return nil;
    }
}

+ (NSArray*)toLogArray:(NSArray*)logs {
    NSMutableArray *array = [[NSMutableArray alloc] init];

    for (int i = 0; i < [logs count]; i++) {
        Log* log = [logs objectAtIndex:i];
        [array addObject: [RNFfmpegkit toLogDictionary:log]];
    }

    return array;
}

+ (NSArray*)toStatisticsArray:(NSArray*)statisticsArray {
    NSMutableArray *array = [[NSMutableArray alloc] init];

    for (int i = 0; i < [statisticsArray count]; i++) {
        Statistics* statistics = [statisticsArray objectAtIndex:i];
        [array addObject: [RNFfmpegkit toStatisticsDictionary:statistics]];
    }

    return array;
}

+ (NSArray*)toSessionArray:(NSArray*)sessions {
    NSMutableArray *array = [[NSMutableArray alloc] init];

    for (int i = 0; i < [sessions count]; i++) {
        AbstractSession* session = (AbstractSession*)[sessions objectAtIndex:i];
        [array addObject: [RNFfmpegkit toSessionDictionary:session]];
    }

    return array;
}

+ (NSNumber*)sessionStateToNumber:(SessionState)sessionState {
  switch (sessionState) {
    case SessionStateCreated:
      return [NSNumber numberWithInt:0];
    case SessionStateRunning:
      return [NSNumber numberWithInt:1];
    case SessionStateFailed:
      return [NSNumber numberWithInt:2];
    case SessionStateCompleted:
    default:
      return [NSNumber numberWithInt:3];
  }
}

+ (BOOL)isValidPositiveNumber:(double)value {
    return (value >= 0);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeFfmpegkitSpecJSI>(params);
}

// Register the (RN-prefixed) class under the JS module name "Ffmpegkit".
// This both sets +moduleName and registers the class via RCTRegisterModule,
// which the renamed class would otherwise lack now that the ObjC class name
// no longer matches the module name used by TurboModuleRegistry.
RCT_EXPORT_MODULE(Ffmpegkit)

@end
