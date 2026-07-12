import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  final List<Map<String, dynamic>> classrooms;

  const CreateEventScreen({super.key, required this.classrooms});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
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

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _sessionDurationController =
      TextEditingController(text: '20');

  int? _selectedClassroomId;
  DateTime? _selectedStartAt;
  DateTime? _selectedEndAt;

  @override
  void initState() {
    super.initState();

    if (widget.classrooms.isNotEmpty) {
      _selectedClassroomId = (widget.classrooms.first['id'] as num?)?.toInt();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sessionDurationController.dispose();

    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime now = DateTime.now();

    final DateTime initial = isStart
        ? (_selectedStartAt ?? now.add(const Duration(days: 1)))
        : (_selectedEndAt ??
              (_selectedStartAt ?? now).add(const Duration(hours: 2)));

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: _surfaceColor,
              onSurface: _textPrimaryColor,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (date == null || !mounted) {
      return;
    }

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: _surfaceColor,
              onSurface: _textPrimaryColor,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (time == null || !mounted) {
      return;
    }

    final DateTime picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _selectedStartAt = picked;

        if (_selectedEndAt == null || !_selectedEndAt!.isAfter(picked)) {
          _selectedEndAt = picked.add(const Duration(hours: 2));
        }
      } else {
        _selectedEndAt = picked;
      }
    });
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Chọn thời gian';
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassroomId == null ||
        _selectedStartAt == null ||
        _selectedEndAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn lớp học và thời gian đầy đủ'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );

      return;
    }

    if (!_selectedEndAt!.isAfter(_selectedStartAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian kết thúc phải sau thời gian bắt đầu'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );

      return;
    }

    Navigator.pop<Map<String, dynamic>>(context, {
      'classroomId': _selectedClassroomId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'startAt': _selectedStartAt!.toIso8601String(),
      'endAt': _selectedEndAt!.toIso8601String(),
      'sessionDurationMinutes':
          int.tryParse(_sessionDurationController.text.trim()) ?? 20,
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
        'Tạo sự kiện mới',
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
              Icons.event_available_outlined,
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
                  'Thông tin sự kiện',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Thiết lập lớp học, nội dung và thời gian '
                  'diễn ra sự kiện.',
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

  Widget _buildClassroomField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Lớp học', required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedClassroomId,
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
            hintText: 'Chọn lớp học',
            prefixIcon: Icons.school_outlined,
          ),
          items: widget.classrooms.map((Map<String, dynamic> classroom) {
            return DropdownMenuItem<int>(
              value: (classroom['id'] as num?)?.toInt(),
              child: Text(
                classroom['code']?.toString() ??
                    classroom['className']?.toString() ??
                    '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (int? value) {
            setState(() {
              _selectedClassroomId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Tên sự kiện', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Nhập tên sự kiện',
            prefixIcon: Icons.title_rounded,
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tên sự kiện là bắt buộc';
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
          controller: _descriptionController,
          minLines: 4,
          maxLines: 4,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            height: 1.5,
          ),
          decoration: _buildInputDecoration(hintText: 'Nhập mô tả sự kiện'),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, required: true),
        const SizedBox(height: 8),
        Material(
          color: _inputBackgroundColor,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: _primaryDarkColor, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatDateTime(value),
                      style: TextStyle(
                        color: value == null
                            ? const Color(0xFF9AA49E)
                            : _textPrimaryColor,
                        fontSize: 13.5,
                        fontWeight: value == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: _textSecondaryColor,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Thời lượng mỗi phiên', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _sessionDurationController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration:
              _buildInputDecoration(
                hintText: 'Nhập thời lượng',
                prefixIcon: Icons.timer_outlined,
              ).copyWith(
                suffixText: 'phút',
                suffixStyle: const TextStyle(
                  color: _textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          validator: (String? value) {
            final int? minutes = int.tryParse(value?.trim() ?? '');

            if (minutes == null || minutes <= 0) {
              return 'Nhập thời lượng hợp lệ';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Tạo sự kiện',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
                        _buildClassroomField(),
                        const SizedBox(height: 18),
                        _buildTitleField(),
                        const SizedBox(height: 18),
                        _buildDescriptionField(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildFormSection(
                      title: 'Thời gian sự kiện',
                      icon: Icons.schedule_outlined,
                      children: [
                        _buildDateTimeField(
                          label: 'Bắt đầu',
                          value: _selectedStartAt,
                          icon: Icons.calendar_today_outlined,
                          onTap: () {
                            _pickDateTime(isStart: true);
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildDateTimeField(
                          label: 'Kết thúc',
                          value: _selectedEndAt,
                          icon: Icons.event_outlined,
                          onTap: () {
                            _pickDateTime(isStart: false);
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildDurationField(),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _buildSubmitButton(),
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
