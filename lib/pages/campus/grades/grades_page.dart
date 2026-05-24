import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/providers/grades_provider.dart';
import 'package:bugaoshan/providers/scu_auth_provider.dart';
import 'package:bugaoshan/widgets/common/loading_widgets.dart';
import 'package:bugaoshan/widgets/common/login_required_widget.dart';
import 'scheme_scores_tab.dart';
import 'passing_scores_tab.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [SchemeScoresTab(), PassingScoresTab()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: Listenable.merge([
        getIt<ScuAuthProvider>(),
        getIt<GradesProvider>(),
      ]),
      builder: (context, _) {
        final auth = getIt<ScuAuthProvider>();

        final isDesktop =
            !kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
        final gradesProvider = getIt<GradesProvider>();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.gradesStats),
              actions: [
                if (isDesktop && auth.isLoggedIn)
                  IconButton(
                    onPressed: _currentIndex == 0
                        ? gradesProvider.refreshSchemeScores
                        : gradesProvider.refreshPassingScores,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
              bottom: auth.isLoggedIn
                  ? TabBar(
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      dividerHeight: 0,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                      tabs: [
                        Tab(text: l10n.schemeScores),
                        Tab(text: l10n.passingScores),
                      ],
                    )
                  : null,
            ),
            body: !auth.isLoggedIn
                ? auth.isAutoLoggingIn
                      ? const AutoLoginLoadingWidget()
                      : const LoginRequiredWidget()
                : _pages[_currentIndex],
          ),
        );
      },
    );
  }
}
