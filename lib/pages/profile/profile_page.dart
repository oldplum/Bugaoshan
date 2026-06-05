import 'package:bugaoshan/providers/app_config_provider.dart';
import 'package:bugaoshan/providers/user_info_provider.dart';
import 'package:bugaoshan/widgets/common/third_center.dart';
import 'package:bugaoshan/widgets/dialog/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/pages/auth/scu_login_page.dart';
import 'package:bugaoshan/pages/profile/login_status_card.dart';
import 'package:bugaoshan/pages/profile/profile_menu_card.dart';
import 'package:bugaoshan/pages/profile/user_info_card.dart';
import 'package:bugaoshan/providers/scu_auth_provider.dart';
import 'package:bugaoshan/widgets/route/router_utils.dart';

const _keyUsername = 'scu_saved_username';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = await _storage.read(key: _keyUsername);
    if (mounted) {
      setState(() => _username = username);
    }
  }

  Future<void> _openLogin(BuildContext context) async {
    final result = await popupOrNavigate(context, const ScuLoginPage());
    if (result == true && context.mounted) {
      _loadUsername();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录成功')));
    }
  }

  Future<void> _confirmLogout(
    BuildContext context,
    ScuAuthProvider provider,
    AppLocalizations localizations,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.confirmMessage),
        content: Text(localizations.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(localizations.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = getIt<ScuAuthProvider>();
    final userInfoProvider = getIt<UserInfoProvider>();
    final localizations = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: Listenable.merge([authProvider, userInfoProvider]),
      builder: (context, _) {
        final status = LoginStatus.from(authProvider);

        final loginStatusCard = LoginStatusCard(
          status: status,
          username: _username,
          authProvider: authProvider,
          onLogin: () => _openLogin(context),
          onLogout: () => _confirmLogout(context, authProvider, localizations),
        );

        final body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            loginStatusCard,

            const SizedBox(height: 12),
            AnimatedSize(
              duration: appConfigService.cardSizeAnimationDuration.value,
              curve: appCurve,
              child: UserInfoCard(provider: userInfoProvider),
            ),

            const SizedBox(height: 12),
            const ProfileMenuCard(),
          ],
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: ThirdCenter(child: body),
              ),
            );
          },
        );
      },
    );
  }
}
