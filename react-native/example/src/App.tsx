import { useEffect, useState } from 'react';
import { Text, View, StyleSheet } from 'react-native';
import { FFmpegKitConfig } from '@mtd1410/react-native-ffmpegkit';

export default function App() {
  const [version, setVersion] = useState<string>('loading…');

  useEffect(() => {
    FFmpegKitConfig.getFFmpegVersion()
      .then(setVersion)
      .catch((error: unknown) => setVersion(`error: ${String(error)}`));
  }, []);

  return (
    <View style={styles.container}>
      <Text>FFmpeg version: {version}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
