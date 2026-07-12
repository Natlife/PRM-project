import 'package:flutter/material.dart';

import '../../../services/dashboard_service.dart';
import '../../../services/project_service.dart';
import '../student_project_detail_screen.dart';

class StudentProjectsTab extends StatefulWidget {
  final ValueChanged<int> onTabTapped;

  const StudentProjectsTab({super.key, required this.onTabTapped});

  @override
  State<StudentProjectsTab> createState() => _StudentProjectsTabState();
}

class _StudentProjectsTabState extends State<StudentProjectsTab> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);

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

      final List<Map<String, dynamic>> activeGroups =
          List<Map<String, dynamic>>.from(
            dashboardData['activeGroups'] ?? const [],
          );

      final List<Map<String, dynamic>> loadedProjects = [];

      for (final Map<String, dynamic> group in activeGroups) {
        final int groupId = (group['id'] as num?)?.toInt() ?? 0;

        final int classroomId = (group['classroomId'] as num?)?.toInt() ?? 0;

        if (groupId == 0 || classroomId == 0) {
          continue;
        }

        final String classCode = group['classroomCode']?.toString() ?? '';

        final String className = group['classroomName']?.toString() ?? '';

        final String groupName = group['groupName']?.toString() ?? '';

        final String projectName = group['projectName']?.toString() ?? '';

        final int memberCount = (group['memberCount'] as num?)?.toInt() ?? 0;

        Map<String, dynamic> groupDetail = {};
        List<Map<String, dynamic>> membersData = [];
        List<String> membersList = [];
        Map<String, dynamic>? leader;

        String description = '';
        String status = group['status']?.toString() ?? '';

        try {
          groupDetail = await ProjectService().getStudentProjectGroup(
            classroomId,
          );

          membersData = List<Map<String, dynamic>>.from(
            groupDetail['members'] ?? const [],
          );

          membersList = membersData
              .map(
                (Map<String, dynamic> member) =>
                    member['fullName']?.toString() ??
                    member['userName']?.toString() ??
                    '',
              )
              .where((String name) => name.isNotEmpty)
              .toList();

          leader = groupDetail['leader'] as Map<String, dynamic>?;

          description = groupDetail['description']?.toString() ?? '';

          status = groupDetail['status']?.toString() ?? status;
        } catch (error) {
          debugPrint('Error getting student project group detail: $error');
        }

        List<Map<String, dynamic>> milestones = [];

        try {
          milestones = await ProjectService().getGroupMilestones(groupId);
        } catch (error) {
          debugPrint('Error getting group milestones: $error');
        }

        double progress = 0;
        String projectDeadline = '';

        if (milestones.isNotEmpty) {
          final int totalPercent = milestones.fold<int>(0, (
            int sum,
            Map<String, dynamic> item,
          ) {
            return sum + (((item['progressPercent'] as num?) ?? 0).toInt());
          });

          progress = (totalPercent / milestones.length) / 100.0;

          DateTime? latestDate;

          for (final Map<String, dynamic> milestone in milestones) {
            final String dueAtString =
                milestone['dueAt']?.toString() ??
                milestone['dueDate']?.toString() ??
                '';

            if (dueAtString.isNotEmpty) {
              try {
                final DateTime date = DateTime.parse(dueAtString);

                if (latestDate == null || date.isAfter(latestDate)) {
                  latestDate = date;
                }
              } catch (_) {}
            }
          }

          if (latestDate != null) {
            projectDeadline =
                '${latestDate.day.toString().padLeft(2, '0')}/'
                '${latestDate.month.toString().padLeft(2, '0')}/'
                '${latestDate.year}';
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
    } catch (error) {
      debugPrint('Error loading student projects: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dự án của bạn',
                style: TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Theo dõi nhóm, tiến độ và các mốc dự án.',
                style: TextStyle(
                  color: _textSecondaryColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '${_projects.length} dự án',
            style: const TextStyle(
              color: _primaryDarkColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final String classCodeWithName =
        project['classCodeWithName']?.toString() ?? '';

    final String status = project['status']?.toString() ?? '';

    final String projectName = project['projectName']?.toString() ?? '';

    final String title = project['title']?.toString() ?? '';

    final String groupName = project['groupName']?.toString() ?? '';

    final String subject = project['subject']?.toString() ?? '';

    final String deadline = project['date']?.toString() ?? '';

    final int memberCount = (project['membersCount'] as num?)?.toInt() ?? 0;

    final double progress = (project['progress'] as num?)?.toDouble() ?? 0;

    final Map<String, dynamic>? leader =
        project['leader'] as Map<String, dynamic>?;

    final String leaderName =
        leader?['fullName']?.toString() ??
        leader?['userName']?.toString() ??
        '';

    final String displayName = projectName.isNotEmpty ? projectName : title;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final dynamic targetIndex = await Navigator.push(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) {
                return StudentProjectDetailScreen(project: project);
              },
            ),
          );

          if (targetIndex != null && targetIndex is int) {
            widget.onTabTapped(targetIndex);
          } else {
            _loadProjects();
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _textPrimaryColor.withOpacity(0.035),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F0),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.group_work_outlined,
                      color: _primaryDarkColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textPrimaryColor,
                            fontSize: 15.5,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (groupName.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            groupName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _primaryDarkColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA49E),
                    size: 22,
                  ),
                ],
              ),
              if (classCodeWithName.isNotEmpty || status.isNotEmpty) ...[
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (classCodeWithName.isNotEmpty)
                      _buildTag(
                        label: classCodeWithName,
                        foregroundColor: _primaryDarkColor,
                        backgroundColor: const Color(0xFFEAF7F0),
                      ),
                    if (status.isNotEmpty)
                      _buildTag(
                        label: status,
                        foregroundColor: _textSecondaryColor,
                        backgroundColor: const Color(0xFFF1F4F2),
                      ),
                  ],
                ),
              ],
              if (subject.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: Color(0xFF8B9690),
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textSecondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1, color: _borderColor),
              const SizedBox(height: 15),
              Wrap(
                spacing: 18,
                runSpacing: 11,
                children: [
                  _buildInformationItem(
                    icon: Icons.groups_outlined,
                    value: '$memberCount thành viên',
                  ),
                  if (deadline.isNotEmpty)
                    _buildInformationItem(
                      icon: Icons.calendar_today_outlined,
                      value: 'Hạn: $deadline',
                    ),
                  if (leader != null)
                    _buildInformationItem(
                      icon: Icons.workspace_premium_outlined,
                      value: 'Trưởng nhóm: $leaderName',
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tiến độ chung',
                      style: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: _primaryDarkColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFF0F3F1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required Color foregroundColor,
    required Color backgroundColor,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
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
    );
  }

  Widget _buildInformationItem({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF8B9690), size: 15),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
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

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        children: [
          _EmptyProjectIcon(),
          SizedBox(height: 22),
          Text(
            'Chưa có dự án nào',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Khi hệ thống phân nhóm dự án, thông tin dự án của bạn sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      itemCount: _projects.length + 1,
      separatorBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return const SizedBox(height: 22);
        }

        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _buildHeader();
        }

        return _buildProjectCard(_projects[index - 1]);
      },
    );
  }

  Widget _buildEmptyProjectList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      children: [_buildHeader(), _buildEmptyState()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProjects,
          color: _primaryColor,
          backgroundColor: _surfaceColor,
          child: _isLoading
              ? _buildLoadingState()
              : _projects.isEmpty
              ? _buildEmptyProjectList()
              : _buildProjectList(),
        ),
      ),
    );
  }
}

class _EmptyProjectIcon extends StatelessWidget {
  const _EmptyProjectIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(
        Icons.group_work_outlined,
        color: Color(0xFF167A52),
        size: 40,
      ),
    );
  }
}
