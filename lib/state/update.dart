import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Public repo whose GitHub releases carry every APK.
const kReleasesRepo = 'hawraz93/girfan';

class AppVersion {
  final String name; // 1.0.0
  final int build; // versionCode
  const AppVersion(this.name, this.build);
  String get label => '$name ($build)';
}

class UpdateInfo {
  final int build;
  final String tag;
  final String apkUrl;
  const UpdateInfo({required this.build, required this.tag, required this.apkUrl});
}

final appVersionProvider = FutureProvider<AppVersion>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppVersion(info.version, int.tryParse(info.buildNumber) ?? 0);
});

/// Build number at the end of a tag such as "v1.0.0-build12".
int? buildFromTag(String tag) {
  final m = RegExp(r'(\d+)$').firstMatch(tag);
  return m == null ? null : int.parse(m.group(1)!);
}

/// Bump to check again (pull-to-refresh, settings button).
final updateCheckTick = StateProvider<int>((_) => 0);

/// A newer release than the installed one, or null. Never throws: being
/// offline or rate-limited just means no banner.
final updateProvider = FutureProvider<UpdateInfo?>((ref) async {
  ref.watch(updateCheckTick);
  if (!Platform.isAndroid) return null;
  try {
    final current = await ref.watch(appVersionProvider.future);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client
          .getUrl(Uri.parse('https://api.github.com/repos/$kReleasesRepo/releases/latest'));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      req.headers.set(HttpHeaders.userAgentHeader, 'girfan-app');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String? ?? '';
      final build = buildFromTag(tag);
      if (build == null || build <= current.build) return null;
      final assets = (json['assets'] as List?) ?? const [];
      final apk = assets
          .cast<Map<String, dynamic>>()
          .where((a) => (a['name'] as String? ?? '').endsWith('.apk'))
          .firstOrNull;
      final url = apk?['browser_download_url'] as String?;
      if (url == null) return null;
      return UpdateInfo(build: build, tag: tag, apkUrl: url);
    } finally {
      client.close(force: true);
    }
  } catch (_) {
    return null;
  }
});
