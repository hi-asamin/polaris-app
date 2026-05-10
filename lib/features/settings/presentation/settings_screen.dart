import 'package:flutter/material.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
            title: Text(l.settingsAbout),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(
              Icons.numbers_rounded,
              color: scheme.onSurfaceVariant,
            ),
            title: Text(l.settingsVersion),
            trailing: Text(
              '0.1.0',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: Icon(
              Icons.download_outlined,
              color: scheme.onSurfaceVariant,
            ),
            title: Text(l.settingsDataExport),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.gavel_outlined, color: scheme.onSurfaceVariant),
            title: Text(l.settingsLicense),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
