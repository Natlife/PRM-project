import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/project_service.dart';
import 'edit_milestone_screen.dart';

class MilestoneDetailScreen extends StatefulWidget {
  final Map<String, dynamic> milestone;

  const MilestoneDetailScreen({super.key, required this.milestone});

  @override
  State<MilestoneDetailScreen> createState() => _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends State<MilestoneDetailScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _inputBackgroundColor = Color(0xFFF9FBFA);
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  late Map<String, dynamic> _milestoneData;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _milestoneData = Map<String, dynamic>.from(widget.milestone);

    _milestoneData['activities'] ??= [];
    _milestoneData['comments'] ??= [];
    _milestoneData['evidences'] ??= [];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
      case 'COMPLETED':
        return const Color(0xFF22C55E);

      case 'Đang thực hiện':
      case 'IN_PROGRESS':
        return const Color(0xFFF59E0B);

      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Hoàn thành':
      case 'COMPLETED':
        return Icons.check_circle_outline_rounded;

      case 'Đang thực hiện':
      case 'IN_PROGRESS':
        return Icons.timelapse_rounded;

      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  Future<void> _saveMilestoneChanges() async {
    final int milestoneId = (_milestoneData['id'] as num?)?.toInt() ?? 0;

    if (milestoneId == 0) {
      return;
    }

    DateTime? dueDateTime;

    final String dateStr = _milestoneData['date']?.toString() ?? '';

    if (dateStr.isNotEmpty) {
      final List<String> parts = dateStr.split('/');

      if (parts.length == 3) {
        final int? day = int.tryParse(parts[0]);
        final int? month = int.tryParse(parts[1]);
        final int? year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          dueDateTime = DateTime(year, month, day, 23, 59, 59);
        }
      }
    }

    dueDateTime ??= DateTime.now().add(const Duration(days: 7));

    final String dueAtIso = dueDateTime.toIso8601String();

    final String statusRaw =
        _milestoneData['status']?.toString() ?? 'Chưa bắt đầu';

    String backendStatus = 'NOT_STARTED';

    if (statusRaw == 'Hoàn thành' || statusRaw == 'COMPLETED') {
      backendStatus = 'COMPLETED';
    } else if (statusRaw == 'Đang thực hiện' || statusRaw == 'IN_PROGRESS') {
      backendStatus = 'IN_PROGRESS';
    } else if (statusRaw == 'Quá hạn' || statusRaw == 'OVERDUE') {
      backendStatus = 'OVERDUE';
    }

    final String descriptionPayload = jsonEncode({
      'description': _milestoneData['description'] ?? '',
      'tasks': _milestoneData['activities'] ?? [],
      'comments': _milestoneData['comments'] ?? [],
    });

    final Map<String, dynamic> payload = {
      'title': _milestoneData['title'] ?? '',
      'description': descriptionPayload,
      'dueAt': dueAtIso,
      'status': backendStatus,
    };

