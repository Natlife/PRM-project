import 'package:flutter/material.dart';

class EditClassScreen extends StatefulWidget {
  final String className;
  final String classCode;
  final String semester;
  final String description;
  final List<Map<String, dynamic>> schedules;

  const EditClassScreen({
    super.key,
    required this.className,
    required this.classCode,
    required this.semester,
    required this.description,
    required this.schedules,
  });

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
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

  final List<String> _semesters = const ['SU26', 'FA26', 'SP26', 'HK1 2026'];

  final List<String> _dayLabels = const [
    'Thu 2',
    'Thu 3',
    'Thu 4',
    'Thu 5',
    'Thu 6',
    'Thu 7',
    'Chu nhat',
  ];

  final List<Map<String, String>> _slots = const [
    {
      'slotLabel': 'Slot 1',
      'display': 'Slot 1 (7:30-9:50)',
      'startTime': '07:30:00',
      'endTime': '09:50:00',
    },
    {
      'slotLabel': 'Slot 2',
      'display': 'Slot 2 (10:00-12:20)',
      'startTime': '10:00:00',
      'endTime': '12:20:00',
    },
    {
      'slotLabel': 'Slot 3',
      'display': 'Slot 3 (12:50-15:10)',
      'startTime': '12:50:00',
      'endTime': '15:10:00',
    },
    {
      'slotLabel': 'Slot 4',
      'display': 'Slot 4 (15:20-17:40)',
      'startTime': '15:20:00',
      'endTime': '17:40:00',
    },
    {
      'slotLabel': 'Slot 5',
      'display': 'Slot 5 (18:00-20:20)',
      'startTime': '18:00:00',
      'endTime': '20:20:00',
    },
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  late String _selectedSemester;
  late String _selectedDay;
  late String _selectedSlot;

  late List<Map<String, dynamic>> _schedulesList;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.className);

    _descController = TextEditingController(text: widget.description);

    _selectedSemester = _semesters.contains(widget.semester)
        ? widget.semester
        : _semesters.first;

    _selectedDay = _dayLabels.first;
    _selectedSlot = _slots.first['display']!;

    _schedulesList = widget.schedules.map(_normalizeSchedule).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();

    super.dispose();
  }

  Map<String, dynamic> _normalizeSchedule(Map<String, dynamic> raw) {
    final int dayOfWeek = raw['dayOfWeek'] as int? ?? 0;

    final String slotLabel = raw['slotLabel']?.toString() ?? 'Slot 1';

    final String startTime = raw['startTime']?.toString() ?? '07:30:00';

    final String endTime = raw['endTime']?.toString() ?? '09:50:00';

    final String display = _slots.firstWhere((Map<String, String> slot) {
      return slot['slotLabel'] == slotLabel;
    }, orElse: () => _slots.first)['display']!;

    return {
      'dayOfWeek': dayOfWeek,
      'slotLabel': slotLabel,
      'startTime': startTime,
      'endTime': endTime,
      'displayDay': dayOfWeek >= 0 && dayOfWeek < _dayLabels.length
          ? _dayLabels[dayOfWeek]
          : _dayLabels.first,
      'displaySlot': display,
    };
  }

  Map<String, dynamic> _buildScheduleRequest(
    String dayLabel,
    String slotDisplay,
  ) {
    final int dayOfWeek = _dayLabels.indexOf(dayLabel);

    final Map<String, String> slot = _slots.firstWhere((
      Map<String, String> item,
    ) {
      return item['display'] == slotDisplay;
    }, orElse: () => _slots.first);

    return {
      'dayOfWeek': dayOfWeek < 0 ? 0 : dayOfWeek,
      'slotLabel': slot['slotLabel'],
      'startTime': slot['startTime'],
      'endTime': slot['endTime'],
      'displayDay': dayLabel,
      'displaySlot': slotDisplay,
    };
  }

  void _addSchedule() {
    final Map<String, dynamic> newSchedule = _buildScheduleRequest(
      _selectedDay,
      _selectedSlot,
    );

    final bool exists = _schedulesList.any((Map<String, dynamic> schedule) {
      return schedule['dayOfWeek'] == newSchedule['dayOfWeek'] &&
          schedule['slotLabel'] == newSchedule['slotLabel'];
    });

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lich hoc nay da ton tai.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _schedulesList.add(newSchedule);
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedulesList.removeAt(index);
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_schedulesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui long them it nhat mot lich hoc.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'semesterCode': _selectedSemester,
      'schedules': _schedulesList.map((Map<String, dynamic> schedule) {
        return {
          'dayOfWeek': schedule['dayOfWeek'],
          'slotLabel': schedule['slotLabel'],
          'startTime': schedule['startTime'],
          'endTime': schedule['endTime'],
        };
      }).toList(),
    });
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
        'Chỉnh sửa lớp học',
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
              Icons.edit_calendar_outlined,
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
                  'Cập nhật thông tin cơ bản và lịch học '
                  'của lớp.',
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
            hintText: 'Nhập tên lớp học',
            prefixIcon: Icons.school_outlined,
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ten lop hoc la bat buoc';
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

  Widget _buildSemesterField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Học kỳ', required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSemester,
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
          decoration: _buildInputDecoration(
            hintText: 'Chọn học kỳ',
            prefixIcon: Icons.calendar_month_outlined,
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
      ],
    );
  }

  Widget _buildDayField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Ngày học', required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedDay,
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
          decoration: _buildInputDecoration(
            hintText: 'Chọn ngày học',
            prefixIcon: Icons.today_outlined,
          ),
          items: _dayLabels.map((String day) {
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
      ],
    );
  }

  Widget _buildSlotField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Slot học', required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSlot,
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
          decoration: _buildInputDecoration(
            hintText: 'Chọn slot học',
            prefixIcon: Icons.access_time_outlined,
          ),
          items: _slots.map((Map<String, String> slot) {
            return DropdownMenuItem<String>(
              value: slot['display'],
              child: Text(
                slot['display']!,
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
      ],
    );
  }

  Widget _buildAddScheduleButton() {
    return SizedBox(
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
    );
  }

  Widget _buildSchedulesList() {
    if (_schedulesList.isEmpty) {
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
                '${_schedulesList.length} lịch',
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
        ...List<Widget>.generate(_schedulesList.length, (int index) {
          final Map<String, dynamic> schedule = _schedulesList[index];

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.fromLTRB(13, 10, 5, 10),
            decoration: BoxDecoration(
              color: _inputBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.schedule_outlined,
                    color: _primaryDarkColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '${schedule['displayDay']} - '
                    '${schedule['displaySlot']}',
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
      padding: const EdgeInsets.all(15),
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
                  widget.classCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
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
            onPressed: () {
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
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Lưu thay đổi',
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
                        _buildDayField(),
                        const SizedBox(height: 18),
                        _buildSlotField(),
                        const SizedBox(height: 14),
                        _buildAddScheduleButton(),
                        _buildSchedulesList(),
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
