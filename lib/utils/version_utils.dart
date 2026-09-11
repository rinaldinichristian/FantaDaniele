class VersionUtils {
  static bool isNewerVersion(String remote, String local) {
    try {
      final remoteClean = remote.split('+')[0];
      final localClean = local.split('+')[0];

      final remoteParts = remoteClean.split('.').map(int.parse).toList();
      final localParts = localClean.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final r = i < remoteParts.length ? remoteParts[i] : 0;
        final l = i < localParts.length ? localParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
    } catch (_) {}
    return false;
  }
}
