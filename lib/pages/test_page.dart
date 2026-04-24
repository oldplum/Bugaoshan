import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/providers/app_info_provider.dart';
import 'package:bugaoshan/utils/open_link.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _versionInfoProvider = getIt<AppInfoProvider>();
  String? _latestVersion;
  bool _checkingUpdate = false;
  String? _updateError;

  bool get _isWindowsOrLinux => Platform.isWindows || Platform.isLinux;

  Future<void> _checkForUpdates() async {
    if (!_isWindowsOrLinux) return;
    setState(() {
      _checkingUpdate = true;
      _updateError = null;
    });

    try {
      final latest = await _getLatestVersionFromGitHub();
      setState(() {
        _latestVersion = latest;
        _checkingUpdate = false;
      });
    } catch (e) {
      setState(() {
        _updateError = e.toString();
        _checkingUpdate = false;
      });
    }
  }

  Future<String> _getLatestVersionFromGitHub() async {
    const repo = 'The-Brotherhood-of-SCU/Bugaoshan';
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
      headers: {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('GitHub API returned empty response');
      }
      final tagName = RegExp(
        r'"tag_name":\s*"([^"]+)"',
      ).firstMatch(response.body)?.group(1);
      if (tagName != null) {
        return tagName.replaceFirst('v', '');
      }
      throw Exception('Could not parse release tag from response');
    }
    throw Exception('GitHub API error: ${response.statusCode}');
  }

  String _getBinaryUrl(String version) {
    final platform = Platform.isWindows ? 'windows' : 'linux';
    return 'https://github.com/The-Brotherhood-of-SCU/Bugaoshan/releases/download/v$version/bugaoshan_${version}_${platform}_x64.zip';
  }

  Future<void> _downloadAndInstall(String version) async {
    final url = _getBinaryUrl(version);
    await openLink(url);
  }

  void _showUpdateDialog(String latestVersion) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update_alt),
            const SizedBox(width: 8),
            Text(localizations.newVersionAvailable),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('${localizations.version}: $latestVersion')],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.neverMind),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(latestVersion);
            },
            child: Text(localizations.goToReleases),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.testPage)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: localizations.environmentInfo),
            const SizedBox(height: 12),
            _EnvironmentInfoButton(
              onPressed: () => _showEnvironmentInfoDialog(context),
            ),
            const SizedBox(height: 32),
            if (_isWindowsOrLinux) ...[
              _SectionTitle(title: localizations.forceUpdate),
              const SizedBox(height: 12),
              _UpdateCard(
                latestVersion: _latestVersion,
                checkingUpdate: _checkingUpdate,
                updateError: _updateError,
                currentVersion: _versionInfoProvider.currentVersion,
                onCheck: _checkForUpdates,
                onUpdate: () {
                  if (_latestVersion != null) {
                    _showUpdateDialog(_latestVersion!);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEnvironmentInfoDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final versionInfo = await _versionInfoProvider.getVersionInfo();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            Text(localizations.environmentInfo),
          ],
        ),
        content: SelectableText(
          versionInfo,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.confirm),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _EnvironmentInfoButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EnvironmentInfoButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(AppLocalizations.of(context)!.environmentInfo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onPressed,
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final String? latestVersion;
  final bool checkingUpdate;
  final String? updateError;
  final String currentVersion;
  final VoidCallback onCheck;
  final VoidCallback onUpdate;

  const _UpdateCard({
    required this.latestVersion,
    required this.checkingUpdate,
    required this.updateError,
    required this.currentVersion,
    required this.onCheck,
    required this.onUpdate,
  });

  bool get _hasNewVersion {
    if (latestVersion == null) return false;
    try {
      final current = Version.parse(currentVersion);
      final latest = Version.parse(latestVersion!);
      return latest > current;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${localizations.version}: $currentVersion',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                if (checkingUpdate)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton(
                    onPressed: onCheck,
                    child: Text(localizations.checkForUpdates),
                  ),
              ],
            ),
            if (updateError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: $updateError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (latestVersion != null) ...[
              const SizedBox(height: 8),
              Text(
                'Latest: $latestVersion',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (_hasNewVersion)
                ElevatedButton.icon(
                  onPressed: onUpdate,
                  icon: const Icon(Icons.system_update_alt),
                  label: Text(localizations.newVersionAvailable),
                )
              else
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      localizations.noUpdateAvailable,
                      style: TextStyle(color: Colors.green[600]),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
