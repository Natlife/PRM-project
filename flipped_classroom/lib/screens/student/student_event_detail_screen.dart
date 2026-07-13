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
  bool _isLoading = true;
  Map<String, dynamic> _detail = {};

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final detail = await EventService().getStudentEventDetail(widget.eventId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải sự kiện: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '';
    final value = raw.toString();
    final parts = value.split('T');
    if (parts.length != 2) return value;
    final date = parts.first.split('-');
    final time = parts.last.split(':');
    if (date.length == 3 && time.length >= 2) {
      return '${date[2]}/${date[1]}/${date[0]} ${time[0]}:${time[1]}';
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
        return 'Chua dien ra';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'LIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.redAccent;
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

  Future<void> _uploadEvidence({int? assignmentId}) async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      List<int>? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      }
      if (bytes == null) return;
      await EventService().uploadStudentEvidence(
        widget.eventId,
        bytes,
        file.name,
        assignmentId: assignmentId,
      );
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải lên: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteEvidence(int assetId) async {
    try {
      await EventService().deleteStudentEvidence(assetId);
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openDefenseRoom(int assignmentId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDefenseRoomScreen(
          eventId: widget.eventId,
          assignmentId: assignmentId,
        ),
      ),
    );
    if (result != null) {
      await _loadDetail();
    }
  }

  Future<void> _openReview(int assignmentId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentEventReviewScreen(
          eventId: widget.eventId,
          assignmentId: assignmentId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _detail['status']?.toString() ?? 'SCHEDULED';
    final role = _detail['myRole']?.toString() ?? 'AUDIENCE';
    final assignments = List<Map<String, dynamic>>.from(
      _detail['assignments'] ?? const [],
    );
    final myAssignments = assignments
        .where((assignment) => assignment['myRole']?.toString() != 'AUDIENCE')
        .toList();
    final primaryAssignment = myAssignments.isNotEmpty
        ? myAssignments.first
        : Map<String, dynamic>.from(_detail['myAssignment'] ?? const {});
    final evidences = List<Map<String, dynamic>>.from(
      primaryAssignment['evidences'] ?? const [],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Chi tiết sự kiện',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
            )
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _detail['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(_detail['classroomCode'] ?? ''),
                        const SizedBox(height: 6),
                        Text('Vai trò của bạn: ${_roleLabel(role)}'),
                        const SizedBox(height: 6),
                        Text('Bắt đầu: ${_formatDateTime(_detail['startAt'])}'),
                        const SizedBox(height: 6),
                        Text('Kết thúc: ${_formatDateTime(_detail['endAt'])}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (assignments.isNotEmpty) ...[
                    const Text(
                      'Các phiên thuyết trình',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...assignments.map((assignment) {
                      final assignmentId =
                          (assignment['id'] as num?)?.toInt() ?? 0;
                      final assignmentRole =
                          assignment['myRole']?.toString() ?? 'AUDIENCE';
                      final recording =
                          assignment['recording'] as Map<String, dynamic>?;
                      final assignmentEvidences =
                          List<Map<String, dynamic>>.from(
                            assignment['evidences'] ?? const [],
                          );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Phiên ${assignment['orderIndex'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (assignment['status']?.toString() ==
                                                    'REVIEWED'
                                                ? Colors.green
                                                : Colors.orange)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _assignmentStatusLabel(
                                      assignment['status']?.toString() ??
                                          'PENDING',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          assignment['status']?.toString() ==
                                              'REVIEWED'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Thuyết trình: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        assignment['presenterGroupName'] ??
                                        assignment['presenterStudentName'] ??
                                        '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Phản biện: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        assignment['reviewerStudentName'] ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (assignmentRole != 'AUDIENCE') ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF7EC07E,
                                  ).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Vai trò của bạn: ${_roleLabel(assignmentRole)}',
                                  style: const TextStyle(
                                    color: Color(0xFF7EC07E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                            const Divider(height: 24),
                            const Text(
                              'Minh chứng của phiên',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (assignmentEvidences.isEmpty && recording == null)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Chưa có minh chứng nào',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black38,
                                  ),
                                ),
                              )
                            else ...[
                              if (recording != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF0F172A).withOpacity(0.03),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.play_circle_outline,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              recording['originalFileName'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Bản ghi/Minh chứng do giáo viên tải lên',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        iconSize: 18,
                                        onPressed: () async {
                                          final url = recording['fileUrl']?.toString() ?? '';
                                          if (url.isEmpty) return;
                                          await launchUrl(
                                            Uri.parse(url),
                                            mode: LaunchMode.externalApplication,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.open_in_new,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ...assignmentEvidences.map((evidence) {
                                final isPrivate = evidence['visibility'] == 'PRIVATE';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF0F172A).withOpacity(0.03),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file_outlined,
                                        size: 16,
                                        color: Color(0xFF7EC07E),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              evidence['originalFileName'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isPrivate
                                                  ? 'Riêng tư trước khi sự kiện bắt đầu'
                                                  : 'Hiển thị công khai',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isPrivate ? Colors.orange : Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        iconSize: 18,
                                        onPressed: () async {
                                          final url = evidence['fileUrl']?.toString() ?? '';
                                          if (url.isEmpty) return;
                                          await launchUrl(
                                            Uri.parse(url),
                                            mode: LaunchMode.externalApplication,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.open_in_new,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (_detail['canUploadEvidence'] == true &&
                                          assignmentRole == 'PRESENTER')
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          iconSize: 18,
                                          onPressed: () => _deleteEvidence(
                                            (evidence['id'] as num?)?.toInt() ?? 0,
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            if (_detail['canUploadEvidence'] == true &&
                                assignmentRole == 'PRESENTER') ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF7EC07E),
                                  side: const BorderSide(
                                    color: Color(0xFF7EC07E),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () =>
                                    _uploadEvidence(assignmentId: assignmentId),
                                icon: const Icon(Icons.upload_file, size: 14),
                                label: const Text(
                                  'Tải lên minh chứng',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (_detail['canJoinRoom'] == true)
                                  ElevatedButton(
                                    onPressed: () =>
                                        _openDefenseRoom(assignmentId),
                                    child: const Text('Vào phòng phản biện'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: const Color(0xFF7EC07E),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                if (_detail['canWatchRecording'] == true &&
                                    recording != null)
                                  ElevatedButton(
                                    onPressed: () => _openReview(assignmentId),
                                    child: const Text('Xem lại sự kiện'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}
