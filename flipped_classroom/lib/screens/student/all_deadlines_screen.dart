import 'package:flutter/material.dart';

import '../../services/activity_service.dart';
import '../../services/dashboard_service.dart';
import 'student_activity_detail_screen.dart';

class AllDeadlinesScreen extends StatefulWidget {
  const AllDeadlinesScreen({super.key});

  @override
  State<AllDeadlinesScreen> createState() => _AllDeadlinesScreenState();
}

class _AllDeadlinesScreenState extends State<AllDeadlinesScreen> {
  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _dangerColor = Color(0xFFEF4444);

  static const int _pageSize = 10;
  static const double _loadMoreOffset = 200;

  final ScrollController _scrollController = ScrollController();
  final DashboardService _dashboardService = DashboardService();
  final ActivityService _activityService = ActivityService();

  final List<Map<String, dynamic>> _deadlines = [];

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadMoreDeadlines();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final shouldLoadMore = position.pixels >=
        position.maxScrollExtent - _loadMoreOffset;

    if (shouldLoadMore && !_isLoading && _hasMore) {
      _loadMoreDeadlines();
    }
  }

  Future<void> _loadMoreDeadlines() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rawList = await _dashboardService.getStudentDeadlines(
        _page,
        _pageSize,
      );

      final normalizedList = <Map<String, dynamic>>[];

      for (final activity in rawList) {
        final normalizedActivity = await _normalizeActivity(activity);
        normalizedList.add(normalizedActivity);
      }

      if (!mounted) return;

      setState(() {
        _deadlines.addAll(normalizedList);
        _isLoading = false;
        _hasMore = rawList.length >= _pageSize;

        if (_hasMore) {
          _page++;
        }
      });
    } catch (e) {
      debugPrint('Error loading deadlines: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _normalizeActivity(
    Map<String, dynamic> activity,
  ) async {
    Map<String, dynamic> submission = {};

    final activityId = (activity['id'] as num?)?.toInt();

    if (activityId != null) {
      try {
        submission = await _activityService.getStudentSubmission(activityId);
      } catch (e) {
        debugPrint('Error loading submission for deadline $activityId: $e');
      }
    }

    final submissionStatus =
        submission['status']?.toString() ?? 'NOT_SUBMITTED';

    final isDone = submissionStatus == 'SUBMITTED' ||
        submissionStatus == 'LATE_SUBMITTED' ||
        submissionStatus == 'GRADED';

    return {
      'id': activity['id'],
      'title': activity['title'] ?? '',
      'description': activity['description'] ?? '',
      'activityType': activity['activityType'],
      'type': _mapActivityType(activity['activityType']),
      'dueAt': activity['dueAt'],
      'deadline': _formatDueAt(activity['dueAt']),
      'maxScore': activity['maxScore'],
      'activityWorkflowStatus': activity['status']?.toString() ?? '',
      'submissionStatus': submissionStatus,
      'status': isDone ? 'Đã làm' : 'Chưa làm',
      'submissionId': submission['id'],
      'submissionTime': submission['submittedAt']?.toString(),
      'attachmentCount': submission['attachmentCount'] ?? 0,
      'commentCount': submission['commentCount'] ?? 0,
      'teacherFeedback': submission['teacherFeedback'] ?? '',
      'score': submission['score'],
    };
  }

  String _mapActivityType(dynamic value) {
    final type = value?.toString() ?? '';

    if (type == 'PRE_CLASS' || type == 'BEFORE_CLASS') {
      return 'Trước buổi học';
    }

    return 'Trong buổi học';
  }

  String _mapActivityStatus(dynamic value) {
    final status = value?.toString() ?? '';

    if (status == 'SUBMITTED' ||
        status == 'LATE_SUBMITTED' ||
        status == 'GRADED') {
      return 'Đã làm';
    }

    return 'Chưa làm';
  }

  String _formatDueAt(dynamic value) {
    if (value == null) {
      return 'Không có hạn';
    }

    return 'Hạn: ${value.toString().replaceFirst('T', ' ')}';
  }

  Future<void> _refresh() async {
    setState(() {
      _deadlines.clear();
      _page = 0;
      _hasMore = true;
    });

    await _loadMoreDeadlines();
  }

  Future<void> _openActivityDetail(Map<String, dynamic> activity) async {
    final dueAtStr =
        activity['deadline']?.toString() ?? _formatDueAt(activity['dueAt']);

    final targetIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentActivityDetailScreen(
          activity: {
            'id': activity['id'],
            'title': activity['title'] ?? '',
            'type':
                activity['type'] ?? _mapActivityType(activity['activityType']),
            'deadline': dueAtStr,
            'status': activity['status'] ??
                _mapActivityStatus(activity['submissionStatus']),
            'description': activity['description'] ?? '',
            'submissionId': activity['submissionId'],
            'submissionStatus': activity['submissionStatus'],
            'submissionTime': activity['submissionTime'],
            'attachmentCount': activity['attachmentCount'],
            'commentCount': activity['commentCount'],
            'teacherFeedback': activity['teacherFeedback'],
            'score': activity['score'],
            'maxScore': activity['maxScore'],
          },
        ),
      ),
    );

    if (targetIndex != null && mounted) {
      Navigator.pop(context, targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showInitialLoading = _deadlines.isEmpty && _isLoading;
    final showEmptyState = _deadlines.isEmpty && !_isLoading;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: _primaryColor,
          backgroundColor: _surfaceColor,
          child: showInitialLoading
              ? const _InitialLoadingView()
              : showEmptyState
                  ? const _EmptyDeadlinesView()
                  : _buildDeadlineList(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textColor,
          size: 20,
        ),
      ),
      title: const Text(
        'Tất cả deadline',
        style: TextStyle(
          color: _textColor,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildDeadlineList() {
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: _deadlines.length + (_isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _deadlines.length) {
          return const _LoadMoreIndicator();
        }

        final activity = _deadlines[index];

        return _DeadlineCard(
          title: activity['title']?.toString() ?? '',
          description: activity['description']?.toString() ?? '',
          deadline: activity['deadline']?.toString() ??
              _formatDueAt(activity['dueAt']),
          status: activity['status']?.toString() ?? '',
          onTap: () => _openActivityDetail(activity),
        );
      },
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final String title;
  final String description;
  final String deadline;
  final String status;
  final VoidCallback onTap;

  const _DeadlineCard({
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
    required this.onTap,
  });

  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _dangerColor = Color(0xFFEF4444);
  static const Color _successColor = Color(0xFF22C55E);
  static const Color _borderColor = Color(0xFFE2E8F0);

  bool get _isDone {
    return status == 'Đã làm';
  }

  @override
  Widget build(BuildContext context) {
    final titleText = title.trim().isEmpty ? 'Hoạt động chưa có tiêu đề' : title;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _borderColor.withOpacity(0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: _textColor.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: _buildContent(titleText),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: _mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final color = _isDone ? _successColor : _dangerColor;
    final icon = _isDone
        ? Icons.check_circle_outline_rounded
        : Icons.assignment_late_outlined;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildContent(String titleText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _textColor,
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.1,
          ),
        ),
        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _mutedTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              label: deadline,
              icon: Icons.schedule_rounded,
              foregroundColor: _dangerColor,
              backgroundColor: _dangerColor.withOpacity(0.08),
            ),
            if (status.trim().isNotEmpty)
              _InfoChip(
                label: status,
                icon: _isDone
                    ? Icons.done_rounded
                    : Icons.hourglass_bottom_rounded,
                foregroundColor: _isDone ? _successColor : _dangerColor,
                backgroundColor:
                    (_isDone ? _successColor : _dangerColor).withOpacity(0.08),
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: foregroundColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDeadlinesView extends StatelessWidget {
  const _EmptyDeadlinesView();

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  size: 42,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Không có deadline nào',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khi có bài tập hoặc hoạt động sắp đến hạn, chúng sẽ xuất hiện tại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _mutedTextColor,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InitialLoadingView extends StatelessWidget {
  const _InitialLoadingView();

  static const Color _primaryColor = Color(0xFF7EC07E);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: _primaryColor,
        ),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  static const Color _primaryColor = Color(0xFF7EC07E);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: _primaryColor,
          ),
        ),
      ),
    );
  }
}