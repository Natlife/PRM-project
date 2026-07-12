import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/event_service.dart';

class _EventPalette {
  const _EventPalette._();

  static const Color primary = Color(0xFF22A06B);
  static const Color primaryDark = Color(0xFF167A52);
  static const Color background = Color(0xFFF5F7F6);
  static const Color surface = Colors.white;
  static const Color inputBackground = Color(0xFFF9FBFA);
  static const Color softGreen = Color(0xFFEAF7F0);
  static const Color textPrimary = Color(0xFF17211B);
  static const Color textSecondary = Color(0xFF66736B);
  static const Color border = Color(0xFFE2E8E4);
  static const Color error = Color(0xFFDC3D43);
  static const Color warning = Color(0xFFF59E0B);
}

class TeacherEventDetailScreen extends StatefulWidget {
  final int eventId;

  const TeacherEventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<TeacherEventDetailScreen> createState() =>
      _TeacherEventDetailScreenState();
}

class _TeacherEventDetailScreenState
    extends State<TeacherEventDetailScreen> {
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
      final detail = await EventService().getTeacherEventDetail(
        widget.eventId,
      );

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
          content: Text(
            'Lỗi tải chi tiết sự kiện: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.error,
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

  Color _statusColor(String status) {
    switch (status) {
      case 'LIVE':
        return _EventPalette.primary;

      case 'COMPLETED':
        return const Color(0xFF718078);

      case 'CANCELLED':
        return _EventPalette.error;

      case 'SCHEDULED':
      default:
        return _EventPalette.warning;
    }
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'LIVE':
        return Icons.play_circle_outline_rounded;

      case 'COMPLETED':
        return Icons.check_circle_outline_rounded;

      case 'CANCELLED':
        return Icons.cancel_outlined;

      case 'SCHEDULED':
      default:
        return Icons.schedule_outlined;
    }
  }

  ButtonStyle _dialogTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: _EventPalette.textSecondary,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: _EventPalette.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  ButtonStyle _darkButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: _EventPalette.textPrimary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  ButtonStyle _outlineActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _EventPalette.primaryDark,
      backgroundColor: _EventPalette.softGreen,
      side: const BorderSide(
        color: _EventPalette.primary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  ButtonStyle _headerTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: _EventPalette.primaryDark,
      backgroundColor: _EventPalette.softGreen,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  InputDecoration _dialogInputDecoration({
    required String label,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(
        color: _EventPalette.textSecondary,
        fontSize: 13,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 13,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              color: _EventPalette.textSecondary,
              size: 20,
            ),
      filled: true,
      fillColor: _EventPalette.inputBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _EventPalette.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _EventPalette.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _EventPalette.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    try {
      await EventService().updateTeacherEvent(
        widget.eventId,
        {
          'status': status,
        },
      );

      await _loadDetail();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã cập nhật trạng thái sự kiện',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.primary,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi cập nhật trạng thái: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.error,
        ),
      );
    }
  }

  Future<void> _showAddQuestionBankDialog() async {
    final TextEditingController controller =
        TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _EventPalette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            22,
            22,
            22,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            22,
            10,
            22,
            8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          title: const Text(
            'Thêm câu hỏi mẫu',
            style: TextStyle(
              color: _EventPalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            minLines: 4,
            maxLines: 4,
            style: const TextStyle(
              color: _EventPalette.textPrimary,
              fontSize: 13.5,
              height: 1.5,
            ),
            decoration: _dialogInputDecoration(
              label: 'Nội dung câu hỏi',
              hintText:
                  'Nhập câu hỏi vào ngân hàng câu hỏi',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: _dialogTextButtonStyle(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              style: _primaryButtonStyle(),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }

    try {
      await EventService().addQuestionBankItem(
        widget.eventId,
        result,
      );

      await _loadDetail();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi thêm câu hỏi: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.error,
        ),
      );
    }
  }

  Future<void> _showAddAssignmentDialog() async {
    final List<Map<String, dynamic>> students =
        List<Map<String, dynamic>>.from(
      _detail['availableStudents'] ?? const [],
    );

    final List<Map<String, dynamic>> groups =
        List<Map<String, dynamic>>.from(
      _detail['availableGroups'] ?? const [],
    );

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lớp hiện chưa có sinh viên để phân công',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.warning,
        ),
      );

      return;
    }

    String assignmentType = 'INDIVIDUAL';

    int orderIndex =
        List<Map<String, dynamic>>.from(
              _detail['assignments'] ?? const [],
            ).length +
            1;

    int? presenterStudentId =
        (students.first['id'] as num?)?.toInt();

    int? reviewerStudentId = students.length > 1
        ? (students[1]['id'] as num?)?.toInt()
        : (students.first['id'] as num?)?.toInt();

    int? presenterGroupId = groups.isNotEmpty
        ? (groups.first['id'] as num?)?.toInt()
        : null;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            return AlertDialog(
              backgroundColor: _EventPalette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                22,
                22,
                22,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                22,
                10,
                22,
                8,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16,
              ),
              title: const Text(
                'Tạo phiên phản biện',
                style: TextStyle(
                  color: _EventPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: assignmentType,
                      isExpanded: true,
                      dropdownColor: _EventPalette.surface,
                      decoration: _dialogInputDecoration(
                        label: 'Kiểu phiên',
                        prefixIcon: Icons.people_outline,
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'INDIVIDUAL',
                          child: Text('Cá nhân'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'GROUP',
                          child: Text('Nhóm'),
                        ),
                      ],
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          assignmentType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: '$orderIndex',
                      keyboardType: TextInputType.number,
                      decoration: _dialogInputDecoration(
                        label: 'Thứ tự',
                        prefixIcon:
                            Icons.format_list_numbered,
                      ),
                      onChanged: (String value) {
                        orderIndex =
                            int.tryParse(value) ??
                                orderIndex;
                      },
                    ),
                    const SizedBox(height: 14),
                    if (assignmentType == 'INDIVIDUAL')
                      DropdownButtonFormField<int>(
                        initialValue:
                            presenterStudentId,
                        isExpanded: true,
                        dropdownColor:
                            _EventPalette.surface,
                        decoration:
                            _dialogInputDecoration(
                          label:
                              'Người thuyết trình',
                          prefixIcon:
                              Icons.record_voice_over_outlined,
                        ),
                        items: students.map(
                          (
                            Map<String, dynamic>
                                student,
                          ) {
                            return DropdownMenuItem<int>(
                              value: (student['id']
                                      as num?)
                                  ?.toInt(),
                              child: Text(
                                student['fullName'] ??
                                    student[
                                        'userName'] ??
                                    '',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (int? value) {
                          setDialogState(() {
                            presenterStudentId =
                                value;
                          });
                        },
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue:
                            presenterGroupId,
                        isExpanded: true,
                        dropdownColor:
                            _EventPalette.surface,
                        decoration:
                            _dialogInputDecoration(
                          label:
                              'Nhóm thuyết trình',
                          prefixIcon:
                              Icons.groups_outlined,
                        ),
                        items: groups.map(
                          (
                            Map<String, dynamic>
                                group,
                          ) {
                            return DropdownMenuItem<int>(
                              value: (group['id']
                                      as num?)
                                  ?.toInt(),
                              child: Text(
                                group['groupName'] ??
                                    '',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (int? value) {
                          setDialogState(() {
                            presenterGroupId = value;
                          });
                        },
                      ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue:
                          reviewerStudentId,
                      isExpanded: true,
                      dropdownColor:
                          _EventPalette.surface,
                      decoration:
                          _dialogInputDecoration(
                        label: 'Người phản biện',
                        prefixIcon:
                            Icons.rate_review_outlined,
                      ),
                      items: students.map(
                        (
                          Map<String, dynamic>
                              student,
                        ) {
                          return DropdownMenuItem<int>(
                            value:
                                (student['id'] as num?)
                                    ?.toInt(),
                            child: Text(
                              student['fullName'] ??
                                  student['userName'] ??
                                  '',
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (int? value) {
                        setDialogState(() {
                          reviewerStudentId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  style: _dialogTextButtonStyle(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  style: _primaryButtonStyle(),
                  child: const Text('Tạo'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await EventService().createEventAssignment(
        widget.eventId,
        {
          'assignmentType': assignmentType,
          if (assignmentType == 'INDIVIDUAL')
            'presenterStudentId':
                presenterStudentId,
          if (assignmentType == 'GROUP')
            'presenterGroupId': presenterGroupId,
          'reviewerStudentId': reviewerStudentId,
          'orderIndex': orderIndex,
        },
      );

      await _loadDetail();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi tạo phiên phản biện: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.error,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: _EventPalette.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _EventPalette.border,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.pop(context, true);
        },
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: _EventPalette.textPrimary,
        ),
      ),
      titleSpacing: 0,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _EventPalette.textPrimary,
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
          color: _EventPalette.primary,
          strokeWidth: 2.8,
        ),
      ),
    );
  }

  Widget _buildEventOverview({
    required String title,
    required String status,
  }) {
    final Color statusColor = _statusColor(status);

    final String description =
        _detail['description']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _EventPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _EventPalette.border,
        ),
        boxShadow: [
          BoxShadow(
            color: _EventPalette.textPrimary.withOpacity(
              0.04,
            ),
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
                  color: _EventPalette.softGreen,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: _EventPalette.primaryDark,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _detail['classroomCode']
                              ?.toString() ??
                          '',
                      style: const TextStyle(
                        color:
                            _EventPalette.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color:
                            _EventPalette.textPrimary,
                        fontSize: 20,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _statusIcon(status),
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Text(
            description.isNotEmpty
                ? description
                : 'Chưa có mô tả sự kiện.',
            style: const TextStyle(
              color: _EventPalette.textSecondary,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          _buildEventInformation(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (status == 'SCHEDULED')
                ElevatedButton.icon(
                  onPressed: () {
                    _updateStatus('LIVE');
                  },
                  style: _primaryButtonStyle(),
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Bắt đầu sự kiện',
                  ),
                ),
              if (status == 'LIVE')
                ElevatedButton.icon(
                  onPressed: () {
                    _updateStatus('COMPLETED');
                  },
                  style: _darkButtonStyle(),
                  icon: const Icon(
                    Icons.stop_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Kết thúc sự kiện',
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _showAddAssignmentDialog,
                style: _outlineActionButtonStyle(),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 19,
                ),
                label: const Text(
                  'Thêm phiên phản biện',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventInformation() {
    return Column(
      children: [
        _buildInformationRow(
          icon: Icons.schedule_outlined,
          label: 'Bắt đầu',
          value: _formatDateTime(
            _detail['startAt'],
          ),
        ),
        const SizedBox(height: 10),
        _buildInformationRow(
          icon: Icons.event_outlined,
          label: 'Kết thúc',
          value: _formatDateTime(
            _detail['endAt'],
          ),
        ),
        const SizedBox(height: 10),
        _buildInformationRow(
          icon: Icons.timer_outlined,
          label: 'Mỗi phiên',
          value:
              '${_detail['sessionDurationMinutes'] ?? 0} phút',
        ),
      ],
    );
  }

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _EventPalette.inputBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _EventPalette.softGreen,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: _EventPalette.primaryDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color:
                        _EventPalette.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        _EventPalette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onAction,
    required Widget child,
    required int count,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _EventPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: title,
            icon: icon,
            count: count,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required int count,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: _EventPalette.softGreen,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: _EventPalette.primaryDark,
            size: 18,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _EventPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _EventPalette.softGreen,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _EventPalette.primaryDark,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onAction,
          style: _headerTextButtonStyle(),
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard({
    required String message,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        color: _EventPalette.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF9AA49E),
            size: 30,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _EventPalette.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> question,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _EventPalette.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _EventPalette.softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: _EventPalette.primaryDark,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  question['content']?.toString() ??
                      '',
                  style: const TextStyle(
                    color:
                        _EventPalette.textPrimary,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Tạo bởi ${question['authorName'] ?? ''}',
                  style: const TextStyle(
                    color:
                        _EventPalette.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(
    Map<String, dynamic> assignment,
  ) {
    final dynamic presenter =
        assignment['presenterGroupName'] ??
            assignment['presenterStudentName'] ??
            'Chưa xác định';

    final dynamic reviewer =
        assignment['reviewerStudentName'] ??
            'Chưa xác định';

    final Map<String, dynamic>? recording =
        assignment['recording']
            as Map<String, dynamic>?;

    final bool isReviewed =
        assignment['status']?.toString() ==
            'REVIEWED';

    final Color statusColor = isReviewed
        ? _EventPalette.primary
        : _EventPalette.warning;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _EventPalette.inputBackground,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      statusColor.withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  isReviewed
                      ? Icons
                          .check_circle_outline_rounded
                      : Icons
                          .pending_actions_outlined,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Phiên ${assignment['orderIndex'] ?? ''}',
                  style: const TextStyle(
                    color:
                        _EventPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      statusColor.withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(100),
                ),
                child: Text(
                  isReviewed
                      ? 'Đã review'
                      : 'Chưa review',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAssignmentInformation(
            icon: Icons
                .record_voice_over_outlined,
            label: 'Thuyết trình',
            value: presenter.toString(),
          ),
          const SizedBox(height: 9),
          _buildAssignmentInformation(
            icon: Icons.rate_review_outlined,
            label: 'Phản biện',
            value: reviewer.toString(),
          ),
          if (recording != null) ...[
            const SizedBox(height: 12),
            Material(
              color: _EventPalette.softGreen,
              borderRadius:
                  BorderRadius.circular(13),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(13),
                onTap: () async {
                  final String url =
                      recording['fileUrl']
                              ?.toString() ??
                          '';

                  if (url.isEmpty) {
                    return;
                  }

                  await launchUrl(
                    Uri.parse(url),
                    mode:
                        LaunchMode.externalApplication,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color:
                            _EventPalette.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bản ghi: ${recording['originalFileName'] ?? ''}',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _EventPalette
                                .primaryDark,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color:
                            _EventPalette.primaryDark,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final bool? result =
                    await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (
                      BuildContext context,
                    ) {
                      return TeacherEventRoomScreen(
                        eventId: widget.eventId,
                        assignmentId:
                            (assignment['id'] as num?)
                                    ?.toInt() ??
                                0,
                      );
                    },
                  ),
                );

                if (result == true) {
                  await _loadDetail();
                }
              },
              style: _outlineActionButtonStyle(),
              icon: const Icon(
                Icons.meeting_room_outlined,
                size: 18,
              ),
              label: const Text(
                'Mở phòng review',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentInformation({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _EventPalette.textSecondary,
          size: 17,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: _EventPalette.textPrimary,
                fontSize: 12.5,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color:
                        _EventPalette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
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

  Widget _buildContent({
    required String title,
    required String status,
    required List<Map<String, dynamic>>
        questionBank,
    required List<Map<String, dynamic>>
        assignments,
  }) {
    return RefreshIndicator(
      color: _EventPalette.primary,
      onRefresh: _loadDetail,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          36,
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
                  _buildEventOverview(
                    title: title,
                    status: status,
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Ngân hàng câu hỏi',
                    icon: Icons.quiz_outlined,
                    actionLabel: 'Thêm',
                    onAction:
                        _showAddQuestionBankDialog,
                    count: questionBank.length,
                    child: questionBank.isEmpty
                        ? _buildEmptyCard(
                            message:
                                'Chưa có câu hỏi mẫu nào',
                            icon:
                                Icons.help_outline_rounded,
                          )
                        : Column(
                            children: questionBank
                                .map<Widget>(
                                  _buildQuestionCard,
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Phiên phản biện',
                    icon:
                        Icons.forum_outlined,
                    actionLabel: 'Tạo phiên',
                    onAction:
                        _showAddAssignmentDialog,
                    count: assignments.length,
                    child: assignments.isEmpty
                        ? _buildEmptyCard(
                            message:
                                'Chưa có phiên phản biện nào',
                            icon:
                                Icons.groups_outlined,
                          )
                        : Column(
                            children: assignments
                                .map<Widget>(
                                  _buildAssignmentCard,
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        _detail['title']?.toString() ??
            'Chi tiết sự kiện';

    final String status =
        _detail['status']?.toString() ??
            'SCHEDULED';

    final List<Map<String, dynamic>> assignments =
        List<Map<String, dynamic>>.from(
      _detail['assignments'] ?? const [],
    );

    final List<Map<String, dynamic>> questionBank =
        List<Map<String, dynamic>>.from(
      _detail['questionBank'] ?? const [],
    );

    return Scaffold(
      backgroundColor: _EventPalette.background,
      appBar: _buildAppBar(title),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? _buildLoadingState()
            : _buildContent(
                title: title,
                status: status,
                questionBank: questionBank,
                assignments: assignments,
              ),
      ),
    );
  }
}

class TeacherEventRoomScreen extends StatefulWidget {
  final int eventId;
  final int assignmentId;

  const TeacherEventRoomScreen({
    super.key,
    required this.eventId,
    required this.assignmentId,
  });

  @override
  State<TeacherEventRoomScreen> createState() =>
      _TeacherEventRoomScreenState();
}

class _TeacherEventRoomScreenState
    extends State<TeacherEventRoomScreen> {
  bool _isLoading = true;

  Map<String, dynamic> _detail = {};
  Map<String, dynamic>? _assignment;

  ButtonStyle _dialogTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: _EventPalette.textSecondary,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: _EventPalette.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  ButtonStyle _outlineActionButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _EventPalette.primaryDark,
      backgroundColor: _EventPalette.softGreen,
      side: const BorderSide(
        color: _EventPalette.primary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  InputDecoration _dialogInputDecoration({
    required String label,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(
        color: _EventPalette.textSecondary,
        fontSize: 13,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 13,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              color: _EventPalette.textSecondary,
              size: 20,
            ),
      filled: true,
      fillColor: _EventPalette.inputBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _EventPalette.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _EventPalette.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _EventPalette.primary,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final detail =
          await EventService().getTeacherEventDetail(
        widget.eventId,
      );

      final List<Map<String, dynamic>> assignments =
          List<Map<String, dynamic>>.from(
        detail['assignments'] ?? const [],
      );

      final Map<String, dynamic> assignment =
          assignments.firstWhere(
        (Map<String, dynamic> item) {
          return ((item['id'] as num?)?.toInt() ??
                  0) ==
              widget.assignmentId;
        },
        orElse: () => <String, dynamic>{},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _assignment =
            assignment.isEmpty ? null : assignment;
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
          content: Text(
            'Lỗi tải phòng review: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.error,
        ),
      );
    }
  }

  Future<void> _addLiveQuestion() async {
    final List<Map<String, dynamic>> bank =
        List<Map<String, dynamic>>.from(
      _detail['questionBank'] ?? const [],
    );

    String selectedContent = bank.isNotEmpty
        ? bank.first['content']?.toString() ?? ''
        : '';

    final TextEditingController controller =
        TextEditingController(
      text: selectedContent,
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            return AlertDialog(
              backgroundColor: _EventPalette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                22,
                22,
                22,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                22,
                10,
                22,
                8,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16,
              ),
              title: const Text(
                'Đặt câu hỏi',
                style: TextStyle(
                  color: _EventPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bank.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedContent.isEmpty
                                ? null
                                : selectedContent,
                        isExpanded: true,
                        dropdownColor:
                            _EventPalette.surface,
                        decoration:
                            _dialogInputDecoration(
                          label:
                              'Chọn từ ngân hàng',
                          prefixIcon:
                              Icons.quiz_outlined,
                        ),
                        items: bank.map(
                          (
                            Map<String, dynamic>
                                item,
                          ) {
                            final String content =
                                item['content']
                                        ?.toString() ??
                                    '';

                            return DropdownMenuItem<
                                String>(
                              value: content,
                              child: Text(
                                content,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            selectedContent = value;
                            controller.text = value;
                          });
                        },
                      ),
                    if (bank.isNotEmpty)
                      const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      minLines: 4,
                      maxLines: 4,
                      style: const TextStyle(
                        color:
                            _EventPalette.textPrimary,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                      decoration:
                          _dialogInputDecoration(
                        label: 'Nội dung câu hỏi',
                        hintText: 'Nhập câu hỏi',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: _dialogTextButtonStyle(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      controller.text.trim(),
                    );
                  },
                  style: _primaryButtonStyle(),
                  child: const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }

    try {
      await EventService().addTeacherLiveQuestion(
        widget.eventId,
        result,
        assignmentId: widget.assignmentId,
      );

      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi gửi câu hỏi: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.error,
        ),
      );
    }
  }

  Future<void> _uploadRecording() async {
    try {
      final FilePickerResult? result =
          await FilePicker.pickFiles(
        withData: true,
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final PlatformFile file =
          result.files.first;

      List<int>? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        bytes = await io.File(
          file.path!,
        ).readAsBytes();
      }

      if (bytes == null) {
        return;
      }

      await EventService().uploadRecording(
        widget.eventId,
        widget.assignmentId,
        bytes,
        file.name,
      );

      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi upload recording: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.error,
        ),
      );
    }
  }

  Future<void> _completeAssignment() async {
    try {
      await EventService().completeAssignment(
        widget.eventId,
        widget.assignmentId,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi hoàn tất phiên: $error',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _EventPalette.error,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _EventPalette.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _EventPalette.border,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.pop(context, false);
        },
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: _EventPalette.textPrimary,
        ),
      ),
      titleSpacing: 0,
      title: const Text(
        'Phòng review',
        style: TextStyle(
          color: _EventPalette.textPrimary,
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
          color: _EventPalette.primary,
          strokeWidth: 2.8,
        ),
      ),
    );
  }

  Widget _buildRoomOverview({
    required dynamic presenter,
    required dynamic reviewer,
    required Map<String, dynamic> assignment,
  }) {
    final String status =
        assignment['status']?.toString() ?? '';

    final bool isReviewed = status == 'REVIEWED';

    final Color statusColor = isReviewed
        ? _EventPalette.primary
        : _EventPalette.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _EventPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _EventPalette.border,
        ),
        boxShadow: [
          BoxShadow(
            color: _EventPalette.textPrimary.withOpacity(
              0.04,
            ),
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
                  color: _EventPalette.softGreen,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: _EventPalette.primaryDark,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Người thuyết trình',
                      style: TextStyle(
                        color:
                            _EventPalette.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      presenter.toString(),
                      style: const TextStyle(
                        color:
                            _EventPalette.textPrimary,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildRoomInformation(
            icon: Icons.rate_review_outlined,
            label: 'Người phản biện',
            value: reviewer.toString(),
          ),
          const SizedBox(height: 10),
          _buildRoomInformation(
            icon: isReviewed
                ? Icons
                    .check_circle_outline_rounded
                : Icons.pending_actions_outlined,
            label: 'Trạng thái',
            value: status,
            valueColor: statusColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInformation({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _EventPalette.inputBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: valueColor == null
                  ? _EventPalette.softGreen
                  : valueColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color:
                  valueColor ??
                  _EventPalette.primaryDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color:
                        _EventPalette.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        valueColor ??
                        _EventPalette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSection({
    required String title,
    required IconData icon,
    required int count,
    Widget? action,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _EventPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _EventPalette.softGreen,
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: _EventPalette.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color:
                        _EventPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _EventPalette.softGreen,
                  borderRadius:
                      BorderRadius.circular(100),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color:
                        _EventPalette.primaryDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 8),
                action,
              ],
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String message,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 25,
      ),
      decoration: BoxDecoration(
        color: _EventPalette.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF9AA49E),
            size: 29,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _EventPalette.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(
    Map<String, dynamic> evidence,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _EventPalette.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _EventPalette.softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: _EventPalette.primaryDark,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  evidence['originalFileName'] ??
                      '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        _EventPalette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  evidence['uploadedByName'] ??
                      '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        _EventPalette.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mở tệp',
            onPressed: () async {
              final String url =
                  evidence['fileUrl']?.toString() ??
                      '';

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
              color: _EventPalette.primaryDark,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(
    Map<String, dynamic> recording,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _EventPalette.softGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _EventPalette.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _EventPalette.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              color: _EventPalette.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  recording['originalFileName'] ??
                      '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        _EventPalette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bản ghi hiện tại',
                  style: TextStyle(
                    color:
                        _EventPalette.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mở bản ghi',
            onPressed: () async {
              final String url =
                  recording['fileUrl']
                          ?.toString() ??
                      '';

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
              color: _EventPalette.primaryDark,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> question,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _EventPalette.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _EventPalette.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _EventPalette.softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: _EventPalette.primaryDark,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  question['authorName'] ?? '',
                  style: const TextStyle(
                    color:
                        _EventPalette.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question['content'] ?? '',
                  style: const TextStyle(
                    color:
                        _EventPalette.textPrimary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required Map<String, dynamic> assignment,
    required dynamic presenter,
    required dynamic reviewer,
    required List<Map<String, dynamic>>
        questions,
    required List<Map<String, dynamic>>
        evidences,
    required Map<String, dynamic>? recording,
  }) {
    final bool isReviewed =
        (assignment['status']?.toString() ??
                'PENDING') ==
            'REVIEWED';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        36,
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
                _buildRoomOverview(
                  presenter: presenter,
                  reviewer: reviewer,
                  assignment: assignment,
                ),
                const SizedBox(height: 14),
                _buildRoomSection(
                  title: 'Minh chứng',
                  icon:
                      Icons.attach_file_rounded,
                  count: evidences.length,
                  action: OutlinedButton(
                    onPressed: _uploadRecording,
                    style:
                        _outlineActionButtonStyle(),
                    child: const Text(
                      'Upload recording',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (evidences.isEmpty)
                        _buildEmptyState(
                          message:
                              'Chưa có minh chứng nào',
                          icon: Icons
                              .insert_drive_file_outlined,
                        )
                      else
                        ...evidences.map<Widget>(
                          _buildEvidenceCard,
                        ),
                      if (recording != null) ...[
                        if (evidences.isNotEmpty)
                          const SizedBox(height: 6),
                        _buildRecordingCard(
                          recording,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildRoomSection(
                  title: 'Câu hỏi live',
                  icon: Icons.quiz_outlined,
                  count: questions.length,
                  action: ElevatedButton(
                    onPressed: _addLiveQuestion,
                    style: _primaryButtonStyle(),
                    child: const Text(
                      'Đặt câu hỏi',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                  child: questions.isEmpty
                      ? _buildEmptyState(
                          message:
                              'Chưa có câu hỏi nào',
                          icon:
                              Icons.help_outline,
                        )
                      : Column(
                          children: questions
                              .map<Widget>(
                                _buildQuestionCard,
                              )
                              .toList(),
                        ),
                ),
                if (!isReviewed) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _completeAssignment,
                      style:
                          ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor:
                            _EventPalette
                                .textPrimary,
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons
                            .check_circle_outline_rounded,
                        size: 19,
                      ),
                      label: const Text(
                        'Kết thúc phiên phản biện',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> assignment =
        _assignment ?? const <String, dynamic>{};

    final dynamic presenter =
        assignment['presenterGroupName'] ??
            assignment['presenterStudentName'] ??
            'Chưa xác định';

    final dynamic reviewer =
        assignment['reviewerStudentName'] ??
            'Chưa xác định';

    final List<Map<String, dynamic>> questions =
        List<Map<String, dynamic>>.from(
      assignment['questions'] ?? const [],
    );

    final List<Map<String, dynamic>> evidences =
        List<Map<String, dynamic>>.from(
      assignment['evidences'] ?? const [],
    );

    final Map<String, dynamic>? recording =
        assignment['recording']
            as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: _EventPalette.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? _buildLoadingState()
            : _buildContent(
                assignment: assignment,
                presenter: presenter,
                reviewer: reviewer,
                questions: questions,
                evidences: evidences,
                recording: recording,
              ),
      ),
    );
  }
}