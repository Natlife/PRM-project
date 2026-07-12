import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/event_service.dart';
import 'student_defense_room_screen.dart';
import 'student_event_review_screen.dart';

class StudentEventDetailScreen extends StatefulWidget {
  final int eventId;

  const StudentEventDetailScreen({super.key, required this.eventId});

  @override
  State<StudentEventDetailScreen> createState() =>
      _StudentEventDetailScreenState();
}

class _StudentEventDetailScreenState extends State<StudentEventDetailScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _warningColor = Color(0xFFF59E0B);

  bool _isLoading = true;
  Map<String, dynamic> _detail = {};

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final detail = await EventService().getStudentEventDetail(widget.eventId);

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải chi tiết sự kiện: $error'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) {
      return '';
    }

    final String value = raw.toString();
    final List<String> parts = value.split('T');

    if (parts.length != 2) {
      return value;
    }

    final List<String> date = parts.first.split('-');
    final List<String> time = parts.last.split(':');

    if (date.length == 3 && time.length >= 2) {
      return '${date[2]}/${date[1]}/${date[0]} '
          '${time[0]}:${time[1]}';
    }

    return value;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'LIVE':
        return 'Đang diễn ra';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'SCHEDULED':
      default:
        return 'Chưa diễn ra';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'LIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return _errorColor;
      case 'SCHEDULED':
      default:
        return Colors.orange;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'PRESENTER':
        return 'Người thuyết trình';
      case 'REVIEWER':
        return 'Người phản biện';
      default:
        return 'Khán giả';
    }
  }

  String _assignmentStatusLabel(String status) {
    switch (status) {
      case 'REVIEWED':
        return 'Đã review';
      case 'PENDING':
      default:
        return 'Chưa review';
    }
  }

  Future<void> _uploadEvidence() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.first;

      List<int>? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        return;
      }

      await EventService().uploadStudentEvidence(
        widget.eventId,
        bytes,
        file.name,
      );

      await _loadDetail();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi upload minh chứng: $error'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteEvidence(int assetId) async {
    try {
      await EventService().deleteStudentEvidence(assetId);
      await _loadDetail();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa minh chứng: $error'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openDefenseRoom(int assignmentId) async {
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) {
          return StudentDefenseRoomScreen(
            eventId: widget.eventId,
            assignmentId: assignmentId,
          );
        },
      ),
    );

    if (result != null) {
      await _loadDetail();
    }
  }

  Future<void> _openReview(int assignmentId) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return StudentEventReviewScreen(
            eventId: widget.eventId,
            assignmentId: assignmentId,
          );
        },
      ),
    );
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
          Navigator.pop(context, true);
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Chi tiết sự kiện',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildEventOverview({required String status, required String role}) {
    final Color statusColor = _statusColor(status);

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
              Expanded(
                child: Text(
                  _detail['title']?.toString() ?? '',
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 21,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusChip(label: _statusLabel(status), color: statusColor),
            ],
          ),
          if ((_detail['classroomCode'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  color: _textSecondaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _detail['classroomCode'].toString(),
                    style: const TextStyle(
                      color: _textSecondaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 18),
          _buildInformationRow(
            icon: Icons.badge_outlined,
            label: 'Vai trò của bạn',
            value: _roleLabel(role),
          ),
          const SizedBox(height: 15),
          _buildInformationRow(
            icon: Icons.play_circle_outline_rounded,
            label: 'Thời gian bắt đầu',
            value: _formatDateTime(_detail['startAt']),
          ),
          const SizedBox(height: 15),
          _buildInformationRow(
            icon: Icons.stop_circle_outlined,
            label: 'Thời gian kết thúc',
            value: _formatDateTime(_detail['endAt']),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _textSecondaryColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final int assignmentId = (assignment['id'] as num?)?.toInt() ?? 0;

    final String assignmentRole =
        assignment['myRole']?.toString() ?? 'AUDIENCE';

    final String assignmentStatus =
        assignment['status']?.toString() ?? 'PENDING';

    final Map<String, dynamic>? recording =
        assignment['recording'] as Map<String, dynamic>?;

    final bool isReviewed = assignmentStatus == 'REVIEWED';

    final String presenter =
        assignment['presenterGroupName']?.toString().isNotEmpty == true
        ? assignment['presenterGroupName'].toString()
        : assignment['presenterStudentName']?.toString() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${assignment['orderIndex'] ?? ''}',
                  style: const TextStyle(
                    color: _primaryDarkColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phiên phản biện',
                      style: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      presenter,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildStatusChip(
                label: _assignmentStatusLabel(assignmentStatus),
                color: isReviewed ? _primaryDarkColor : _warningColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 16),
          _buildCompactInformationRow(
            icon: Icons.badge_outlined,
            label: 'Vai trò',
            value: _roleLabel(assignmentRole),
          ),
          const SizedBox(height: 12),
          _buildCompactInformationRow(
            icon: Icons.person_search_outlined,
            label: 'Người phản biện',
            value: assignment['reviewerStudentName']?.toString() ?? '',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (_detail['canJoinRoom'] == true)
                FilledButton.icon(
                  onPressed: () {
                    _openDefenseRoom(assignmentId);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.meeting_room_outlined, size: 19),
                  label: const Text(
                    'Vào phòng phản biện',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (_detail['canWatchRecording'] == true && recording != null)
                OutlinedButton.icon(
                  onPressed: () {
                    _openReview(assignmentId);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryDarkColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    side: const BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 19),
                  label: const Text(
                    'Xem lại sự kiện',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: _textSecondaryColor, size: 17),
        const SizedBox(width: 9),
        Text(
          '$label:',
          style: const TextStyle(
            color: _textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceCard(Map<String, dynamic> evidence) {
    final bool isPrivate = evidence['visibility']?.toString() == 'PRIVATE';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 6, 13),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: _primaryDarkColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence['originalFileName']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      isPrivate
                          ? Icons.lock_outline_rounded
                          : Icons.public_rounded,
                      color: _textSecondaryColor,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        isPrivate
                            ? 'Riêng tư trước khi sự kiện bắt đầu'
                            : 'Đang hiển thị công khai',
                        style: const TextStyle(
                          color: _textSecondaryColor,
                          fontSize: 10.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mở minh chứng',
            onPressed: () async {
              final String url = evidence['fileUrl']?.toString() ?? '';

              if (url.isEmpty) {
                return;
              }

              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            },
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: _primaryDarkColor,
              size: 20,
            ),
          ),
          if (_detail['canUploadEvidence'] == true)
            IconButton(
              tooltip: 'Xóa minh chứng',
              onPressed: () {
                _deleteEvidence((evidence['id'] as num?)?.toInt() ?? 0);
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: _errorColor,
                size: 21,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyEvidenceState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: const Column(
        children: [
          Icon(Icons.folder_open_outlined, color: Color(0xFF9AA49E), size: 32),
          SizedBox(height: 10),
          Text(
            'Chưa có minh chứng nào',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadEvidenceButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _uploadEvidence,
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryDarkColor,
          backgroundColor: _surfaceColor,
          side: const BorderSide(color: _primaryColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.upload_file_rounded, size: 20),
        label: const Text(
          'Tải lên minh chứng',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final String status = _detail['status']?.toString() ?? 'SCHEDULED';

    final String role = _detail['myRole']?.toString() ?? 'AUDIENCE';

    final List<Map<String, dynamic>> assignments =
        List<Map<String, dynamic>>.from(_detail['assignments'] ?? const []);

    final List<Map<String, dynamic>> myAssignments = assignments.where((
      Map<String, dynamic> assignment,
    ) {
      return assignment['myRole']?.toString() != 'AUDIENCE';
    }).toList();

    final Map<String, dynamic> primaryAssignment = myAssignments.isNotEmpty
        ? myAssignments.first
        : Map<String, dynamic>.from(_detail['myAssignment'] ?? const {});

    final List<Map<String, dynamic>> evidences =
        List<Map<String, dynamic>>.from(
          primaryAssignment['evidences'] ?? const [],
        );

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadDetail,
              color: _primaryColor,
              backgroundColor: _surfaceColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEventOverview(status: status, role: role),
                          if (myAssignments.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _buildSectionTitle(
                              title: 'Các phiên của bạn',
                              icon: Icons.view_agenda_outlined,
                            ),
                            const SizedBox(height: 14),
                            ...myAssignments.map(_buildAssignmentCard),
                            const SizedBox(height: 18),
                            _buildSectionTitle(
                              title: 'Minh chứng',
                              icon: Icons.folder_open_outlined,
                            ),
                            const SizedBox(height: 14),
                            if (evidences.isEmpty)
                              _buildEmptyEvidenceState()
                            else
                              ...evidences.map(_buildEvidenceCard),
                            if (_detail['canUploadEvidence'] == true) ...[
                              const SizedBox(height: 8),
                              _buildUploadEvidenceButton(),
                            ],
                          ],
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
