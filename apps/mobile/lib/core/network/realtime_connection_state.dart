/// Realtime stream connection lifecycle state for WariVerse AI.
enum RealtimeConnectionState {
  live,
  reconnecting,
  offline,
  lastKnown,
}

extension RealtimeConnectionStateX on RealtimeConnectionState {
  String get label {
    switch (this) {
      case RealtimeConnectionState.live:
        return 'LIVE';
      case RealtimeConnectionState.reconnecting:
        return 'RECONNECTING';
      case RealtimeConnectionState.offline:
        return 'OFFLINE';
      case RealtimeConnectionState.lastKnown:
        return 'LAST KNOWN';
    }
  }
}
