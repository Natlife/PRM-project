import 'package:flutter/material.dart';

import '../../../services/dashboard_service.dart';
import '../../../services/project_service.dart';
import '../student_project_detail_screen.dart';

class StudentProjectsTab extends StatefulWidget {
  final ValueChanged<int> onTabTapped;

  const StudentProjectsTab({
    super.key,
    required this.onTabTapped,
  });

  @override
  State<StudentProjectsTab> createState() => _StudentProjectsTabState();
}

class _StudentProjectsTabState extends State<StudentProjectsTab> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dashboardData = await DashboardService().getStudentDashboard();
      final activeGroups = List<Map<String, dynamic>>.from(
        dashboardData['activeGroups'] ?? const [],
      );

      final List<Map<String, dynamic>> loadedProjects = [];
      for (final group in activeGroups) {
        final groupId = (group['id'] as num?)?.toInt() ?? 0;
        final classroomId = (group['classroomId'] as num?)?.toInt() ?? 0;
        if (groupId == 0 || classroomId == 0) {
          continue;
        }

        final classCode = group['classroomCode']?.toString() ?? '';
        final className = group['classroomName']?.toString() ?? '';
        final groupName = group['groupName']?.toString() ?? '';
        final projectName = group['projectName']?.toString() ?? '';
        final memberCount = (group['memberCount'] as num?)?.toInt() ?? 0;

        Map<String, dynamic> groupDetail = {};
        List<Map<String, dynamic>> membersData = [];
        List<String> membersList = [];
        Map<String, dynamic>? leader;
        String description = '';
        String status = group['status']?.toString() ?? '';

        try {
          groupDetail = await ProjectService().getStudentProjectGroup(classroomId);
          membersData = List<Map<String, dynamic>>.from(
            groupDetail['members'] ?? const [],
          );
          membersList = membersData
              .map(
                (member) =>
                    member['fullName']?.toString() ??
                    member['userName']?.toString() ??
                    '',
              )
              .where((name) => name.isNotEmpty)
              .toList();
          leader = groupDetail['leader'] as Map<String, dynamic>?;
          description = groupDetail['description']?.toString() ?? '';
          status = groupDetail['status']?.toString() ?? status;
        } catch (e) {
          debugPrint('Error getting student project group detail: $e');
        }

        List<Map<String, dynamic>> milestones = [];
        try {
          milestones = await ProjectService().getGroupMilestones(groupId);
        } catch (e) {
          debugPrint('Error getting group milestones: $e');
        }

        double progress = 0;
        String projectDeadline = '';
        if (milestones.isNotEmpty) {
          final totalPercent = milestones.fold<int>(
            0,
            (sum, item) => sum + (((item['progressPercent'] as num?) ?? 0).toInt()),
          );
          progress = (totalPercent / milestones.length) / 100.0;

          DateTime? latestDate;
          for (final m in milestones) {
            final dueAtStr = m['dueAt']?.toString() ?? m['dueDate']?.toString() ?? '';
            if (dueAtStr.isNotEmpty) {
              try {
                final dt = DateTime.parse(dueAtStr);
                if (latestDate == null || dt.isAfter(latestDate)) {
                  latestDate = dt;
                }
              } catch (_) {}
            }
          }
          if (latestDate != null) {
            projectDeadline = '${latestDate.day.toString().padLeft(2, '0')}/${latestDate.month.toString().padLeft(2, '0')}/${latestDate.year}';
          }
        }

        loadedProjects.add({
          'id': groupId,
          'title': projectName.isNotEmpty ? projectName : groupName,
          'projectName': projectName,
          'groupName': groupName,
          'classCodeWithName': classCode.isNotEmpty && className.isNotEmpty
              ? '$classCode - $className'
              : classCode,
          'subject': className,
          'membersCount': memberCount,
          'membersList': membersList,
          'membersData': membersData,
          'leader': leader,
          'description': description,
          'status': status,
          'progress': progress,
          'milestones': milestones,
          'date': projectDeadline,
        });
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _projects = loadedProjects;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student projects: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Tất cả dự án',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
              )
            : RefreshIndicator(
                onRefresh: _loadProjects,
                color: const Color(0xFF7EC07E),
                child: _projects.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          _buildEmptyState(),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(20),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A).withOpacity(0.01),
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
                                      builder: (context) => StudentProjectDetailScreen(
                                        project: project,
                                      ),
                                    ),
                                  );
                                  if (targetIndex != null && targetIndex is int) {
                                    widget.onTabTapped(targetIndex);
                                  } else {
                                    _loadProjects();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                if ((project['classCodeWithName'] ?? '').toString().isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF7EC07E).withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      project['classCodeWithName'] ?? '',
                                                      style: const TextStyle(
                                                        color: Color(0xFF7EC07E),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                if ((project['status'] ?? '').toString().isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF0F172A).withOpacity(0.06),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      project['status'] ?? '',
                                                      style: const TextStyle(
                                                        color: Color(0xFF0F172A),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${project['membersCount'] ?? 0} thành viên',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF0F172A).withOpacity(0.4),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        project['projectName']?.toString().isNotEmpty == true
                                            ? project['projectName']
                                            : (project['title'] ?? ''),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      if ((project['groupName'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          project['groupName'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: const Color(0xFF7EC07E).withOpacity(0.85),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      if ((project['subject'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          project['subject'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: const Color(0xFF0F172A).withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                      if ((project['date'] ?? '').toString().isNotEmpty || project['leader'] != null) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if ((project['date'] ?? '').toString().isNotEmpty)
                                              Expanded(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.calendar_today, size: 13, color: const Color(0xFF0F172A).withOpacity(0.4)),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        'Hạn nộp: ${project['date']}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: const Color(0xFF0F172A).withOpacity(0.5),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if ((project['date'] ?? '').toString().isNotEmpty && project['leader'] != null)
                                              const SizedBox(width: 12),
                                            if (project['leader'] != null)
                                              Expanded(
                                                child: Text(
                                                  'Trưởng nhóm: ${project['leader']['fullName'] ?? project['leader']['userName'] ?? ''}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: const Color(0xFF0F172A).withOpacity(0.5),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Tiến độ chung:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF0F172A).withOpacity(0.4),
                                            ),
                                          ),
                                          Text(
                                            '${((project['progress'] as double? ?? 0) * 100).toInt()}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF7EC07E),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: project['progress'] as double? ?? 0,
                                          minHeight: 6,
                                          backgroundColor: const Color(0xFF0F172A).withOpacity(0.05),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7EC07E)),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7EC07E).withOpacity(0.12),
            ),
            child: const Icon(
              Icons.group_work_outlined,
              size: 40,
              color: Color(0xFF7EC07E),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có dự án nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khi hệ thống phân nhóm dự án của bạn, dữ liệu sẽ hiển thị ở đây.',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF0F172A).withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
