import 'package:flutter/material.dart';
import '../student_project_detail_screen.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/project_service.dart';

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
      final List<dynamic> activeGroups = dashboardData['activeGroups'] ?? [];

      final List<Map<String, dynamic>> loadedProjects = [];
      for (var group in activeGroups) {
        final int groupId = group['id'];
        final String projectName = group['projectName'] ?? 'Dự án không tên';
        final String groupName = group['groupName'] ?? '';
        final int memberCount = group['memberCount'] ?? 1;
        final String classCode = group['classroomCode'] ?? '';
        final String className = group['classroomName'] ?? '';
        final int classroomId = group['classroomId'] ?? 0;

        // Fetch detailed project group to list members and milestones
        Map<String, dynamic> groupDetail = {};
        List<String> membersList = [];
        try {
          groupDetail = await ProjectService().getStudentProjectGroup(classroomId);
          final List<dynamic> membersData = groupDetail['members'] ?? [];
          membersList = membersData
              .map((m) => m['fullName'] as String? ?? 'Thành viên')
              .toList();
        } catch (e) {
          debugPrint('Error getting group detail: $e');
        }

        List<Map<String, dynamic>> milestones = [];
        try {
          milestones = await ProjectService().getGroupMilestones(groupId);
        } catch (e) {
          debugPrint('Error getting group milestones: $e');
        }

        // Calculate general progress
        double progress = 0.0;
        if (milestones.isNotEmpty) {
          int totalPercent = 0;
          for (var m in milestones) {
            totalPercent += (m['progressPercent'] as num).toInt();
          }
          progress = (totalPercent / milestones.length) / 100.0;
        }

        loadedProjects.add({
          'id': groupId,
          'title': projectName,
          'projectName': projectName,
          'groupName': groupName,
          'classCodeWithName': classCode.isNotEmpty ? '$classCode - $className' : 'Chưa xếp lớp',
          'subject': className.isNotEmpty ? className : 'Dự án môn học',
          'membersCount': memberCount,
          'membersList': membersList.isNotEmpty ? membersList : ['Thành viên'],
          'progress': progress,
          'milestones': milestones,
        });
      }

      setState(() {
        _projects = loadedProjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading projects: $e');
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
        shape: Border(
          bottom: BorderSide(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            width: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7EC07E),
                ),
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
                        padding: const EdgeInsets.all(20.0),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final proj = _projects[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
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
                                        project: proj,
                                      ),
                                    ),
                                  );
                                  if (targetIndex != null && targetIndex is int) {
                                    widget.onTabTapped(targetIndex);
                                  } else {
                                    // Reload project data if user returns
                                    _loadProjects();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF7EC07E).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              proj['classCodeWithName'] ?? '',
                                              style: const TextStyle(
                                                color: Color(0xFF7EC07E),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${proj['membersCount']} thành viên',
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
                                        proj['projectName'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        proj['subject'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: const Color(0xFF0F172A).withOpacity(0.5),
                                        ),
                                      ),
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
                                            '${(proj['progress'] * 100).toInt()}%',
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
                                          value: proj['progress'],
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
            'Hãy tham gia lớp học để bắt đầu dự án nhóm.',
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
