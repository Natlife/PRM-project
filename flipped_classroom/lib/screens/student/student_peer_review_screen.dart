import 'package:flutter/material.dart';
import '../../services/peer_review_service.dart';
import '../../services/project_service.dart';

class StudentPeerReviewScreen extends StatefulWidget {
  final int classroomId;
  final String classCode;

  const StudentPeerReviewScreen({
    super.key,
    required this.classroomId,
    required this.classCode,
  });

  @override
  State<StudentPeerReviewScreen> createState() => _StudentPeerReviewScreenState();
}

class _StudentPeerReviewScreenState extends State<StudentPeerReviewScreen> {
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
          (review['reviewedGroupId'] as num).toInt(): review,
      };

      final List<Map<String, dynamic>> loadedGroups = [];
      for (final target in targets) {
        final int groupId = (target['id'] as num).toInt();
        final review = reviewByGroupId[groupId];

        List<String> members = [];
        try {
          final detail = await ProjectService().getTeacherProjectGroupDetail(groupId);
          members = (detail['members'] as List<dynamic>? ?? [])
              .map((member) => member['fullName'] as String? ?? 'Thanh vien')
              .toList();
        } catch (_) {}

        loadedGroups.add({
          'id': groupId,
          'name': target['groupName'] ?? 'Nhom',
          'projectName': target['projectName'] ?? 'Du an',
          'members': members,
          'scoreCode': (review?['codeQualityScore'] as num?)?.toDouble() ?? 0.0,
          'scoreUI': (review?['uiUxScore'] as num?)?.toDouble() ?? 0.0,
          'scoreFeature': (review?['featureScore'] as num?)?.toDouble() ?? 0.0,
          'scorePresentation':
              (review?['presentationScore'] as num?)?.toDouble() ?? 0.0,
          'comment': review?['comment'] ?? '',
          'isSubmitted': review != null,
        });
      }

      if (!mounted) return;
      setState(() {
        _peerGroups = loadedGroups;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong tai duoc danh sach danh gia cheo: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
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

  Widget _buildStarRating(
    String label,
    double currentScore,
    ValueChanged<double> onRatingChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              currentScore == 0.0
                  ? 'Chua cham'
                  : '${currentScore.toStringAsFixed(1)} / 5.0',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: currentScore == 0.0
                    ? Colors.grey
                    : const Color(0xFF7EC07E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (starIndex) {
            final double starValue = starIndex + 1.0;
            return GestureDetector(
              onTap: () => onRatingChanged(starValue),
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  starValue <= currentScore
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: starValue <= currentScore
                      ? Colors.amber
                      : const Color(0xFFCBD5E1),
                  size: 30,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _submitReview() async {
    if (_selectedGroupIndex == null) return;

    final group = _peerGroups[_selectedGroupIndex!];
    if (group['scoreCode'] == 0.0 ||
        group['scoreUI'] == 0.0 ||
        group['scoreFeature'] == 0.0 ||
        group['scorePresentation'] == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui long danh gia du 4 tieu chi sao!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
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

      if (!mounted) return;
      setState(() {
        group['comment'] = response['comment'] ?? _commentController.text.trim();
        group['isSubmitted'] = true;
        _selectedGroupIndex = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Da gui danh gia cheo cho ${group['name']} thanh cong!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF7EC07E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gui danh gia that bai: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () {
            if (_selectedGroupIndex != null) {
              setState(() {
                _selectedGroupIndex = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _selectedGroupIndex != null
              ? 'Danh gia chi tiet'
              : 'Danh gia cheo - ${widget.classCode}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
              )
            : _selectedGroupIndex == null
                ? _buildGroupsList()
                : _buildGroupReviewDetail(),
      ),
    );
  }

  Widget _buildGroupsList() {
    if (_peerGroups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Hien tai khong co nhom nao de danh gia cheo.',
            style: TextStyle(color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPeerGroups,
      color: const Color(0xFF7EC07E),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20.0),
        itemCount: _peerGroups.length,
        itemBuilder: (context, index) {
          final group = _peerGroups[index];
          final isSubmitted = group['isSubmitted'] == true;
          final members = (group['members'] as List<dynamic>).cast<String>();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSubmitted
                      ? const Color(0xFF7EC07E).withOpacity(0.3)
                      : const Color(0xFF0F172A).withOpacity(0.05),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _selectGroup(index),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSubmitted
                              ? const Color(0xFF7EC07E).withOpacity(0.12)
                              : const Color(0xFF0F172A).withOpacity(0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isSubmitted ? Icons.check_circle : Icons.group_outlined,
                            color: isSubmitted
                                ? const Color(0xFF7EC07E)
                                : const Color(0xFF0F172A).withOpacity(0.5),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  group['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (isSubmitted)
                                  const Text(
                                    'Da danh gia',
                                    style: TextStyle(
                                      color: Color(0xFF7EC07E),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              group['projectName'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF0F172A).withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              members.isEmpty
                                  ? 'Chua co danh sach thanh vien'
                                  : 'Thanh vien: ${members.join(', ')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF0F172A).withOpacity(0.4),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupReviewDetail() {
    final group = _peerGroups[_selectedGroupIndex!];
    final isSubmitted = group['isSubmitted'] == true;
    final members = (group['members'] as List<dynamic>).cast<String>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF7EC07E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group['projectName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thanh vien:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  members.isEmpty ? 'Chua co du lieu' : members.join(', '),
                  style: TextStyle(
                    color: const Color(0xFF0F172A).withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cham diem va nhan xet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildStarRating(
            'Chat luong ma nguon',
            group['scoreCode'],
            isSubmitted
                ? (_) {}
                : (val) => setState(() => group['scoreCode'] = val),
          ),
          _buildStarRating(
            'Giao dien va trai nghiem',
            group['scoreUI'],
            isSubmitted
                ? (_) {}
                : (val) => setState(() => group['scoreUI'] = val),
          ),
          _buildStarRating(
            'Tinh nang ung dung',
            group['scoreFeature'],
            isSubmitted
                ? (_) {}
                : (val) => setState(() => group['scoreFeature'] = val),
          ),
          _buildStarRating(
            'Thuyet trinh va slide',
            group['scorePresentation'],
            isSubmitted
                ? (_) {}
                : (val) => setState(() => group['scorePresentation'] = val),
          ),
          const Text(
            'Nhan xet chi tiet:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.1)),
            ),
            child: TextField(
              controller: _commentController,
              enabled: !isSubmitted,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              decoration: const InputDecoration(
                hintText: 'Nhap nhan xet chi tiet cho nhom...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!isSubmitted)
            ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7EC07E),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Gui danh gia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7EC07E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF7EC07E).withOpacity(0.3),
                ),
              ),
              child: const Center(
                child: Text(
                  'Ban da hoan thanh danh gia cheo cho nhom nay.',
                  style: TextStyle(
                    color: Color(0xFF7EC07E),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
