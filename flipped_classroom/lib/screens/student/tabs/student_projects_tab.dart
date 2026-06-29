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
        if (milestones.isNotEmpty) {
          final totalPercent = milestones.fold<int>(
            0,
            (sum, item) => sum + (((item['progressPercent'] as num?) ?? 0).toInt()),
          );
          progress = (totalPercent / milestones.length) / 100.0;
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
          'Tat ca du an',
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
                                            '${project['membersCount'] ?? 0} thanh vien',
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
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Tien do chung:',
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
            'Chua co du an nao',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khi backend co nhom du an cua ban, du lieu se hien o day.',
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
