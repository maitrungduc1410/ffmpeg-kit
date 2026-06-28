import type { TurboModule, CodegenTypes } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

// Event payloads. These mirror the dictionaries emitted by the native side.
// `mediaInformation` on sessions is intentionally not modelled here: the JS
// layer only reads `sessionId` from the complete event and then re-fetches the
// full session (including media information) through `getSession`.
export type LogEvent = {
  sessionId: number;
  level: number;
  message: string;
};

export type StatisticsEvent = {
  sessionId: number;
  videoFrameNumber: number;
  videoFps: number;
  videoQuality: number;
  size: number;
  time: number;
  bitrate: number;
  speed: number;
};

export type SessionEvent = {
  sessionId: number;
};

export interface Spec extends TurboModule {
  // AbstractSession
  abstractSessionGetEndTime(sessionId: number): Promise<number>;
  abstractSessionGetDuration(sessionId: number): Promise<number>;
  abstractSessionGetAllLogs(
    sessionId: number,
    waitTimeout: number
  ): Promise<Object[]>;
  abstractSessionGetLogs(sessionId: number): Promise<Object[]>;
  abstractSessionGetAllLogsAsString(
    sessionId: number,
    waitTimeout: number
  ): Promise<string>;
  abstractSessionGetState(sessionId: number): Promise<number>;
  abstractSessionGetReturnCode(sessionId: number): Promise<number>;
  abstractSessionGetFailStackTrace(sessionId: number): Promise<string>;
  abstractSessionThereAreAsynchronousMessagesInTransmit(
    sessionId: number
  ): Promise<boolean>;

  // ArchDetect
  getArch(): Promise<string>;

  // FFmpegSession
  ffmpegSession(commandArguments: string[]): Promise<Object>;
  ffmpegSessionGetAllStatistics(
    sessionId: number,
    waitTimeout: number
  ): Promise<Object[]>;
  ffmpegSessionGetStatistics(sessionId: number): Promise<Object[]>;

  // FFprobeSession
  ffprobeSession(commandArguments: string[]): Promise<Object>;

  // MediaInformationSession
  mediaInformationSession(commandArguments: string[]): Promise<Object>;
  getMediaInformation(sessionId: number): Promise<Object>;

  // MediaInformationJsonParser
  mediaInformationJsonParserFrom(ffprobeJsonOutput: string): Promise<Object>;

  // FFmpegKitConfig
  enableRedirection(): Promise<void>;
  disableRedirection(): Promise<void>;
  enableLogs(): Promise<void>;
  disableLogs(): Promise<void>;
  enableStatistics(): Promise<void>;
  disableStatistics(): Promise<void>;
  setFontconfigConfigurationPath(path: string): Promise<void>;
  setFontDirectory(
    fontDirectoryPath: string,
    fontNameMap: Object
  ): Promise<void>;
  setFontDirectoryList(
    fontDirectoryList: string[],
    fontNameMap: Object
  ): Promise<void>;
  registerNewFFmpegPipe(): Promise<string>;
  closeFFmpegPipe(ffmpegPipePath: string): Promise<void>;
  getFFmpegVersion(): Promise<string>;
  isLTSBuild(): Promise<boolean>;
  getBuildDate(): Promise<string>;
  setEnvironmentVariable(
    variableName: string,
    variableValue: string
  ): Promise<void>;
  ignoreSignal(signalValue: number): Promise<void>;
  ffmpegSessionExecute(sessionId: number): Promise<void>;
  ffprobeSessionExecute(sessionId: number): Promise<void>;
  mediaInformationSessionExecute(
    sessionId: number,
    waitTimeout: number
  ): Promise<void>;
  asyncFFmpegSessionExecute(sessionId: number): Promise<void>;
  asyncFFprobeSessionExecute(sessionId: number): Promise<void>;
  asyncMediaInformationSessionExecute(
    sessionId: number,
    waitTimeout: number
  ): Promise<void>;
  getLogLevel(): Promise<number>;
  setLogLevel(level: number): Promise<void>;
  getSessionHistorySize(): Promise<number>;
  setSessionHistorySize(sessionHistorySize: number): Promise<void>;
  getSession(sessionId: number): Promise<Object>;
  getLastSession(): Promise<Object>;
  getLastCompletedSession(): Promise<Object>;
  getSessions(): Promise<Object[]>;
  clearSessions(): Promise<void>;
  getSessionsByState(sessionState: number): Promise<Object[]>;
  messagesInTransmit(sessionId: number): Promise<number>;
  getPlatform(): Promise<string>;
  writeToPipe(inputPath: string, namedPipePath: string): Promise<number>;
  selectDocument(
    writable: boolean,
    title: string,
    type: string,
    extraTypes: string[]
  ): Promise<string>;
  getSafParameter(uriString: string, openMode: string): Promise<string>;

  // FFmpegKit
  cancel(): Promise<void>;
  cancelSession(sessionId: number): Promise<void>;
  getFFmpegSessions(): Promise<Object[]>;

  // FFprobeKit
  getFFprobeSessions(): Promise<Object[]>;
  getMediaInformationSessions(): Promise<Object[]>;

  // Packages
  getPackageName(): Promise<string>;
  getExternalLibraries(): Promise<string[]>;

  uninit(): Promise<void>;

  // Events (global FFmpegKit callbacks bridged to JS)
  readonly onFFmpegKitLogCallbackEvent: CodegenTypes.EventEmitter<LogEvent>;
  readonly onFFmpegKitStatisticsCallbackEvent: CodegenTypes.EventEmitter<StatisticsEvent>;
  readonly onFFmpegKitCompleteCallbackEvent: CodegenTypes.EventEmitter<SessionEvent>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Ffmpegkit');
