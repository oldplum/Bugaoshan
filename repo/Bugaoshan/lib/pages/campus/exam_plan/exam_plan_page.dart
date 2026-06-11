import 'package:flutter/material.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/pages/campus/exam_plan/models/exam_info.dart';
import 'package:bugaoshan/providers/scu_auth_provider.dart';
import 'package:bugaoshan/services/api/zhjw_api_service.dart';
import 'package:bugaoshan/services/auth/scu_exceptions.dart';
import 'package:bugaoshan/widgets/common/loading_widgets.dart';
import 'package:bugaoshan/widgets/common/login_required_widget.dart';
import 'package:bugaoshan/widgets/common/error_widgets.dart';

class ExamPlanPage extends StatefulWidget {
  const ExamPlanPage({super.key});

  @override
  State<ExamPlanPage> createState() => _ExamPlanPageState();
}

class _ExamPlanPageState extends State<ExamPlanPage> {
  List<ExamInfo> _exams = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    getIt<ScuAuthProvider>().addListener(_onAuthChanged);
    _loadData();
  }

  @override
  void dispose() {
    getIt<ScuAuthProvider>().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final auth = getIt<ScuAuthProvider>();
    if (auth.isLoggedIn && mounted) {
      _loadData();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    final auth = getIt<ScuAuthProvider>();
    if (!auth.isLoggedIn) {
      if (auth.isAutoLoggingIn) return;
      setState(() => _error = 'notLoggedIn');
      return;
    }

    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = getIt<ZhjwApiService>();
      final exams = await api.fetchExamPlan();
      if (mounted) {
        setState(() {
          _exams = exams;
          _loading = false;
        });
      }
    } on UnauthenticatedException {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'notLoggedIn';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'loadFailed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.examPlan),
        actions: [
          if (getIt<ScuAuthProvider>().isLoggedIn && !_loading)
            IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final auth = getIt<ScuAuthProvider>();

    if (!auth.isLoggedIn && auth.isAutoLoggingIn) {
      return const AutoLoginLoadingWidget();
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error == 'notLoggedIn') {
      if (getIt<ScuAuthProvider>().isAutoLoggingIn) {
        return const AutoLoginLoadingWidget();
      }
      return const LoginRequiredWidget();
    }

    if (_error != null) {
      return RetryableErrorWidget(
        message: l10n.examPlanLoadFailed,
        onRetry: _loadData,
      );
    }

    if (_exams.isEmpty) {
      return Center(
        child: Text(
          l10n.examPlanNoData,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exams.length,
        itemBuilder: (context, index) => _buildExamCard(_exams[index]),
      ),
    );
  }

  Widget _buildExamCard(ExamInfo exam) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exam.courseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exam.week,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _infoRow(Icons.calendar_today_outlined, exam.date),
            _infoRow(Icons.today_outlined, exam.weekday),
            _infoRow(Icons.access_time, exam.timeRange),
            _infoRow(Icons.place_outlined, exam.location),
            _infoRow(Icons.event_seat_outlined, exam.seatNumber),
            if (exam.ticketNumber.isNotEmpty)
              _infoRow(Icons.confirmation_number_outlined, exam.ticketNumber),
            if (exam.tip != '无') _infoRow(Icons.info_outlined, exam.tip),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
