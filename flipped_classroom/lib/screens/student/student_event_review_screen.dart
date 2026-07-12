import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/event_service.dart';

class StudentEventReviewScreen extends StatefulWidget {
  final int eventId;
  final int assignmentId;

  const StudentEventReviewScreen({
    super.key,
    required this.eventId,
    required this.assignmentId,
  });

  @override
  State<StudentEventReviewScreen> createState() => _StudentEventReviewScreenState();
}

class _StudentEventReviewScreenState extends State<StudentEventReviewScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _detail = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
          content: Text('Lỗi tải bản ghi sự kiện: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignments = List<Map<String, dynamic>>.from(
      _detail['assignments'] ?? const [],
    );
    final assignment = assignments.cast<Map<String, dynamic>?>().firstWhere(
          (item) => ((item?['id'] as num?)?.toInt() ?? 0) == widget.assignmentId,
          orElse: () => Map<String, dynamic>.from(_detail['myAssignment'] ?? const {}),
        ) ??
        <String, dynamic>{};
    final questions = List<Map<String, dynamic>>.from(
      assignment['questions'] ?? const [],
    );
    final recording = assignment['recording'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xem lại sự kiện',
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
          : ListView(
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
                      Text(
                        _detail['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_detail['classroomCode'] ?? ''),
                      if (recording != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final url = recording['fileUrl']?.toString() ?? '';
                            if (url.isEmpty) return;
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: Text(
                            recording['originalFileName'] ?? 'Mở bản ghi',
                          ),
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text('Giảng viên chưa tải bản ghi cho phiên này'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Câu hỏi đã đặt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                if (questions.isEmpty)
                  const Text('Không có câu hỏi nào được lưu')
                else
                  ...questions.map(
                    (question) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question['authorName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(question['content'] ?? ''),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
