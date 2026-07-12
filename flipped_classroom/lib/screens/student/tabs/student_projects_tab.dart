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
  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final DashboardService _dashboardService = DashboardService();
  final ProjectService _projectService = ProjectService();

  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final dashboardData = await _dashboardService.getStudentDashboard();

      final activeGroups = List<Map<String, dynamic>>.from(
        dashboardData['activeGroups'] ?? const [],
      );

      final loadedProjects = <Map<String, dynamic>>[];

      for (final group in activeGroups) {
        final project = await _buildProjectFromGroup(group);

        if (project != null) {
          loadedProjects.add(project);
        }
      }

      if (!mounted) return;

      setState(() {
        _projects = loadedProjects;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student projects: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _buildProjectFromGroup(
    Map<String, dynamic> group,
  ) async {
    final groupId = (group['id'] as num?)?.toInt() ?? 0;
    final classroomId = (group['classroomId'] as num?)?.toInt() ?? 0;

    if (groupId == 0 || classroomId == 0) {
      return null;
    }

    final classCode = group['classroomCode']?.toString() ?? '';
    final className = group['classroomName']?.toString() ?? '';
    final groupName = group['groupName']?.toString() ?? '';
    final projectName = group['projectName']?.toString() ?? '';
    final memberCount = (group['memberCount'] as num?)?.toInt() ?? 0;

    final groupDetail = await _loadGroupDetail(classroomId);
    final milestones = await _loadMilestones(groupId);

    final membersData = List<Map<String, dynamic>>.from(
      groupDetail['members'] ?? const [],
    );

    final membersList = membersData
        .map(
          (member) =>
              member['fullName']?.toString() ??
              member['userName']?.toString() ??
              '',
        )
        .where((name) => name.isNotEmpty)
        .toList();

    final leader = groupDetail['leader'] as Map<String, dynamic>?;
    final description = groupDetail['description']?.toString() ?? '';
    final status =
        groupDetail['status']?.toString() ?? group['status']?.toString() ?? '';

    return {
      'id': groupId,
      'title': projectName.isNotEmpty ? projectName : groupName,
      'projectName': projectName,
      'groupName': groupName,
      'classCodeWithName': _buildClassCodeWithName(
        classCode: classCode,
        className: className,
      ),
      'subject': className,
      'membersCount': memberCount,
      'membersList': membersList,
      'membersData': membersData,
      'leader': leader,
      'description': description,
      'status': status,
      'progress': _calculateProgress(milestones),
      'milestones': milestones,
      'date': _getProjectDeadline(milestones),
    };
  }

  Future<Map<String, dynamic>> _loadGroupDetail(int classroomId) async {
    try {
      return await _projectService.getStudentProjectGroup(classroomId);
    } catch (e) {
      debugPrint('Error getting student project group detail: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _loadMilestones(int groupId) async {
    try {
      return await _projectService.getGroupMilestones(groupId);
    } catch (e) {
      debugPrint('Error getting group milestones: $e');
      return [];
    }
  }

  String _buildClassCodeWithName({
    required String classCode,
    required String className,
  }) {
    if (classCode.isNotEmpty && className.isNotEmpty) {
      return '$classCode - $className';
    }

    return classCode.isNotEmpty ? classCode : className;
  }

  double _calculateProgress(List<Map<String, dynamic>> milestones) {
    if (milestones.isEmpty) {
      return 0;
    }

    final totalPercent = milestones.fold<int>(
      0,
      (sum, item) {
        final progress = (item['progressPercent'] as num?)?.toInt() ?? 0;
        return sum + progress;
      },
    );

    return (totalPercent / milestones.length) / 100.0;
  }

  String _getProjectDeadline(List<Map<String, dynamic>> milestones) {
    DateTime? latestDate;

    for (final milestone in milestones) {
      final dueAt = milestone['dueAt']?.toString() ??
          milestone['dueDate']?.toString() ??
          '';

      if (dueAt.isEmpty) continue;

      try {
        final date = DateTime.parse(dueAt);

        if (latestDate == null || date.isAfter(latestDate)) {
          latestDate = date;
        }
      } catch (_) {
        continue;
      }
    }

    if (latestDate == null) {
      return '';
    }

    final day = latestDate.day.toString().padLeft(2, '0');
    final month = latestDate.month.toString().padLeft(2, '0');
    final year = latestDate.year.toString();

    return '$day/$month/$year';
  }

  Future<void> _openProjectDetail(Map<String, dynamic> project) async {
    final targetIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentProjectDetailScreen(
          project: project,
        ),
      ),
    );

    if (!mounted) return;

    if (targetIndex != null) {
      widget.onTabTapped(targetIndex);
      return;
    }

    await _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Dự án của bạn',
        style: TextStyle(
          color: _textColor,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const _LoadingView();
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: _primaryColor,
      backgroundColor: _surfaceColor,
      child: _projects.isEmpty ? const _EmptyProjectsView() : _buildProjectList(),
    );
  }

  Widget _buildProjectList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: _projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final project = _projects[index];

        return _ProjectCard(
          project: project,
          onTap: () => _openProjectDetail(project),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  double get _progress {
    final value = project['progress'];

    if (value is num) {
      return value.toDouble().clamp(0.0, 1.0);
    }

    return 0;
  }

  int get _progressPercent {
    return (_progress * 100).round();
  }

  String get _projectTitle {
    final projectName = project['projectName']?.toString() ?? '';
    final title = project['title']?.toString() ?? '';

    return projectName.isNotEmpty
        ? projectName
        : title.isNotEmpty
            ? title
            : 'Dự án chưa có tên';
  }

  String get _leaderName {
    final leader = project['leader'];

    if (leader is Map<String, dynamic>) {
      return leader['fullName']?.toString() ??
          leader['userName']?.toString() ??
          '';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final classCodeWithName = project['classCodeWithName']?.toString() ?? '';
    final status = project['status']?.toString() ?? '';
    final groupName = project['groupName']?.toString() ?? '';
    final subject = project['subject']?.toString() ?? '';
    final deadline = project['date']?.toString() ?? '';
    final membersCount = project['membersCount'] ?? 0;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _borderColor.withOpacity(0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: _textColor.withOpacity(0.035),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(
                classCodeWithName: classCodeWithName,
                status: status,
                membersCount: membersCount,
              ),
              const SizedBox(height: 14),
              Text(
                _projectTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 17,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              if (groupName.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  groupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (subject.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mutedTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (deadline.isNotEmpty || _leaderName.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ProjectMetaRow(
                  deadline: deadline,
                  leaderName: _leaderName,
                ),
              ],
              const SizedBox(height: 18),
              _ProgressSection(
                percent: _progressPercent,
                progress: _progress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow({
    required String classCodeWithName,
    required String status,
    required Object membersCount,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (classCodeWithName.isNotEmpty)
                _ProjectChip(
                  label: classCodeWithName,
                  backgroundColor: _primaryColor.withOpacity(0.12),
                  foregroundColor: _primaryColor,
                ),
              if (status.isNotEmpty)
                _ProjectChip(
                  label: status,
                  backgroundColor: _fieldColor,
                  foregroundColor: _textColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _fieldColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.groups_2_outlined,
                size: 15,
                color: _mutedTextColor,
              ),
              const SizedBox(width: 5),
              Text(
                '$membersCount',
                style: const TextStyle(
                  color: _mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectMetaRow extends StatelessWidget {
  final String deadline;
  final String leaderName;

  const _ProjectMetaRow({
    required this.deadline,
    required this.leaderName,
  });

  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          if (deadline.isNotEmpty)
            _MetaItem(
              icon: Icons.calendar_today_rounded,
              text: 'Hạn nộp: $deadline',
            ),
          if (deadline.isNotEmpty && leaderName.isNotEmpty)
            const SizedBox(height: 8),
          if (leaderName.isNotEmpty)
            _MetaItem(
              icon: Icons.workspace_premium_outlined,
              text: 'Trưởng nhóm: $leaderName',
            ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({
    required this.icon,
    required this.text,
  });

  static const Color _mutedTextColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: _mutedTextColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _mutedTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final int percent;
  final double progress;

  const _ProgressSection({
    required this.percent,
    required this.progress,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tiến độ chung',
                style: TextStyle(
                  color: _mutedTextColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: _primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: _fieldColor,
            valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
        ),
      ],
    );
  }
}

class _ProjectChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ProjectChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyProjectsView extends StatelessWidget {
  const _EmptyProjectsView();

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _surfaceColor = Colors.white;
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
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
                  Icons.group_work_outlined,
                  size: 40,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chưa có dự án nào',
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
                'Khi hệ thống phân nhóm dự án của bạn, dữ liệu sẽ hiển thị ở đây.',
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

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