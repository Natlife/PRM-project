import 'package:flutter/material.dart';

import '../../services/activity_service.dart';
import '../../services/auth_service.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final int? submissionId;
  final String studentName;
  final String submittedTime;

  const SubmissionDetailScreen({
    super.key,
    this.submissionId,
    required this.studentName,
    required this.submittedTime,
  });

  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  String _studentName = '';
  String _submittedTime = '';
  String _status = '';
  String? _score;
  String? _feedback;
  int _attachmentCount = 0;
  String _submittedContent = '';
  List<Map<String, dynamic>> _commentsList = [];

  @override
  void initState() {
    super.initState();
    _studentName = widget.studentName;
    _submittedTime = widget.submittedTime;
    _loadSubmission();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
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
    final dateParts = parts.first.split('-');
    final timeParts = parts.last.split(':');
    if (dateParts.length == 3 && timeParts.length >= 2) {
      return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]} ${timeParts[0]}:${timeParts[1]}';
    }
    return raw;
  }

  Future<void> _loadSubmission() async {
    if (widget.submissionId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final detail = await ActivityService().getTeacherSubmissionDetail(widget.submissionId!);
      final comments = await ActivityService().getSubmissionComments(widget.submissionId!);

      if (!mounted) {
        return;
      }

      final currentUserDbId = AuthService().currentUser?.dbId;

      setState(() {
        _studentName = detail['studentName']?.toString() ?? _studentName;
        _submittedTime = _formatDateTime(detail['submittedAt']);
        _status = detail['status']?.toString() ?? '';
        _score = detail['score']?.toString();
        _feedback = detail['teacherFeedback']?.toString();
        _attachmentCount = detail['attachmentCount'] as int? ?? 0;
        _submittedContent = detail['content']?.toString() ?? '';
        _commentsList = comments
            .map<Map<String, dynamic>>(
              (comment) {
                final authorId = (comment['authorId'] as num?)?.toInt();
                return {
                  'author': comment['authorName'] ?? 'Người dùng',
                  'content': comment['content'] ?? '',
                  'time': _formatDateTime(comment['createdAt']),
                  'isMe': currentUserDbId != null && authorId == currentUserDbId,
                };
              },
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading submission detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.submissionId == null || _isSending) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final created = await ActivityService().addSubmissionComment(
        widget.submissionId!,
        content: text,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _commentsList.add({
          'author': created['authorName'] ?? 'Giáo viên',
          'content': created['content'] ?? text,
          'time': _formatDateTime(created['createdAt']),
          'isMe': true,
        });
        _commentController.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi nhận xét: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7EC07E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF0F172A),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Chi tiết bài nộp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
                    )
                  : ListView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _studentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _submittedTime.isEmpty
                                    ? 'Chưa có thời gian nộp bài'
                                    : 'Nộp bài lúc: $_submittedTime',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              if (_status.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Trạng thái: $_status',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tổng quan bài nộp',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Số tệp đính kèm: $_attachmentCount',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Điểm: ${_score ?? 'Chưa chấm'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              if (_submittedContent.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 6),
                                const Text(
                                  'Nội dung bài nộp:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _submittedContent,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                              if (_feedback != null && _feedback!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Nhận xét giáo viên: $_feedback',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Nhận xét',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_commentsList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Text(
                              'Chưa có nhận xét nào.',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          )
                        else
                          ..._commentsList.map((comment) {
                            final isMe = comment['isMe'] == true;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              alignment:
                                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment:
                                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF0F172A)
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Text(
                                      comment['content']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '${comment['author']} • ${comment['time']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _commentController,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập nhận xét của bạn...',
                        hintStyle: TextStyle(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                        ),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onFieldSubmitted: (_) => _addComment(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isSending ? null : _addComment,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isSending
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF7EC07E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Color(0xFF0F172A),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
