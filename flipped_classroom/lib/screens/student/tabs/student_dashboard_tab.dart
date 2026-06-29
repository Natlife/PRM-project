import 'package:flutter/material.dart';

import '../../../services/activity_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/dashboard_service.dart';
import '../student_activity_detail_screen.dart';
import '../student_class_detail_screen.dart';

class StudentDashboardTab extends StatefulWidget {
  final List<Map<String, dynamic>> myClasses;
  final VoidCallback onJoinClassPressed;
  final ValueChanged<int> onTabTapped;

  const StudentDashboardTab({
    super.key,
    required this.myClasses,
    required this.onJoinClassPressed,
    required this.onTabTapped,
  });

  @override
  State<StudentDashboardTab> createState() => _StudentDashboardTabState();
}

class _StudentDashboardTabState extends State<StudentDashboardTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _upcomingActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await DashboardService().getStudentDashboard();
      final rawUpcomingActivities = List<Map<String, dynamic>>.from(
        data['upcomingActivities'] ?? const [],
      );
      final List<Map<String, dynamic>> normalizedUpcomingActivities = [];

      for (final activity in rawUpcomingActivities) {
        Map<String, dynamic> submission = {};
        final activityId = (activity['id'] as num?)?.toInt();
        if (activityId != null) {
          try {
            submission = await ActivityService().getStudentSubmission(activityId);
          } catch (e) {
            debugPrint('Error loading submission for dashboard activity $activityId: $e');
          }
        }

        final submissionStatus = submission['status']?.toString() ?? 'NOT_SUBMITTED';
        final isDone = submissionStatus == 'SUBMITTED' ||
            submissionStatus == 'LATE_SUBMITTED' ||
            submissionStatus == 'GRADED';

        normalizedUpcomingActivities.add({
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
          'status': isDone ? 'Da lam' : 'Chua lam',
          'submissionId': submission['id'],
          'submissionTime': submission['submittedAt']?.toString(),
          'attachmentCount': submission['attachmentCount'] ?? 0,
          'commentCount': submission['commentCount'] ?? 0,
          'teacherFeedback': submission['teacherFeedback'] ?? '',
          'score': submission['score'],
        });
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _dashboardData = data;
        _upcomingActivities = normalizedUpcomingActivities;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student dashboard: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildClassCodeWithName(Map<String, dynamic> item) {
    final existing = item['classCodeWithName']?.toString().trim() ?? '';
    if (existing.isNotEmpty) {
      return existing;
    }

    final code = item['classCode']?.toString().trim() ?? '';
    final name = item['className']?.toString().trim() ?? '';
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }
    return code.isNotEmpty ? code : name;
  }

  String _mapActivityType(dynamic value) {
    final type = value?.toString() ?? '';
    if (type == 'PRE_CLASS' || type == 'BEFORE_CLASS') {
      return 'Truoc buoi hoc';
    }
    return 'Trong buoi hoc';
  }

  String _mapActivityStatus(dynamic value) {
    final status = value?.toString() ?? '';
    if (status == 'SUBMITTED' || status == 'LATE_SUBMITTED' || status == 'GRADED') {
      return 'Da lam';
    }
    return 'Chua lam';
  }

  String _formatDueAt(dynamic value) {
    if (value == null) {
      return 'Khong co han';
    }
    return 'Han: ${value.toString().split('T').join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final pendingCount = _dashboardData?['pendingActivitiesCount'] ?? 0;
    final upcomingActivities = _upcomingActivities;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFF7EC07E),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.onTabTapped(4),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF7EC07E),
                      child: Text(
                        user?.fullName.split(' ').last.substring(0, 1).toUpperCase() ?? 'SV',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chao, ${user?.fullName ?? "Sinh vien"}!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ban co $pendingCount deadline can xu ly',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: widget.onJoinClassPressed,
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text(
                  'Tham gia lop hoc',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7EC07E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Deadline sap toi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
                ),
              ),
            )
          else if (upcomingActivities.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Khong co deadline nao sap toi',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final activity = upcomingActivities[index];
                  final dueAtStr = activity['deadline']?.toString() ?? _formatDueAt(activity['dueAt']);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                        onTap: () {
                          Navigator.push(
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
                childCount: upcomingActivities.length,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lop hoc cua ban',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onTabTapped(1),
                    child: const Text(
                      'Xem tat ca',
                      style: TextStyle(
                        color: Color(0xFF7EC07E),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = widget.myClasses[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final targetIndex = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentClassDetailScreen(
                                classroomId: item['id'],
                                classCodeWithName: _buildClassCodeWithName(item),
                                className: item['className'] ?? '',
                                instructor: item['instructor'] ?? '',
                                semester: item['semester'] ?? '',
                              ),
                            ),
                          );
                          if (targetIndex != null && targetIndex is int) {
                            widget.onTabTapped(targetIndex);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7EC07E).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.school, color: Color(0xFF7EC07E), size: 22),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['classCode'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['instructor'] ?? '',
                                      style: TextStyle(
                                        color: const Color(0xFF0F172A).withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['semester'] ?? '',
                                      style: TextStyle(
                                        color: const Color(0xFF0F172A).withOpacity(0.4),
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: widget.myClasses.length > 3 ? 3 : widget.myClasses.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }
}
