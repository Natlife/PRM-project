import 'package:flutter/material.dart';

import 'student_milestone_detail_screen.dart';

class StudentProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const StudentProjectDetailScreen({super.key, required this.project});

  @override
  State<StudentProjectDetailScreen> createState() =>
      _StudentProjectDetailScreenState();
}

class _StudentProjectDetailScreenState
    extends State<StudentProjectDetailScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _inactiveColor = Color(0xFF7A857F);

  late List<Map<String, dynamic>> _milestones;

  @override
  void initState() {
    super.initState();

    _milestones = widget.project['milestones'] != null
        ? List<Map<String, dynamic>>.from(widget.project['milestones'])
        : <Map<String, dynamic>>[];
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  String _milestoneStatusLabel(String status) {
    if (status == 'COMPLETED' || status == 'Hoàn thành') {
      return 'Hoàn thành';
    }

    if (status == 'IN_PROGRESS' || status == 'Đang thực hiện') {
      return 'Đang thực hiện';
    }

    if (status == 'OVERDUE' || status == 'Quá hạn') {
      return 'Quá hạn';
    }

    return 'Chưa bắt đầu';
  }

  Color _milestoneStatusColor(String status) {
    if (status == 'COMPLETED' || status == 'Hoàn thành') {
      return _primaryColor;
    }

    if (status == 'IN_PROGRESS' || status == 'Đang thực hiện') {
      return _warningColor;
    }

    if (status == 'OVERDUE' || status == 'Quá hạn') {
      return _errorColor;
    }

    return _inactiveColor;
  }

  String _formatMilestoneDueDate(Map<String, dynamic> milestone) {
    final String dueAtString =
        milestone['dueAt']?.toString() ??
        milestone['dueDate']?.toString() ??
        '';

    if (dueAtString.isEmpty) {
      return '';
    }

    if (dueAtString.contains('Hạn:')) {
      return dueAtString;
    }

    try {
      final DateTime date = DateTime.parse(dueAtString);

      return 'Hạn: '
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return dueAtString;
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
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Chi tiết dự án',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildProjectOverview({
    required String classCodeWithName,
    required String projectName,
    required String groupName,
    required String description,
  }) {
    final String title = projectName.isNotEmpty
        ? projectName
        : widget.project['title']?.toString() ?? groupName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.group_work_outlined,
                  color: _primaryDarkColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (classCodeWithName.isNotEmpty) ...[
                      Container(
                        constraints: const BoxConstraints(maxWidth: 260),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F0),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          classCodeWithName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _primaryDarkColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 20,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (groupName.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.groups_2_outlined,
                  color: _primaryDarkColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    groupName,
                    style: const TextStyle(
                      color: _primaryDarkColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: _borderColor),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                color: _textSecondaryColor,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectStatistics(List<String> membersList) {
    final String projectDeadline = widget.project['date']?.toString() ?? '';

    return Row(
      children: [
        Expanded(
          child: _buildStatisticCard(
            icon: Icons.people_outline_rounded,
            label: 'Số thành viên',
            value: membersList.length.toString(),
            description: 'Thành viên',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatisticCard(
            icon: Icons.calendar_today_outlined,
            label: 'Hạn nộp',
            value: projectDeadline.isNotEmpty ? projectDeadline : 'Không có',
            description: 'Hạn dự án',
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String label,
    required String value,
    required String description,
  }) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _primaryDarkColor, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: _primaryDarkColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _primaryDarkColor, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(List<String> membersList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Thành viên (${membersList.length})',
          icon: Icons.groups_outlined,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
          ),
          child: membersList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                  child: Text(
                    'Chưa có dữ liệu thành viên.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textSecondaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Column(
                  children: List<Widget>.generate(membersList.length, (
                    int index,
                  ) {
                    return _buildMemberItem(
                      membersList[index],
                      index == membersList.length - 1,
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildMemberItem(String memberName, bool isLast) {
    final String trimmedName = memberName.trim();

    final String avatarText = trimmedName.isNotEmpty
        ? trimmedName.split(' ').last.substring(0, 1).toUpperCase()
        : '?';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  avatarText,
                  style: const TextStyle(
                    color: _primaryDarkColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  memberName,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 58, color: _borderColor),
      ],
    );
  }

  Widget _buildMilestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title: 'Mốc thời gian', icon: Icons.flag_outlined),
        const SizedBox(height: 14),
        ..._milestones.map(_buildMilestoneCard),
      ],
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone) {
    final String status = milestone['status']?.toString() ?? 'NOT_STARTED';

    final String displayStatus = _milestoneStatusLabel(status);

    final Color statusColor = _milestoneStatusColor(status);

    final String formattedDue = _formatMilestoneDueDate(milestone);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () async {
            final dynamic result = await Navigator.push(
              context,
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) {
                  return StudentMilestoneDetailScreen(
                    milestone: milestone,
                    project: widget.project,
                  );
                },
              ),
            );

            if (!context.mounted) {
              return;
            }

            if (result is int) {
              Navigator.pop(context, result);
            } else if (result is Map<String, dynamic>) {
              setState(() {
                milestone['status'] = result['status'];
                milestone['progress'] = result['progress'];
                milestone['progressPercent'] = (result['progress'] * 100)
                    .toInt();
                milestone['tasks'] = result['tasks'];
                milestone['attachments'] = result['attachments'];
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    color: statusColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone['title']?.toString() ?? '',
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 14.5,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (formattedDue.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: _textSecondaryColor,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formattedDue,
                                style: const TextStyle(
                                  color: _textSecondaryColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9AA49E),
                      size: 21,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: const Border(top: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: 2,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: _surfaceColor,
          elevation: 0,
          selectedItemColor: _primaryDarkColor,
          unselectedItemColor: const Color(0xFF8B9690),
          selectedFontSize: 11,
          unselectedFontSize: 10.5,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school_rounded),
              label: 'Lớp học',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_work_outlined),
              activeIcon: Icon(Icons.group_work_rounded),
              label: 'Dự án',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> membersList = widget.project['membersList'] != null
        ? List<String>.from(widget.project['membersList'])
        : <String>[];

    final String groupName = widget.project['groupName']?.toString() ?? '';

    final String projectName = widget.project['projectName']?.toString() ?? '';

    final String description = widget.project['description']?.toString() ?? '';

    final String classCodeWithName =
        widget.project['classCodeWithName']?.toString() ?? '';

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectOverview(
                    classCodeWithName: classCodeWithName,
                    projectName: projectName,
                    groupName: groupName,
                    description: description,
                  ),
                  const SizedBox(height: 16),
                  _buildProjectStatistics(membersList),
                  const SizedBox(height: 28),
                  _buildMembersSection(membersList),
                  const SizedBox(height: 28),
                  _buildMilestonesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
