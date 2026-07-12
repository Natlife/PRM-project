import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/classroom_service.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _inputBackgroundColor = Color(0xFFF9FBFA);
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _descController = TextEditingController();

  final TextEditingController _subjectController = TextEditingController();

  String _selectedSemester = 'SU26';
  String _selectedDay = 'Thứ 2';
  String _selectedSlot = 'Slot 1 (7:30-9:50)';

  bool _isSubmitting = false;

  late String _classCodeSuffix;

  final List<String> _semesters = ['SU26', 'FA26', 'SP26', 'HK1 2026'];

  final List<String> _days = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ];

  final List<Map<String, String>> _slots = const [
    {
      'label': 'Slot 1 (7:30-9:50)',
      'startTime': '07:30:00',
      'endTime': '09:50:00',
    },
    {
      'label': 'Slot 2 (10:00-12:20)',
      'startTime': '10:00:00',
      'endTime': '12:20:00',
    },
    {
      'label': 'Slot 3 (12:50-15:10)',
      'startTime': '12:50:00',
      'endTime': '15:10:00',
    },
    {
      'label': 'Slot 4 (15:20-17:40)',
      'startTime': '15:20:00',
      'endTime': '17:40:00',
    },
    {
      'label': 'Slot 5 (18:00-20:20)',
      'startTime': '18:00:00',
      'endTime': '20:20:00',
    },
  ];

  final List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _classCodeSuffix = _generateRandomCode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  String _generateRandomCode() {
    const String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    final Random random = Random();

    return List<String>.generate(6, (int index) {
      return characters[random.nextInt(characters.length)];
    }).join();
  }

  String _sanitizeClassToken(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String _buildBackendClassCode() {
    final String base = _sanitizeClassToken(_nameController.text);

    if (base.isEmpty) {
      return 'CLASS-$_classCodeSuffix';
    }

    return '$base-$_classCodeSuffix';
  }

  Map<String, String> _slotConfig(String slotLabel) {
    return _slots.firstWhere((Map<String, String> slot) {
      return slot['label'] == slotLabel;
    }, orElse: () => _slots.first);
  }

  String _buildDescription() {
    final String subject = _subjectController.text.trim();

    final String description = _descController.text.trim();

    if (subject.isEmpty) {
      return description;
    }

    if (description.isEmpty) {
      return 'Môn học: $subject';
    }

    return 'Môn học: $subject\n\n$description';
  }

  void _addSchedule() {
    final bool exists = _schedules.any((Map<String, dynamic> schedule) {
      return schedule['day'] == _selectedDay &&
          schedule['slotLabel'] == _selectedSlot;
    });

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lịch học này đã được thêm!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final Map<String, String> slot = _slotConfig(_selectedSlot);

    setState(() {
      _schedules.add({
        'day': _selectedDay,
        'dayOfWeek': _days.indexOf(_selectedDay),
        'slotLabel': _selectedSlot,
        'startTime': slot['startTime'],
        'endTime': slot['endTime'],
        'roomName': '',
      });
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    if (_schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một ngày và slot học!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> created = await ClassroomService()
          .createClassroom(
            code: _buildBackendClassCode(),
            name: _nameController.text.trim(),
            description: _buildDescription(),
            semesterCode: _selectedSemester,
            schedules: _schedules.map<Map<String, dynamic>>((
              Map<String, dynamic> schedule,
            ) {
              return {
                'dayOfWeek': schedule['dayOfWeek'],
                'slotLabel': schedule['slotLabel'],
                'startTime': schedule['startTime'],
                'endTime': schedule['endTime'],
                'roomName': schedule['roomName'],
              };
            }).toList(),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo lớp học thành công!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _primaryColor,
        ),
      );

      Navigator.of(context).pop(created);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi tạo lớp học: '
            '${error is ApiException ? error.message : error.toString()}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Tạo lớp học',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add_business_outlined,
              color: _primaryDarkColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin lớp học',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Thiết lập thông tin, môn học và lịch '
                  'học cho lớp mới.',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title: title, icon: icon),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _primaryDarkColor, size: 18),
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
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: _errorColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: _textSecondaryColor, size: 20),
      filled: true,
      fillColor: _inputBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _errorColor, width: 1.5),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Tên lớp học', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Nhập tên lớp học, ví dụ: SE1904',
            prefixIcon: Icons.school_outlined,
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tên lớp học là bắt buộc';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mô tả'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          minLines: 3,
          maxLines: 3,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            height: 1.5,
          ),
          decoration: _buildInputDecoration(hintText: 'Mô tả lớp học'),
        ),
      ],
    );
  }

  Widget _buildSubjectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Môn học', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _subjectController,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Nhập tên môn học, ví dụ: Lập trình Mobile',
            prefixIcon: Icons.menu_book_outlined,
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Môn học là bắt buộc';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSemesterField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Kỳ học', required: true),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          icon: Icons.calendar_month_outlined,
          child: DropdownButton<String>(
            value: _selectedSemester,
            isExpanded: true,
            dropdownColor: _surfaceColor,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textSecondaryColor,
            ),
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            items: _semesters.map((String semester) {
              return DropdownMenuItem<String>(
                value: semester,
                child: Text(semester),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _selectedSemester = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Ngày học', required: true),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          icon: Icons.today_outlined,
          child: DropdownButton<String>(
            value: _selectedDay,
            isExpanded: true,
            dropdownColor: _surfaceColor,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textSecondaryColor,
            ),
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            items: _days.map((String day) {
              return DropdownMenuItem<String>(value: day, child: Text(day));
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _selectedDay = value;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('Slot học', required: true),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          icon: Icons.access_time_outlined,
          child: DropdownButton<String>(
            value: _selectedSlot,
            isExpanded: true,
            dropdownColor: _surfaceColor,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textSecondaryColor,
            ),
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            items: _slots.map((Map<String, String> slot) {
              return DropdownMenuItem<String>(
                value: slot['label'],
                child: Text(
                  slot['label']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _selectedSlot = value;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addSchedule,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryDarkColor,
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: _primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text(
              'Thêm lịch học',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContainer({
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 14, right: 12),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: _textSecondaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonHideUnderline(child: child)),
        ],
      ),
    );
  }

  Widget _buildSelectedSchedules() {
    if (_schedules.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Divider(height: 1, color: _borderColor),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Lịch đã chọn',
                style: TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${_schedules.length} lịch',
                style: const TextStyle(
                  color: _primaryDarkColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        ...List<Widget>.generate(_schedules.length, (int index) {
          final Map<String, dynamic> schedule = _schedules[index];

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.fromLTRB(13, 11, 5, 11),
            decoration: BoxDecoration(
              color: _inputBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.schedule_outlined,
                    color: _primaryDarkColor,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '${schedule['day']} - '
                    '${schedule['slotLabel']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textPrimaryColor,
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa lịch',
                  onPressed: () {
                    _removeSchedule(index);
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _errorColor,
                    size: 19,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildClassCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 8, 15),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.key_outlined,
              color: _primaryDarkColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mã lớp học',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildBackendClassCode(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tạo mã mới',
            onPressed: () {
              setState(() {
                _classCodeSuffix = _generateRandomCode();
              });
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: _primaryDarkColor,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: _textSecondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primaryColor.withOpacity(0.65),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : const Text(
                    'Tạo lớp',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 14),
                    _buildFormSection(
                      title: 'Thông tin cơ bản',
                      icon: Icons.info_outline_rounded,
                      children: [
                        _buildNameField(),
                        const SizedBox(height: 18),
                        _buildSubjectField(),
                        const SizedBox(height: 18),
                        _buildDescriptionField(),
                        const SizedBox(height: 18),
                        _buildSemesterField(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildFormSection(
                      title: 'Thiết lập lịch học',
                      icon: Icons.schedule_outlined,
                      children: [
                        _buildScheduleSelectors(),
                        _buildSelectedSchedules(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildFormSection(
                      title: 'Mã lớp',
                      icon: Icons.vpn_key_outlined,
                      children: [_buildClassCodeCard()],
                    ),
                    const SizedBox(height: 22),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
