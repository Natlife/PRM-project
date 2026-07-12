import 'package:flutter/material.dart';

class EditActivityScreen extends StatefulWidget {
  final String activityTitle;
  final String description;
  final String deadline;
  final String currentStatus;

  const EditActivityScreen({
    super.key,
    required this.activityTitle,
    required this.description,
    required this.deadline,
    required this.currentStatus,
  });

  @override
  State<EditActivityScreen> createState() =>
      _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
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

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _deadlineController;

  late String _selectedStatus;

  final List<Map<String, String>> _statusOptions = const [
    {
      'value': 'DRAFT',
      'label': 'Draft',
    },
    {
      'value': 'PUBLISHED',
      'label': 'Published',
    },
    {
      'value': 'CLOSED',
      'label': 'Closed',
    },
  ];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.activityTitle,
    );

    _descController = TextEditingController(
      text: widget.description,
    );

    _deadlineController = TextEditingController(
      text: widget.deadline,
    );

    _selectedStatus = widget.currentStatus.isNotEmpty
        ? widget.currentStatus
        : 'DRAFT';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _deadlineController.dispose();

    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();

    final DateTime tomorrow = now.add(
      const Duration(days: 1),
    );

    DateTime initial = tomorrow;

    try {
      final String sourceDeadline =
          _deadlineController.text;

      if (sourceDeadline.contains('/')) {
        final List<String> parts =
            sourceDeadline.split('/');

        final int day = int.parse(parts[0]);
        final int month = int.parse(parts[1]);
        final int year = int.parse(parts[2]);

        final DateTime parsed = DateTime(
          year,
          month,
          day,
        );

        if (parsed.isAfter(now)) {
          initial = parsed;
        }
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: now.add(
        const Duration(days: 365),
      ),
      builder: (
        BuildContext context,
        Widget? child,
      ) {
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

    if (picked != null) {
      setState(() {
        _deadlineController.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final Map<String, dynamic> updatedActivity = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'deadline': _deadlineController.text,
      'status': _selectedStatus,
    };

    Navigator.of(context).pop(updatedActivity);
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
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: _textPrimaryColor,
        ),
      ),
      titleSpacing: 0,
      title: const Text(
        'Chỉnh sửa hoạt động',
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
        border: Border.all(
          color: _borderColor,
        ),
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
              Icons.edit_note_rounded,
              color: _primaryDarkColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin hoạt động',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Cập nhật nội dung, hạn nộp và trạng thái '
                  'của hoạt động.',
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

  Widget _buildFormSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(),
          const SizedBox(height: 20),
          _buildTitleField(),
          const SizedBox(height: 18),
          _buildDescriptionField(),
          const SizedBox(height: 18),
          _buildDeadlineField(),
          const SizedBox(height: 18),
          _buildStatusField(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: _primaryDarkColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Text(
            'Chi tiết hoạt động',
            style: TextStyle(
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

  Widget _buildFieldLabel(
    String label, {
    bool required = false,
  }) {
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
    Widget? suffixIcon,
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
          : Icon(
              prefixIcon,
              color: _textSecondaryColor,
              size: 20,
            ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _inputBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _errorColor,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _errorColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Tiêu đề',
          required: true,
        ),
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
            hintText: 'Nhập tiêu đề hoạt động',
            prefixIcon: Icons.title_rounded,
          ),
          validator: (String? value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'Tiêu đề hoạt động là bắt buộc';
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
        _buildFieldLabel('Mô tả yêu cầu'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          minLines: 4,
          maxLines: 4,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            height: 1.5,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Nhập mô tả yêu cầu...',
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Hạn nộp',
          required: true,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _deadlineController,
          readOnly: true,
          onTap: () {
            _selectDate(context);
          },
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Chọn ngày hạn nộp',
            prefixIcon: Icons.calendar_today_outlined,
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textSecondaryColor,
            ),
          ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return 'Hạn nộp là bắt buộc';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Trạng thái',
          required: true,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedStatus,
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
            hintText: 'Chọn trạng thái',
            prefixIcon: Icons.track_changes_outlined,
          ),
          items: _statusOptions.map(
            (Map<String, String> status) {
              return DropdownMenuItem<String>(
                value: status['value'],
                child: Text(
                  status['label']!,
                ),
              );
            },
          ).toList(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                _selectedStatus = value;
              });
            }
          },
        ),
      ],
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
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              side: const BorderSide(
                color: _borderColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Lưu thay đổi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
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
          padding: const EdgeInsets.fromLTRB(
            18,
            20,
            18,
            36,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 680,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 14),
                    _buildFormSection(),
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