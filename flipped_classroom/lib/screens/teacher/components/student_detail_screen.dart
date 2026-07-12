import 'package:flutter/material.dart';

import '../submission_detail_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentName;
  final String studentEmail;
  final int submissionsCount;
  final int progressPercentage;

  const StudentDetailScreen({
    super.key,
    required this.studentName,
    required this.studentEmail,
    required this.submissionsCount,
    required this.progressPercentage,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  final List<Map<String, dynamic>> _activitiesList = [
    {
      'title': 'Thực hành Lab 1',
      'date': '19/03/2026',
      'status': 'Đã được đánh giá',
      'statusColor': const Color(0xFF22C55E),
      'score': 9.0,
      'submitted': true,
    },
    {
      'title': 'Thực hành Lab 2',
      'date': '22/03/2026',
      'status': 'Chưa chấm',
      'statusColor': const Color(0xFF7EC07E),
      'score': null,
      'submitted': true,
    },
    {
      'title': 'Thực hành Lab 3',
      'date': '-',
      'status': 'Chưa nộp',
      'statusColor': Colors.redAccent,
      'score': null,
      'submitted': false,
    },
  ];

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
        'Chi tiết sinh viên',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildStudentOverview() {
    final String trimmedName = widget.studentName.trim();

    final String avatarText = trimmedName.isNotEmpty
        ? trimmedName.split(' ').last.substring(0, 1).toUpperCase()
        : '?';

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
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              avatarText,
              style: const TextStyle(
                color: _primaryDarkColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      color: _textSecondaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        widget.studentEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textSecondaryColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required int completedCount,
    required int totalCount,
  }) {
    final double progress = totalCount > 0 ? completedCount / totalCount : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: _primaryDarkColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Tiến độ hoạt động',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: const TextStyle(
                    color: _primaryDarkColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF0F3F1),
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.progressPercentage}% hoạt động đã được hoàn thành',
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Row(
      children: [
        _SubmissionSectionIcon(),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'Danh sách bài nộp',
            style: TextStyle(
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

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final bool isSubmitted = activity['submitted'] as bool;

    final Color statusColor = activity['statusColor'] as Color;

    final String title = activity['title']?.toString() ?? '';

    final String date = activity['date']?.toString() ?? '';

    final String status = activity['status']?.toString() ?? '';

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
          onTap: () {
            if (isSubmitted) {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return SubmissionDetailScreen(
                      studentName: widget.studentName,
                      submittedTime: date,
                    );
                  },
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sinh viên chưa nộp bài hoạt động này!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
                    color: isSubmitted
                        ? const Color(0xFFEAF7F0)
                        : const Color(0xFFFFECEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isSubmitted
                        ? Icons.assignment_turned_in_outlined
                        : Icons.assignment_late_outlined,
                    color: isSubmitted ? _primaryDarkColor : _errorColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isSubmitted
                                ? Icons.calendar_today_outlined
                                : Icons.schedule_outlined,
                            color: isSubmitted
                                ? _textSecondaryColor
                                : _errorColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isSubmitted ? 'Nộp ngày: $date' : 'Chưa nộp bài',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSubmitted
                                    ? _textSecondaryColor
                                    : _errorColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA49E),
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int completedCount = _activitiesList
        .where((Map<String, dynamic> activity) => activity['submitted'] as bool)
        .length;

    final int totalCount = _activitiesList.length;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStudentOverview(),
                    const SizedBox(height: 14),
                    _buildProgressCard(
                      completedCount: completedCount,
                      totalCount: totalCount,
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle(),
                    const SizedBox(height: 14),
                    ..._activitiesList.map(_buildActivityCard),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionSectionIcon extends StatelessWidget {
  const _SubmissionSectionIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.assignment_outlined,
        color: Color(0xFF167A52),
        size: 18,
      ),
    );
  }
}
