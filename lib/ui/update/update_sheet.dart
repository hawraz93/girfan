import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/update.dart';
import '../widgets/widgets.dart';

Future<void> showUpdateSheet(BuildContext context, UpdateInfo info) => showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (_) => UpdateSheet(info: info),
    );

/// Downloads the new APK and hands it to Android's installer. Data is kept
/// because the APK is signed with the same key.
class UpdateSheet extends StatefulWidget {
  final UpdateInfo info;
  const UpdateSheet({super.key, required this.info});

  @override
  State<UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<UpdateSheet> {
  StreamSubscription<OtaEvent>? _sub;
  double? progress;
  String? status;
  bool error = false;
  bool running = false;

  void _start() {
    setState(() {
      running = true;
      error = false;
      progress = 0;
      status = S.updDownloading;
    });
    try {
      _sub = OtaUpdate()
          .execute(widget.info.apkUrl, destinationFilename: 'girfan-update.apk')
          .listen((e) {
        if (!mounted) return;
        setState(() {
          switch (e.status) {
            case OtaStatus.DOWNLOADING:
              progress = (double.tryParse(e.value ?? '') ?? 0) / 100;
              status = S.updDownloading;
            case OtaStatus.INSTALLING:
            case OtaStatus.INSTALLATION_DONE:
              progress = 1;
              status = S.updInstalling;
              running = false;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              _fail(S.updPermission);
            default:
              _fail('${S.updFailed} (${e.status.name})');
          }
        });
      }, onError: (Object _) {
        if (mounted) setState(() => _fail(S.updFailed));
      });
    } catch (_) {
      _fail(S.updFailed);
    }
  }

  void _fail(String msg) {
    error = true;
    running = false;
    status = msg;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 8),
            Center(child: CircleIcon(Icons.system_update_rounded, p.accent, size: 64)),
            const SizedBox(height: 14),
            Text(S.updTitle,
                textAlign: TextAlign.center,
                style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${S.updBuild} ${widget.info.build}',
                textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 13)),
            const SizedBox(height: 6),
            Text(S.updKeepsData,
                textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 12)),
            const SizedBox(height: 20),
            if (progress != null) ...[
              ProgressLine(progress!, error ? p.coral : p.accent),
              const SizedBox(height: 8),
              Text(
                status ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(color: error ? p.coral : p.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: running ? null : _start,
              child: Text(error ? S.updRetry : S.updNow),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: running ? null : () => Navigator.pop(context),
              child: const Text(S.updLater),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner on the home screen when a newer version is published.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(updateProvider).valueOrNull;
    if (info == null) return const SizedBox.shrink();
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        color: p.accent.withValues(alpha: 0.12),
        onTap: () => showUpdateSheet(context, info),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.system_update_rounded, color: p.accent),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(S.updTitle, style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            Text(S.updNow, style: TextStyle(color: p.accent, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
