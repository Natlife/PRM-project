import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/event_service.dart';
import 'student_defense_room_screen.dart';
import 'student_event_review_screen.dart';

class StudentEventDetailScreen extends StatefulWidget {
  final int eventId;

  const StudentEventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<StudentEventDetailScreen> createState() => _StudentEventDetailScreenState();
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
          content: Text('Loi tai chi tiet su kien: $e'),
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
        return 'Dang dien ra';
      case 'COMPLETED':
        return 'Da hoan thanh';
      case 'CANCELLED':
        return 'Da huy';
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
        return 'Nguoi thuyet trinh';
      case 'REVIEWER':
        return 'Nguoi phan bien';
      default:
        return 'Khan gia';
    }
  }

  String _assignmentStatusLabel(String status) {
    switch (status) {
      case 'REVIEWED':
        return 'Da review';
      case 'PENDING':
      default:
        return 'Chua review';
    }
  }

  Future<void> _uploadEvidence() async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      List<int>? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      }
      if (bytes == null) return;
      await EventService().uploadStudentEvidence(widget.eventId, bytes, file.name);
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi upload minh chung: $e'),
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
          content: Text('Loi xoa minh chung: $e'),
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
          'Chi tiet su kien',
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
                        Text('Vai tro cua ban: ${_roleLabel(role)}'),
                        const SizedBox(height: 6),
                        Text('Bat dau: ${_formatDateTime(_detail['startAt'])}'),
                        const SizedBox(height: 6),
                        Text('Ket thuc: ${_formatDateTime(_detail['endAt'])}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (myAssignments.isNotEmpty) ...[
                    const Text(
                      'Cac phien cua ban',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...myAssignments.map((assignment) {
                      final assignmentId =
                          (assignment['id'] as num?)?.toInt() ?? 0;
                      final assignmentRole =
                          assignment['myRole']?.toString() ?? 'AUDIENCE';
                      final recording =
                          assignment['recording'] as Map<String, dynamic>?;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Phien ${assignment['orderIndex'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  _assignmentStatusLabel(
                                    assignment['status']?.toString() ?? 'PENDING',
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        assignment['status']?.toString() == 'REVIEWED'
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              assignment['presenterGroupName'] ??
                                  assignment['presenterStudentName'] ??
                                  '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text('Vai tro: ${_roleLabel(assignmentRole)}'),
                            const SizedBox(height: 4),
                            Text(
                              'Phan bien: ${assignment['reviewerStudentName'] ?? ''}',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (_detail['canJoinRoom'] == true)
                                  ElevatedButton(
                                    onPressed: () => _openDefenseRoom(assignmentId),
                                    child: const Text('Vao phong phan bien'),
                                  ),
                                if (_detail['canWatchRecording'] == true &&
                                    recording != null)
                                  ElevatedButton(
                                    onPressed: () => _openReview(assignmentId),
                                    child: const Text('Xem lai su kien'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    const Text(
                      'Minh chung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (evidences.isEmpty)
                      const Text('Chua co minh chung nao')
                    else
                      ...evidences.map(
                        (evidence) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      evidence['originalFileName'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      evidence['visibility'] == 'PRIVATE'
                                          ? 'Rieng tu truoc khi su kien bat dau'
                                          : 'Dang hien thi cong khai',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFF0F172A)
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final url = evidence['fileUrl']?.toString() ?? '';
                                  if (url.isEmpty) return;
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: const Icon(Icons.open_in_new),
                              ),
                              if (_detail['canUploadEvidence'] == true)
                                IconButton(
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
                        ),
                      ),
                    if (_detail['canUploadEvidence'] == true) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _uploadEvidence,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Tai len minh chung'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
