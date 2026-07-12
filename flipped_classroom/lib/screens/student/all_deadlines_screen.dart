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
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _warningColor = Color(0xFFF59E0B);

  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final DashboardService _dashboardService = DashboardService();
  final ActivityService _activityService = ActivityService();

  final List<Map<String, dynamic>> _deadlines = [];

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  String? _errorMessage;

  bool get _isInitialLoading => _isLoading && _deadlines.isEmpty;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
    _loadMoreDeadlines();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) {
      return;
    }

    final ScrollPosition position = _scrollController.position;
    const double loadMoreThreshold = 200;

    if (position.pixels >= position.maxScrollExtent - loadMoreThreshold) {
      _loadMoreDeadlines();
    }
  }

  Future<void> _loadMoreDeadlines() async {
    if (_isLoading || !_hasMore) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawList = await _dashboardService.getStudentDeadlines(
        _page,
        _pageSize,
      );

      final List<Map<String, dynamic>> normalizedList = [];

      for (final dynamic rawActivity in rawList) {
        final Map<String, dynamic> activity = Map<String, dynamic>.from(
          rawActivity as Map,
        );

        Map<String, dynamic> submission = {};

        final int? activityId = (activity['id'] as num?)?.toInt();

        if (activityId != null) {
          try {
            final dynamic rawSubmission = await _activityService
                .getStudentSubmission(activityId);

            if (rawSubmission is Map) {
              submission = Map<String, dynamic>.from(rawSubmission);
            }
          } catch (error) {
            debugPrint(
              'Error loading submission for deadline '
              '$activityId: $error',
            );
          }
        }

        final String submissionStatus =
            submission['status']?.toString() ?? 'NOT_SUBMITTED';

        final bool isDone = _isCompletedSubmission(submissionStatus);

        normalizedList.add({
          'id': activity['id'],
          'title': activity['title']?.toString() ?? '',
          'description': activity['description']?.toString() ?? '',
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
          'teacherFeedback': submission['teacherFeedback']?.toString() ?? '',
          'score': submission['score'],
        });
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _deadlines.addAll(normalizedList);

        if (rawList.length < _pageSize) {
          _hasMore = false;
        } else {
          _page++;
        }
      });
    } catch (error) {
      debugPrint('Error loading deadlines: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Không thể tải danh sách deadline.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isCompletedSubmission(String status) {
    return status == 'SUBMITTED' ||
        status == 'LATE_SUBMITTED' ||
        status == 'GRADED';
  }

  String _mapActivityType(dynamic value) {
    final String type = value?.toString() ?? '';

    if (type == 'PRE_CLASS' || type == 'BEFORE_CLASS') {
      return 'Trước buổi học';
    }

    return 'Trong buổi học';
  }

  String _mapActivityStatus(dynamic value) {
    final String status = value?.toString() ?? '';

    return _isCompletedSubmission(status) ? 'Đã làm' : 'Chưa làm';
  }

  String _formatDueAt(dynamic value) {
    if (value == null) {
      return 'Không có hạn';
    }

    final String dueAt = value.toString().replaceFirst('T', ' ');

    return 'Hạn: $dueAt';
  }

  Future<void> _refresh() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _deadlines.clear();
      _page = 0;
      _hasMore = true;
      _errorMessage = null;
    });

    await _loadMoreDeadlines();
  }

  Future<void> _openActivityDetail(Map<String, dynamic> activity) async {
    final String dueAt =
        activity['deadline']?.toString() ?? _formatDueAt(activity['dueAt']);

    final dynamic targetIndex = await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) {
          return StudentActivityDetailScreen(
            activity: {
              'id': activity['id'],
              'title': activity['title'] ?? '',
              'type':
                  activity['type'] ??
                  _mapActivityType(activity['activityType']),
              'deadline': dueAt,
              'status':
                  activity['status'] ??
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
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (targetIndex is int) {
      Navigator.of(context).pop(targetIndex);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Tất cả deadline',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(Map<String, dynamic> activity) {
    final String title = activity['title']?.toString() ?? '';
    final String description = activity['description']?.toString() ?? '';
    final String type =
        activity['type']?.toString() ??
        _mapActivityType(activity['activityType']);
    final String status =
        activity['status']?.toString() ??
        _mapActivityStatus(activity['submissionStatus']);
    final String dueAt =
        activity['deadline']?.toString() ?? _formatDueAt(activity['dueAt']);

    final bool isDone = status == 'Đã làm';

    final Color statusColor = isDone ? _primaryColor : _warningColor;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openActivityDetail(activity),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _textPrimaryColor.withOpacity(0.04),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isDone ? Icons.task_alt_rounded : Icons.assignment_outlined,
                  color: statusColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textPrimaryColor,
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9AA49E),
                          size: 21,
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textSecondaryColor,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInformationChip(
                          icon: Icons.schedule_rounded,
                          label: dueAt,
                          foregroundColor: _errorColor,
                          backgroundColor: const Color(0xFFFFECEE),
                        ),
                        _buildInformationChip(
                          icon: Icons.layers_outlined,
                          label: type,
                          foregroundColor: _primaryDarkColor,
                          backgroundColor: const Color(0xFFEAF7F0),
                        ),
                        _buildInformationChip(
                          icon: isDone
                              ? Icons.check_circle_outline_rounded
                              : Icons.pending_outlined,
                          label: status,
                          foregroundColor: statusColor,
                          backgroundColor: statusColor.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformationChip({
    required IconData icon,
    required String label,
    required Color foregroundColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foregroundColor, size: 13),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineList() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: _primaryColor,
      backgroundColor: _surfaceColor,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _deadlines.length + (_isLoading ? 1 : 0),
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (BuildContext context, int index) {
          if (index == _deadlines.length) {
            return _buildLoadingMoreIndicator();
          }

          return _buildDeadlineCard(_deadlines[index]);
        },
      ),
    );
  }

  Widget _buildInitialLoadingState() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: _primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.event_available_outlined,
                color: _primaryDarkColor,
                size: 43,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có deadline',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Các bài tập và hoạt động có thời hạn sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Kéo xuống để tải lại',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AA49E),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: _primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEE),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: _errorColor,
                size: 43,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Không thể tải deadline',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _errorMessage ?? 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: FilledButton.icon(
              onPressed: _refresh,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 19),
              label: const Text(
                'Thử lại',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return _buildInitialLoadingState();
    }

    if (_deadlines.isEmpty && _errorMessage != null) {
      return _buildErrorState();
    }

    if (_deadlines.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDeadlineList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }
}
