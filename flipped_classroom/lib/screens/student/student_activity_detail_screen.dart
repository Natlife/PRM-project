import 'package:flutter/material.dart';

import '../../services/activity_service.dart';

class StudentActivityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const StudentActivityDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  State<StudentActivityDetailScreen> createState() => _StudentActivityDetailScreenState();
}

class _StudentActivityDetailScreenState extends State<StudentActivityDetailScreen> {
  final TextEditingController _replyController = TextEditingController();

  bool _isLoading = true;
  int? _submissionId;
  String _title = '';
  String _type = '';
  String _deadline = '';
  String _description = '';
  String _status = 'Chua lam';
  String _submissionStatus = 'NOT_SUBMITTED';
  String _activityWorkflowStatus = '';
  String? _submittedAt;
  String? _createdAt;
  String? _updatedAt;
  int _attachmentCount = 0;
  int _commentCount = 0;
  dynamic _score;
  dynamic _maxScore;
  String _teacherFeedback = '';
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _title = widget.activity['title']?.toString() ?? '';
    _type = widget.activity['type']?.toString() ?? '';
    _deadline = widget.activity['deadline']?.toString() ?? '';
    _description = widget.activity['description']?.toString() ?? '';
    _status = widget.activity['status']?.toString() ?? 'Chua lam';
    _submissionStatus = widget.activity['submissionStatus']?.toString() ?? 'NOT_SUBMITTED';
    _score = widget.activity['score'];
    _maxScore = widget.activity['maxScore'];
    _teacherFeedback = widget.activity['teacherFeedback']?.toString() ?? '';
    _loadActivityDetail();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _formatDateTime(dynamic rawValue) {
    if (rawValue == null) {
      return '';
    }
    final raw = rawValue.toString();
    final parts = raw.split('T');
    if (parts.length != 2) {
      return raw;
    }
    final date = parts.first.split('-');
    final time = parts.last.split(':');
    if (date.length == 3 && time.length >= 2) {
      return '${date[2]}/${date[1]}/${date[0]} ${time[0]}:${time[1]}';
    }
    return raw;
  }

  Future<void> _loadActivityDetail() async {
    final activityId = (widget.activity['id'] as num?)?.toInt();
    if (activityId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final detail = await ActivityService().getStudentActivityDetail(activityId);
      final submission = await ActivityService().getStudentSubmission(activityId);
      List<Map<String, dynamic>> comments = [];
      final submissionId = (submission['id'] as num?)?.toInt();
      if (submissionId != null && submission['status'] != 'NOT_SUBMITTED') {
        comments = await ActivityService().getSubmissionComments(submissionId);
      }

      if (!mounted) {
        return;
      }

      final submissionStatus = submission['status']?.toString() ?? 'NOT_SUBMITTED';
      final isDone = submissionStatus == 'SUBMITTED' ||
          submissionStatus == 'LATE_SUBMITTED' ||
          submissionStatus == 'GRADED';

      setState(() {
        _title = detail['title']?.toString() ?? _title;
        _description = detail['description']?.toString() ?? _description;
        _type = (detail['activityType'] == 'PRE_CLASS' || detail['activityType'] == 'BEFORE_CLASS')
            ? 'Truoc buoi hoc'
            : 'Trong buoi hoc';
        _deadline = 'Han: ${_formatDateTime(detail['dueAt']).split(' ').first}';
        _submissionId = submissionId;
        _submissionStatus = submissionStatus;
        _activityWorkflowStatus = detail['status']?.toString() ?? '';
        _submittedAt = submission['submittedAt']?.toString();
        _createdAt = detail['createdAt']?.toString();
        _updatedAt = detail['updatedAt']?.toString();
        _attachmentCount = submission['attachmentCount'] as int? ?? 0;
        _commentCount = submission['commentCount'] as int? ?? comments.length;
        _status = isDone ? 'Da lam' : 'Chua lam';
        _score = submission['score'];
        _maxScore = detail['maxScore'];
        _teacherFeedback = submission['teacherFeedback']?.toString() ?? '';
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student activity detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _submissionId == null) {
      return;
    }

    try {
      final created = await ActivityService().addSubmissionComment(
        _submissionId!,
        content: text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _comments.add(created);
        _commentCount = _comments.length;
        _replyController.clear();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong the gui trao doi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final submittedLabel = _submittedAt != null && _submittedAt!.isNotEmpty
        ? _formatDateTime(_submittedAt)
        : 'Chua nop bai';
    final createdLabel = _createdAt != null && _createdAt!.isNotEmpty
        ? _formatDateTime(_createdAt)
        : '';
    final updatedLabel = _updatedAt != null && _updatedAt!.isNotEmpty
        ? _formatDateTime(_updatedAt)
        : '';
    final scoreLabel = _score != null
        ? (_maxScore != null ? '$_score / $_maxScore' : _score.toString())
        : 'Chua co diem';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiet hoat dong',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTag(_type, const Color(0xFF7EC07E), true),
                              _buildTag(_status, _status == 'Da lam' ? const Color(0xFF7EC07E) : Colors.redAccent, false),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _deadline,
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF0F172A).withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Yeu cau',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                            ),
                            child: Text(
                              _description.isEmpty ? 'Chua co mo ta.' : _description,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF0F172A).withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Thong tin bai nop',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Trang thai nop bai: $_submissionStatus'),
                                const SizedBox(height: 6),
                                Text('Trang thai hoat dong: ${_activityWorkflowStatus.isEmpty ? 'N/A' : _activityWorkflowStatus}'),
                                const SizedBox(height: 6),
                                Text('Thoi gian nop: $submittedLabel'),
                                const SizedBox(height: 6),
                                Text('So minh chung da nop: $_attachmentCount'),
                                const SizedBox(height: 6),
                                Text('So trao doi: $_commentCount'),
                                const SizedBox(height: 6),
                                Text('Diem: $scoreLabel'),
                                if (createdLabel.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('Tao luc: $createdLabel'),
                                ],
                                if (updatedLabel.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('Cap nhat luc: $updatedLabel'),
                                ],
                              ],
                            ),
                          ),
                          if (_teacherFeedback.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Nhan xet cua giang vien',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                              ),
                              child: Text(
                                _teacherFeedback,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF0F172A).withOpacity(0.7),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          const Text(
                            'Trao doi voi giang vien',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_comments.isEmpty)
                            const Text(
                              'Chua co trao doi nao.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ..._comments.map((comment) {
                              final author = comment['authorName']?.toString() ?? 'Nguoi dung';
                              final content = comment['content']?.toString() ?? '';
                              final time = _formatDateTime(comment['createdAt']);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF0F172A).withOpacity(0.05),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      author,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      content,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF0F172A),
                                        height: 1.4,
                                      ),
                                    ),
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        time,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: const Color(0xFF0F172A).withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          const SizedBox(height: 12),
                          if (_submissionId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _replyController,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Nhap cau tra loi',
                                        hintStyle: TextStyle(
                                          color: const Color(0xFF0F172A).withOpacity(0.3),
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (_) => _sendReply(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: Color(0xFF7EC07E), size: 20),
                                    onPressed: _sendReply,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFF7EC07E),
        unselectedItemColor: const Color(0xFF0F172A).withOpacity(0.4),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Trang chu'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Lop hoc'),
          BottomNavigationBarItem(icon: Icon(Icons.group_work_outlined), label: 'Du an'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Thong bao'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Ca nhan'),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, bool filledGreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(filledGreen ? 0.12 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
