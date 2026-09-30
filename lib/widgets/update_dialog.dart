import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';

import '../app_info.dart';
import '../services/update_service.dart';

/// El navegador descarga el APK; al abrirlo, Android lo instala encima.
Future<bool> openUpdateDownload(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final download = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.system_update_outlined),
      title: Text(l10n.updateDialogTitle(info.version)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.updateDialogBody(AppInfo.version)),
            if (info.notes != null && info.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(info.notes!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.updateLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.updateDownload),
        ),
      ],
    ),
  );
  if (download == true && !await openUpdateDownload(info.downloadUrl)) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.updateOpenError)));
  }
}
