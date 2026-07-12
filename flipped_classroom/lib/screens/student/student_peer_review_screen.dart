import 'package:flutter/material.dart';

import '../../services/peer_review_service.dart';

class StudentPeerReviewScreen extends StatefulWidget {
  final int classroomId;
  final String classCode;

  const StudentPeerReviewScreen({
    super.key,
    required this.classroomId,
    required this.classCode,
  });

  @override
  State<StudentPeerReviewScreen> createState() =>
      _StudentPeerReviewScreenState();
}

class _StudentPeerReviewScreenState extends State<StudentPeerReviewScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _starColor = Color(0xFFF59E0B);

  final TextEditingController _commentController = TextEditingController();

  List<Map<String, dynamic>> _peerGroups = [];
  bool _isLoading = true;
  int? _selectedGroupIndex;

  @override
  void initState() {
    super.initState();
    _loadPeerGroups();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPeerGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final targets = await PeerReviewService().getPeerReviewTargets(
        widget.classroomId,
      );

      final submittedReviews = await PeerReviewService().getMyPeerReviews(
        widget.classroomId,
      );

      final Map<int, Map<String, dynamic>> reviewByGroupId = {
        for (final review in submittedReviews)
          ((review['reviewedGroupId'] as num).toInt()): review,
      };

      final List<Map<String, dynamic>> loadedGroups = [];

      for (final target in targets) {
        final int groupId = (target['id'] as num).toInt();

        final Map<String, dynamic>? review = reviewByGroupId[groupId];

        loadedGroups.add({
          'id': groupId,
          'name': target['groupName'] ?? 'Nhóm',
          'projectName': target['projectName'] ?? '',
          'memberCount': (target['memberCount'] as num?)?.toInt() ?? 0,
          'scoreCode': (review?['codeQualityScore'] as num?)?.toDouble() ?? 0.0,
          'scoreUI': (review?['uiUxScore'] as num?)?.toDouble() ?? 0.0,
          'scoreFeature': (review?['featureScore'] as num?)?.toDouble() ?? 0.0,
          'scorePresentation':
              (review?['presentationScore'] as num?)?.toDouble() ?? 0.0,
          'comment': review?['comment'] ?? '',
          'isSubmitted': review != null,
        });
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _peerGroups = loadedGroups;
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
          content: Text('Không tải được danh sách đánh giá chéo: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  void _selectGroup(int index) {
    setState(() {
      _selectedGroupIndex = index;
      _commentController.text = _peerGroups[index]['comment'] ?? '';
    });
  }

  Future<void> _submitReview() async {
    if (_selectedGroupIndex == null) {
      return;
    }

    final Map<String, dynamic> group = _peerGroups[_selectedGroupIndex!];

    if (group['scoreCode'] == 0.0 ||
        group['scoreUI'] == 0.0 ||
        group['scoreFeature'] == 0.0 ||
        group['scorePresentation'] == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đánh giá đủ 4 tiêu chí sao!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );

      return;
    }

    try {
      final response = await PeerReviewService().submitPeerReview(
        reviewedGroupId: group['id'] as int,
        codeQualityScore: (group['scoreCode'] as double).toInt(),
        uiUxScore: (group['scoreUI'] as double).toInt(),
        featureScore: (group['scoreFeature'] as double).toInt(),
        presentationScore: (group['scorePresentation'] as double).toInt(),
        comment: _commentController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        group['comment'] =
            response['comment'] ?? _commentController.text.trim();

        group['isSubmitted'] = true;
        _selectedGroupIndex = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi đánh giá chéo cho '
            '${group['name']} thành công!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _primaryDarkColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi đánh giá thất bại: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  void _handleBack() {
    if (_selectedGroupIndex != null) {
      setState(() {
        _selectedGroupIndex = null;
      });
    } else {
      Navigator.pop(context);
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
        onPressed: _handleBack,
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: Text(
        _selectedGroupIndex != null
            ? 'Đánh giá chi tiết'
            : 'Đánh giá chéo - ${widget.classCode}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _textPrimaryColor,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
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

  Widget _buildGroupsHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách nhóm',
          style: TextStyle(
            color: _textPrimaryColor,
            fontSize: 23,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Chọn một nhóm để chấm điểm và gửi nhận xét.',
          style: TextStyle(
            color: _textSecondaryColor,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, int index) {
    final bool isSubmitted = group['isSubmitted'] == true;

    final int memberCount = group['memberCount'] as int? ?? 0;

    final String groupName = group['name']?.toString() ?? '';

    final String projectName = group['projectName']?.toString() ?? '';

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _selectGroup(index);
        },
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSubmitted ? const Color(0xFFD4EDDF) : _borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: _textPrimaryColor.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSubmitted
                      ? const Color(0xFFEAF7F0)
                      : const Color(0xFFF1F4F2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isSubmitted
                      ? Icons.check_circle_outline_rounded
                      : Icons.groups_outlined,
                  color: isSubmitted ? _primaryDarkColor : _textSecondaryColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            groupName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textPrimaryColor,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isSubmitted) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7F0),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Đã đánh giá',
                              style: TextStyle(
                                color: _primaryDarkColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (projectName.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        projectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textSecondaryColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          color: Color(0xFF8B9690),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            memberCount > 0
                                ? 'Số thành viên: $memberCount'
                                : 'Backend không trả chi tiết '
                                      'thành viên ở màn này',
                            style: const TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 13),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA49E),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList() {
    if (_peerGroups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EmptyReviewIcon(),
              SizedBox(height: 22),
              Text(
                'Không có nhóm để đánh giá',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hiện tại không có nhóm nào để '
                'đánh giá chéo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondaryColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPeerGroups,
      color: _primaryColor,
      backgroundColor: _surfaceColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        itemCount: _peerGroups.length + 1,
        separatorBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return const SizedBox(height: 22);
          }

          return const SizedBox(height: 12);
        },
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _buildGroupsHeader();
          }

          final int groupIndex = index - 1;

          return _buildGroupCard(_peerGroups[groupIndex], groupIndex);
        },
      ),
    );
  }

  Widget _buildGroupOverview(Map<String, dynamic> group) {
    final int memberCount = group['memberCount'] as int? ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.035),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: _primaryDarkColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name']?.toString() ?? '',
                  style: const TextStyle(
                    color: _primaryDarkColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group['projectName']?.toString() ?? '',
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 17,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      color: _textSecondaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        memberCount > 0
                            ? '$memberCount thành viên'
                            : 'Backend không trả chi tiết '
                                  'thành viên cho nhóm này.',
                        style: const TextStyle(
                          color: _textSecondaryColor,
                          fontSize: 12,
                          height: 1.4,
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

  Widget _buildSectionTitle() {
    return const Row(
      children: [
        _RatingSectionIcon(),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'Chấm điểm và nhận xét',
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

  Widget _buildStarRating(
    String label,
    double currentScore,
    ValueChanged<double> onRatingChanged,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: currentScore == 0
                      ? const Color(0xFFF1F4F2)
                      : const Color(0xFFFFF4D8),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  currentScore == 0
                      ? 'Chưa chấm'
                      : '${currentScore.toStringAsFixed(1)} / 5.0',
                  style: TextStyle(
                    color: currentScore == 0
                        ? _textSecondaryColor
                        : const Color(0xFFA46500),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: List<Widget>.generate(5, (int starIndex) {
              final double starValue = starIndex + 1.0;

              final bool isSelected = starValue <= currentScore;

              return IconButton(
                tooltip: '$starValue sao',
                onPressed: () {
                  onRatingChanged(starValue);
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(42, 42),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isSelected ? _starColor : const Color(0xFFC8D0CB),
                  size: 31,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentField(bool isSubmitted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhận xét chi tiết',
          style: TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _commentController,
          enabled: !isSubmitted,
          maxLines: 4,
          minLines: 4,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập nhận xét chi tiết cho nhóm...',
            hintStyle: const TextStyle(color: Color(0xFF9AA49E), fontSize: 13),
            filled: true,
            fillColor: isSubmitted ? const Color(0xFFF4F6F5) : _surfaceColor,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _borderColor),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _submitReview,
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.send_rounded, size: 19),
        label: const Text(
          'Gửi đánh giá',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSubmittedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD4EDDF)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: _primaryDarkColor,
            size: 20,
          ),
          SizedBox(width: 9),
          Flexible(
            child: Text(
              'Bạn đã hoàn thành đánh giá chéo '
              'cho nhóm này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryDarkColor,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupReviewDetail() {
    final Map<String, dynamic> group = _peerGroups[_selectedGroupIndex!];

    final bool isSubmitted = group['isSubmitted'] == true;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupOverview(group),
              const SizedBox(height: 28),
              _buildSectionTitle(),
              const SizedBox(height: 14),
              _buildStarRating(
                'Chất lượng mã nguồn',
                group['scoreCode'] as double,
                isSubmitted
                    ? (_) {}
                    : (double value) {
                        setState(() {
                          group['scoreCode'] = value;
                        });
                      },
              ),
              _buildStarRating(
                'Giao diện và trải nghiệm',
                group['scoreUI'] as double,
                isSubmitted
                    ? (_) {}
                    : (double value) {
                        setState(() {
                          group['scoreUI'] = value;
                        });
                      },
              ),
              _buildStarRating(
                'Tính năng ứng dụng',
                group['scoreFeature'] as double,
                isSubmitted
                    ? (_) {}
                    : (double value) {
                        setState(() {
                          group['scoreFeature'] = value;
                        });
                      },
              ),
              _buildStarRating(
                'Thuyết trình và slide',
                group['scorePresentation'] as double,
                isSubmitted
                    ? (_) {}
                    : (double value) {
                        setState(() {
                          group['scorePresentation'] = value;
                        });
                      },
              ),
              const SizedBox(height: 6),
              _buildCommentField(isSubmitted),
              const SizedBox(height: 24),
              if (!isSubmitted)
                _buildSubmitButton()
              else
                _buildSubmittedState(),
            ],
          ),
        ),
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
        child: _isLoading
            ? _buildLoadingState()
            : _selectedGroupIndex == null
            ? _buildGroupsList()
            : _buildGroupReviewDetail(),
      ),
    );
  }
}

class _EmptyReviewIcon extends StatelessWidget {
  const _EmptyReviewIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(
        Icons.rate_review_outlined,
        color: Color(0xFF167A52),
        size: 40,
      ),
    );
  }
}

class _RatingSectionIcon extends StatelessWidget {
  const _RatingSectionIcon();

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
        Icons.star_outline_rounded,
        color: Color(0xFF167A52),
        size: 19,
      ),
    );
  }
}
