import 'package:flutter/material.dart';

class EditMilestoneScreen extends StatefulWidget {
  final Map<String, dynamic> milestone;

  const EditMilestoneScreen({super.key, required this.milestone});

  @override
  State<EditMilestoneScreen> createState() => _EditMilestoneScreenState();
}

class _EditMilestoneScreenState extends State<EditMilestoneScreen> {
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

  late TextEditingController _titleController;
  late TextEditingController _deadlineController;

  final TextEditingController _activityInputController =
      TextEditingController();

  late String _selectedStatus;

  final List<Map<String, dynamic>> _activitiesList = [];

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic> milestone = widget.milestone;

    _titleController = TextEditingController(text: milestone['title'] ?? '');

    _deadlineController = TextEditingController(text: milestone['date'] ?? '');

    _selectedStatus = milestone['status'] ?? 'Chưa bắt đầu';

    if (milestone['activities'] != null) {
      _activitiesList.addAll(
        List<Map<String, dynamic>>.from(
          (milestone['activities'] as List).map(
            (dynamic activity) => Map<String, dynamic>.from(activity),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineController.dispose();
    _activityInputController.dispose();

    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();

    final DateTime today = DateTime(now.year, now.month, now.day);

    DateTime initial = today;

    final String dateText = _deadlineController.text.trim();

    if (dateText.isNotEmpty) {
      final List<String> parts = dateText.split('/');

      if (parts.length == 3) {
        final int? day = int.tryParse(parts[0]);
        final int? month = int.tryParse(parts[1]);
        final int? year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          initial = DateTime(year, month, day);
        }
      }
    }

    final DateTime first = today.subtract(const Duration(days: 365));

    final DateTime last = today.add(const Duration(days: 365));

    if (initial.isBefore(first)) {
      initial = first;
    } else if (initial.isAfter(last)) {
      initial = last;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
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

    if (picked != null) {
      setState(() {
        _deadlineController.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  Future<void> _selectDateLegacy(BuildContext context) async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
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

    if (picked != null) {
      setState(() {
        _deadlineController.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  void _addActivity() {
    final String text = _activityInputController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _activitiesList.add({'title': text, 'status': 'Chưa bắt đầu'});

      _activityInputController.clear();
    });
  }

  void _removeActivity(int index) {
    setState(() {
      _activitiesList.removeAt(index);
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'date': _deadlineController.text,
      'status': _selectedStatus,
      'activities': _activitiesList,
      'comments': widget.milestone['comments'] ?? <Map<String, String>>[],
      'evidences': widget.milestone['evidences'] ?? <Map<String, String>>[],
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
        'Chỉnh sửa mốc thời gian',
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
                  'Thông tin mốc thời gian',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Cập nhật thời hạn, trạng thái và '
                  'các hoạt động trong mốc.',
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
          : Icon(prefixIcon, color: _textSecondaryColor, size: 20),
      suffixIcon: suffixIcon,
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

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Tên mốc', required: true),
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
            hintText: 'Nhập tên mốc thời gian',
            prefixIcon: Icons.flag_outlined,
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tên mốc là bắt buộc';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDeadlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Hạn hoàn thành', required: true),
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
            hintText: 'Chọn ngày hạn hoàn thành',
            prefixIcon: Icons.calendar_today_outlined,
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textSecondaryColor,
            ),
          ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return 'Hạn hoàn thành là bắt buộc';
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
        _buildFieldLabel('Trạng thái'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
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
          items: const [
            DropdownMenuItem<String>(
              value: 'Chưa bắt đầu',
              child: Text('Chưa bắt đầu'),
            ),
            DropdownMenuItem<String>(
              value: 'Đang thực hiện',
              child: Text('Đang thực hiện'),
            ),
            DropdownMenuItem<String>(
              value: 'Hoàn thành',
              child: Text('Hoàn thành'),
            ),
          ],
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

  Widget _buildActivityInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Hoạt động'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _activityInputController,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Nhập hoạt động để thêm',
            prefixIcon: Icons.checklist_rounded,
          ),
          onFieldSubmitted: (String value) {
            _addActivity();
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addActivity,
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
              'Thêm hoạt động',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesList() {
    if (_activitiesList.isEmpty) {
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
                'Hoạt động hiện tại',
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
                '${_activitiesList.length} hoạt động',
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activitiesList.length,
          itemBuilder: (BuildContext context, int index) {
            final Map<String, dynamic> activity = _activitiesList[index];

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
                      Icons.check_circle_outline_rounded,
                      color: _primaryDarkColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      activity['title'] ?? '',
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
                    tooltip: 'Xóa hoạt động',
                    onPressed: () {
                      _removeActivity(index);
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
                        _buildTitleField(),
                        const SizedBox(height: 18),
                        _buildDeadlineField(),
                        const SizedBox(height: 18),
                        _buildStatusField(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildFormSection(
                      title: 'Danh sách hoạt động',
                      icon: Icons.checklist_rounded,
                      children: [_buildActivityInput(), _buildActivitiesList()],
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