    try {
      await ProjectService().updateMilestone(milestoneId, payload);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật mốc thời gian: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  void _changeActivityStatus(int index) {
    final List<dynamic> activities = List<dynamic>.from(
      _milestoneData['activities'] ?? [],
    );

    final Map<String, dynamic> activity = Map<String, dynamic>.from(
      activities[index],
    );

    final String currentStatus = activity['status'] ?? 'Chưa bắt đầu';

    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
          contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          title: const Text(
            'Cập nhật trạng thái',
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption(
                dialogContext: dialogContext,
                title: 'Chưa bắt đầu',
                currentStatus: currentStatus,
              ),
              _buildStatusOption(
                dialogContext: dialogContext,
                title: 'Đang thực hiện',
                currentStatus: currentStatus,
              ),
              _buildStatusOption(
                dialogContext: dialogContext,
                title: 'Hoàn thành',
                currentStatus: currentStatus,
              ),
            ],
          ),
        );
      },
    ).then((String? selectedStatus) {
      if (selectedStatus != null && selectedStatus != currentStatus) {
        setState(() {
          activity['status'] = selectedStatus;

          activity['isDone'] = selectedStatus == 'Hoàn thành';

          activities[index] = activity;

          _milestoneData['activities'] = activities;

          final int completedCount = activities
              .where(
                (dynamic item) =>
                    item['isDone'] == true || item['status'] == 'Hoàn thành',
              )
              .length;

          final double newProgress = activities.isEmpty
              ? 0.0
              : completedCount / activities.length;

          if (newProgress == 1.0) {
            _milestoneData['status'] = 'Hoàn thành';
          } else if (newProgress == 0.0) {
            _milestoneData['status'] = 'Chưa bắt đầu';
          } else {
            _milestoneData['status'] = 'Đang thực hiện';
          }
        });

        _saveMilestoneChanges();
      }
    });
  }

  Widget _buildStatusOption({
    required BuildContext dialogContext,
    required String title,
    required String currentStatus,
  }) {
    final Color statusColor = _getStatusColor(title);

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Radio<String>(
        value: title,
        groupValue: currentStatus,
        activeColor: _primaryColor,
        onChanged: (String? value) {
          Navigator.pop(dialogContext, title);
        },
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 14,
          fontWeight: title == currentStatus
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      trailing: Icon(_getStatusIcon(title), color: statusColor, size: 20),
      onTap: () {
        Navigator.pop(dialogContext, title);
      },
    );
  }

  Future<void> _navigateToEditMilestone() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute<Map<String, dynamic>>(
            builder: (BuildContext context) {
              return EditMilestoneScreen(milestone: _milestoneData);
            },
          ),
        );

    if (result != null) {
      setState(() {
        _milestoneData = result;
      });

      _saveMilestoneChanges();
    }
  }

  void _sendComment() {
    final String text = _commentController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      final List<Map<String, dynamic>> comments =
          List<Map<String, dynamic>>.from(_milestoneData['comments'] ?? []);

      comments.add({'sender': 'Giáo viên', 'text': text});

      _milestoneData['comments'] = comments;
      _commentController.clear();
    });

    _saveMilestoneChanges();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.of(context).pop(_milestoneData);
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Chi tiết mốc thời gian',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String status,
    required String date,
    required int activitiesCount,
  }) {
    final Color statusColor = _getStatusColor(status);

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
                  Icons.flag_outlined,
                  color: _primaryDarkColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mốc thời gian',
                      style: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 20,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildOverviewInformation(
                  icon: _getStatusIcon(status),
                  label: 'Trạng thái',
                  value: status,
                  valueColor: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewInformation(
                  icon: Icons.calendar_today_outlined,
                  label: 'Hạn hoàn thành',
                  value: date.isEmpty ? 'Chưa cập nhật' : date,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildOverviewInformation(
            icon: Icons.checklist_rounded,
            label: 'Số hoạt động',
            value: '$activitiesCount hoạt động',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _navigateToEditMilestone,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryDarkColor,
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: _primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Chỉnh sửa mốc thời gian',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewInformation({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: valueColor ?? _primaryDarkColor, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? _textPrimaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    String? countLabel,
  }) {
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (countLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    countLabel,
                    style: const TextStyle(
                      color: _primaryDarkColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(List<dynamic> activities) {
    return _buildSection(
      title: 'Hoạt động',
      icon: Icons.checklist_rounded,
      countLabel: '${activities.length}',
      child: activities.isEmpty
          ? _buildEmptyState(
              icon: Icons.checklist_rounded,
              message: 'Chưa có hoạt động nào',
            )
          : Column(
              children: List<Widget>.generate(activities.length, (int index) {
                final dynamic activity = activities[index];

                final String activityTitle = activity['title'] ?? '';

                final String activityStatus =
                    activity['status'] ?? 'Chưa bắt đầu';

                return _buildActivityCard(
                  title: activityTitle,
                  status: activityStatus,
                  onTap: () {
                    _changeActivityStatus(index);
                  },
                );
              }),
            ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String status,
    required VoidCallback onTap,
  }) {
    final Color statusColor = _getStatusColor(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit_outlined,
                  color: _textSecondaryColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvidencesSection(List<dynamic> evidences) {
    return _buildSection(
      title: 'Minh chứng',
      icon: Icons.attach_file_rounded,
      countLabel: '${evidences.length}',
      child: evidences.isEmpty
          ? _buildEmptyState(
              icon: Icons.insert_drive_file_outlined,
              message: 'Chưa tải lên minh chứng nào',
            )
          : Column(
              children: evidences.map<Widget>((dynamic evidence) {
                final String fileName =
                    evidence['originalFileName'] ??
                    evidence['fileName'] ??
                    'minh_chung.pdf';

                return _buildEvidenceCard(fileName);
              }).toList(),
            ),
    );
  }

  Widget _buildEvidenceCard(String fileName) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: _primaryDarkColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đang tải và mở: $fileName'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryDarkColor,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text(
              'Xem',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(List<dynamic> comments) {
    return _buildSection(
      title: 'Trao đổi',
      icon: Icons.forum_outlined,
      countLabel: '${comments.length}',
      child: comments.isEmpty
          ? _buildEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              message: 'Chưa có thảo luận nào',
            )
          : Column(
              children: comments.map<Widget>((dynamic comment) {
                final String sender = comment['sender'] ?? '';

                final String text = comment['text'] ?? '';

                return _buildCommentBubble(sender: sender, text: text);
              }).toList(),
            ),
    );
  }

  Widget _buildCommentBubble({required String sender, required String text}) {
    final bool isTeacher = sender == 'Giáo viên';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isTeacher
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isTeacher
                  ? const Color(0xFFEAF7F0)
                  : _inputBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isTeacher ? 16 : 4),
                bottomRight: Radius.circular(isTeacher ? 4 : 16),
              ),
              border: Border.all(
                color: isTeacher
                    ? _primaryColor.withOpacity(0.16)
                    : _borderColor,
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              sender,
              style: const TextStyle(
                color: _textSecondaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9AA49E), size: 30),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              textInputAction: TextInputAction.send,
              style: const TextStyle(color: _textPrimaryColor, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Nhập nhận xét của bạn...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9AA49E),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: _inputBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (String value) {
                _sendComment();
              },
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _sendComment,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 21),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required String title,
    required String status,
    required String date,
    required List<dynamic> activities,
    required List<dynamic> comments,
    required List<dynamic> evidences,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(
                title: title,
                status: status,
                date: date,
                activitiesCount: activities.length,
              ),
              const SizedBox(height: 14),
              _buildActivitiesSection(activities),
              const SizedBox(height: 14),
              _buildEvidencesSection(evidences),
              const SizedBox(height: 14),
              _buildCommentsSection(comments),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> activities = _milestoneData['activities'] ?? [];

    final List<dynamic> comments = _milestoneData['comments'] ?? [];

    final List<dynamic> evidences =
        _milestoneData['attachments'] ?? _milestoneData['evidences'] ?? [];

    final String title = _milestoneData['title'] ?? 'Mốc thời gian';

    final String status = _milestoneData['status'] ?? 'Chưa bắt đầu';

    final String date = _milestoneData['date'] ?? '';

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _buildContent(
                title: title,
                status: status,
                date: date,
                activities: activities,
                comments: comments,
                evidences: evidences,
              ),
            ),
            _buildCommentInputBar(),
          ],
        ),
      ),
    );
  }
}
