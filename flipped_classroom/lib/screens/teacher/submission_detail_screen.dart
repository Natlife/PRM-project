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
  State<SubmissionDetailScreen> createState() =>
      _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState
    extends State<SubmissionDetailScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _inputBackgroundColor = Color(0xFFF9FBFA);
  static const Color _softGreenColor = Color(0xFFEAF7F0);
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  final TextEditingController _commentController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

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

    final String raw = rawValue.toString();
    final List<String> parts = raw.split('T');

    if (parts.length != 2) {
      return raw;
    }

    final List<String> dateParts =
        parts.first.split('-');

    final List<String> timeParts =
        parts.last.split(':');

    if (dateParts.length == 3 &&
        timeParts.length >= 2) {
      return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]} '
          '${timeParts[0]}:${timeParts[1]}';
    }

    return raw;
  }

  Future<void> _loadSubmission() async {
    if (widget.submissionId == null) {
      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final Map<String, dynamic> detail =
          await ActivityService()
              .getTeacherSubmissionDetail(
        widget.submissionId!,
      );

      final List<dynamic> comments =
          await ActivityService()
              .getSubmissionComments(
        widget.submissionId!,
      );

      if (!mounted) {
        return;
      }

      final int? currentUserDbId =
          AuthService().currentUser?.dbId;

      setState(() {
        _studentName =
            detail['studentName']?.toString() ??
                _studentName;

        _submittedTime = _formatDateTime(
          detail['submittedAt'],
        );

        _status =
            detail['status']?.toString() ?? '';

        _score =
            detail['score']?.toString();

        _feedback =
            detail['teacherFeedback']?.toString();

        _attachmentCount =
            detail['attachmentCount'] as int? ?? 0;

        _submittedContent =
            detail['content']?.toString() ?? '';

        _commentsList = comments
            .map<Map<String, dynamic>>(
          (dynamic comment) {
            final int? authorId =
                (comment['authorId'] as num?)
                    ?.toInt();

            return {
              'author':
                  comment['authorName'] ??
                      'Người dùng',
              'content':
                  comment['content'] ?? '',
              'time': _formatDateTime(
                comment['createdAt'],
              ),
              'isMe':
                  currentUserDbId != null &&
                      authorId == currentUserDbId,
            };
          },
        ).toList();

        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Error loading submission detail: $error',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    final String text =
        _commentController.text.trim();

    if (text.isEmpty ||
        widget.submissionId == null ||
        _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final Map<String, dynamic> created =
          await ActivityService()
              .addSubmissionComment(
        widget.submissionId!,
        content: text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _commentsList.add({
          'author':
              created['authorName'] ??
                  'Giáo viên',
          'content':
              created['content'] ?? text,
          'time': _formatDateTime(
            created['createdAt'],
          ),
          'isMe': true,
        });

        _commentController.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController
                  .position.maxScrollExtent,
              duration:
                  const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể gửi nhận xét: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
      case 'COMPLETED':
      case 'GRADED':
        return const Color(0xFF22A06B);

      case 'LATE':
      case 'OVERDUE':
        return const Color(0xFFDC3D43);

      case 'PENDING':
      case 'DRAFT':
        return const Color(0xFFF59E0B);

      default:
        return const Color(0xFF718078);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      elevation: 0,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: _textPrimaryColor,
        ),
      ),
      titleSpacing: 0,
      title: const Text(
        'Chi tiết bài nộp',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          color: _primaryColor,
          strokeWidth: 2.8,
        ),
      ),
    );
  }

  Widget _buildStudentOverviewCard() {
    final Color statusColor =
        _getStatusColor(_status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color:
                _textPrimaryColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _softGreenColor,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _primaryDarkColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sinh viên',
                      style: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _studentName,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          color: _textSecondaryColor,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _submittedTime.isEmpty
                                ? 'Chưa có thời gian nộp bài'
                                : 'Nộp bài lúc: $_submittedTime',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                                  _textSecondaryColor,
                              fontSize: 11.5,
                              fontWeight:
                                  FontWeight.w500,
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
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 17),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color:
                    statusColor.withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    color: statusColor,
                    size: 7,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmissionOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.assignment_outlined,
            title: 'Tổng quan bài nộp',
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _buildStatisticCard(
                  icon: Icons.attach_file_rounded,
                  label: 'Tệp đính kèm',
                  value: '$_attachmentCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatisticCard(
                  icon: Icons.grade_outlined,
                  label: 'Điểm số',
                  value: _score ?? 'Chưa chấm',
                ),
              ),
            ],
          ),
          if (_submittedContent.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(
              height: 1,
              color: _borderColor,
            ),
            const SizedBox(height: 17),
            const Text(
              'Nội dung bài nộp',
              style: TextStyle(
                color: _textPrimaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _inputBackgroundColor,
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: _borderColor,
                ),
              ),
              child: Text(
                _submittedContent,
                style: const TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
          ],
          if (_feedback != null &&
              _feedback!.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Nhận xét giáo viên',
              style: TextStyle(
                color: _textPrimaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _softGreenColor,
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color:
                      _primaryColor.withOpacity(0.14),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.chat_outlined,
                    color: _primaryDarkColor,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _feedback!,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? countLabel,
  }) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: _softGreenColor,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: _primaryDarkColor,
            size: 18,
          ),
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
              color: _softGreenColor,
              borderRadius:
                  BorderRadius.circular(100),
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
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _softGreenColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: _primaryDarkColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.forum_outlined,
            title: 'Nhận xét',
            countLabel:
                '${_commentsList.length}',
          ),
          const SizedBox(height: 17),
          if (_commentsList.isEmpty)
            _buildEmptyComments()
          else
            ..._commentsList.map(
              (Map<String, dynamic> comment) {
                return _buildCommentBubble(
                  comment,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 25,
      ),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: Color(0xFF9AA49E),
            size: 29,
          ),
          SizedBox(height: 9),
          Text(
            'Chưa có nhận xét nào.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentBubble(
    Map<String, dynamic> comment,
  ) {
    final bool isMe =
        comment['isMe'] == true;

    final String author =
        comment['author']?.toString() ?? '';

    final String time =
        comment['time']?.toString() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(
              maxWidth: 340,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isMe
                  ? _softGreenColor
                  : _inputBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(
                  isMe ? 16 : 4,
                ),
                bottomRight: Radius.circular(
                  isMe ? 4 : 16,
                ),
              ),
              border: Border.all(
                color: isMe
                    ? _primaryColor.withOpacity(0.15)
                    : _borderColor,
              ),
            ),
            child: Text(
              comment['content']?.toString() ?? '',
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: Text(
              '$author • $time',
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

  Widget _buildContent() {
    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        30,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 720,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildStudentOverviewCard(),
                const SizedBox(height: 14),
                _buildSubmissionOverview(),
                const SizedBox(height: 14),
                _buildCommentsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
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
        border: Border(
          top: BorderSide(
            color: _borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _commentController,
              textInputAction:
                  TextInputAction.send,
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'Nhập nhận xét của bạn...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9AA49E),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: _inputBackgroundColor,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: _borderColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: _borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
              onFieldSubmitted: (_) {
                _addComment();
              },
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _isSending
                ? const Color(0xFF9AA49E)
                : _primaryColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap:
                  _isSending ? null : _addComment,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.1,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _buildContent(),
            ),
            _buildCommentInputBar(),
          ],
        ),
      ),
    );
  }
}