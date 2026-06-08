import 'package:flutter/material.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/pages/test/environment_info_page.dart';
import 'package:bugaoshan/widgets/route/router_utils.dart';

class EnvironmentInfoButton extends StatelessWidget {
  const EnvironmentInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(AppLocalizations.of(context)!.environmentInfo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => popupOrNavigate(context, const EnvironmentInfoPage()),
      ),
    );
  }
}
