import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../services/activity_service.dart';
import 'student_activity_detail_screen.dart';

class AllDeadlinesScreen extends StatefulWidget {
  const AllDeadlinesScreen({super.key});

  @override
  State<AllDeadlinesScreen> createState() => _AllDeadlinesScreenState();
}

class _AllDeadlinesScreenState extends State<AllDeadlinesScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _deadlines = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadMoreDeadlines();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreDeadlines();
      }
    }
  }

  Future<void> _loadMoreDeadlines() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final rawList = await DashboardService().getStudentDeadlines(_page, _pageSize);
      
      final List<Map<String, dynamic>> normalizedList = [];
      for (final activity in rawList) {
        Map<String, dynamic> submission = {};
        final activityId = (activity['id'] as num?)?.toInt();
        if (activityId != null) {
          try {
            submission = await ActivityService().getStudentSubmission(activityId);
          } catch (e) {
            debugPrint('Error loading submission for deadline $activityId: $e');
          }
        }

        final submissionStatus = submission['status']?.toString() ?? 'NOT_SUBMITTED';
        final isDone = submissionStatus == 'SUBMITTED' ||
            submissionStatus == 'LATE_SUBMITTED' ||
            submissionStatus == 'GRADED';

        normalizedList.add({
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
        });
      }

      if (!mounted) return;

      setState(() {
        _deadlines.addAll(normalizedList);
        _isLoading = false;
        if (rawList.length < _pageSize) {
          _hasMore = false;
        } else {
          _page++;
        }
      });
    } catch (e) {
      debugPrint('Error loading deadlines: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    if (status == 'SUBMITTED' || status == 'LATE_SUBMITTED' || status == 'GRADED') {
      return 'Đã làm';
    }
    return 'Chưa làm';
  }

  String _formatDueAt(dynamic value) {
    if (value == null) {
      return 'Không có hạn';
    }
    return 'Hạn: ${value.toString().split('T').join(' ')}';
  }

  Future<void> _refresh() async {
    setState(() {
      _deadlines.clear();
      _page = 0;
      _hasMore = true;
    });
    await _loadMoreDeadlines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tất cả deadline',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF7EC07E),
        child: _deadlines.isEmpty && !_isLoading
            ? const Center(
                child: Text(
                  'Không có deadline nào',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: _deadlines.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _deadlines.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
                      ),
                    );
                  }

                  final activity = _deadlines[index];
                  final dueAtStr = activity['deadline']?.toString() ?? _formatDueAt(activity['dueAt']);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final targetIndex = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentActivityDetailScreen(
                                activity: {
                                  'id': activity['id'],
                                  'title': activity['title'] ?? '',
                                  'type': activity['type'] ?? _mapActivityType(activity['activityType']),
                                  'deadline': dueAtStr,
                                  'status': activity['status'] ?? _mapActivityStatus(activity['submissionStatus']),
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
                          if (targetIndex != null && targetIndex is int && mounted) {
                            Navigator.pop(context, targetIndex);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.assignment_late_outlined,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      activity['description'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFF0F172A).withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        dueAtStr,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
