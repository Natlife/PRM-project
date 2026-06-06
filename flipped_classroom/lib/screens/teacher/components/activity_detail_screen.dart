import 'package:flutter/material.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityTitle;
  final String deadline;
  final String submissions;

  const ActivityDetailScreen({
    super.key,
    required this.activityTitle,
    required this.deadline,
    required this.submissions,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final List<Map<String, dynamic>> _submissionsList = [
    {'name': 'Nguyễn Văn A', 'code': 'HE170123', 'submitted': true, 'time': '08:15 Hôm nay', 'score': 9.0},
    {'name': 'Trần Thị B', 'code': 'HE170456', 'submitted': true, 'time': '19:40 Hôm qua', 'score': 8.5},
    {'name': 'Lê Văn C', 'code': 'HE170789', 'submitted': false, 'time': '', 'score': null},
    {'name': 'Phạm Minh D', 'code': 'HE170999', 'submitted': true, 'time': '07:30 Hôm nay', 'score': null},
    {'name': 'Hoàng Văn E', 'code': 'HE171111', 'submitted': true, 'time': '21:10 Hôm qua', 'score': 7.5},
    {'name': 'Đỗ Thị F', 'code': 'HE171222', 'submitted': false, 'time': '', 'score': null},
    {'name': 'Nguyễn Đức G', 'code': 'HE171333', 'submitted': true, 'time': '22:15 Hôm qua', 'score': null},
  ];

  void _showGradeDialog(int index) {
    final submission = _submissionsList[index];
    final scoreController = TextEditingController(
      text: submission['score'] != null ? submission['score'].toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Chấm điểm: ${submission['name']}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: scoreController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập điểm (0 - 10)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              fillColor: const Color(0xFF0F172A),
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final double? score = double.tryParse(scoreController.text);
                if (score != null && score >= 0 && score <= 10) {
                  setState(() {
                    _submissionsList[index]['score'] = score;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã chấm điểm ${score.toString()} cho ${submission['name']}!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập điểm hợp lệ từ 0 đến 10!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chi tiết hoạt động',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activityTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(width: 6),
                            Text(
                              'Hạn chót: ${widget.deadline}',
                              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A57FF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.submissions,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF8F8DFF), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 20.0, top: 8.0, bottom: 12.0),
              child: Text(
                'Danh sách nộp bài',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final submission = _submissionsList[index];
                  final isSubmitted = submission['submitted'] as bool;
                  final hasScore = submission['score'] != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSubmitted ? const Color(0xFF2E8EFF).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
                          radius: 18,
                          child: Icon(
                            isSubmitted ? Icons.check_circle_outline : Icons.pending_outlined,
                            color: isSubmitted ? const Color(0xFF2E8EFF) : Colors.white24,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                submission['name'],
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSubmitted ? 'Nộp lúc: ${submission['time']}' : 'Chưa nộp bài',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSubmitted ? Colors.white54 : Colors.redAccent.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSubmitted) ...[
                          if (hasScore) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5A57FF).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${submission['score']} đ',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8F8DFF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            onPressed: () => _showGradeDialog(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A57FF),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              hasScore ? 'Sửa' : 'Chấm',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ] else ...[
                          const Text(
                            '-',
                            style: TextStyle(color: Colors.white24, fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                childCount: _submissionsList.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}
