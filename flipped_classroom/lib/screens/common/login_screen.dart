import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rememberMe = AuthService().rememberMe;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final AuthService authService = AuthService();

    await authService.setRememberMe(_rememberMe);

    final bool success = await authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      final UserRole? role = authService.currentUser?.role;

      if (role == UserRole.teacher) {
        Navigator.of(context).pushReplacementNamed('/teacher_home');
      } else {
        Navigator.of(context).pushReplacementNamed('/student_home');
      }

      return;
    }

    setState(() {
      _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác!';
    });
  }

  void _fillMockCredentials(String username, String password) {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _errorMessage = null;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã tự động điền tài khoản: $username'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _primaryDarkColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _showForgotPasswordMessage() {
    FocusManager.instance.primaryFocus?.unfocus();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Vui lòng sử dụng tài khoản kiểm thử hoặc liên hệ Giáo vụ để được hỗ trợ.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _clearErrorMessage() {
    if (_errorMessage == null) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 21,
        color: _textSecondaryColor,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FBFA),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _errorColor,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _errorColor,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      errorStyle: const TextStyle(
        color: _errorColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            size: 35,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Chào mừng trở lại',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textPrimaryColor,
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Đăng nhập để tiếp tục hành trình học tập\nvà giảng dạy của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textSecondaryColor,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _errorMessage == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey<String>(_errorMessage!),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFD4D6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: _errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: _errorColor,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tên đăng nhập hoặc email',
          style: TextStyle(
            color: _textPrimaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: _usernameController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [
            AutofillHints.username,
            AutofillHints.email,
          ],
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            hintText: 'Nhập tài khoản của bạn',
            prefixIcon: Icons.person_outline_rounded,
          ),
          onChanged: (_) => _clearErrorMessage(),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tài khoản';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Mật khẩu',
                style: TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _showForgotPasswordMessage,
              style: TextButton.styleFrom(
                foregroundColor: _primaryDarkColor,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            hintText: 'Nhập mật khẩu',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Hiển thị mật khẩu'
                  : 'Ẩn mật khẩu',
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 21,
                color: _textSecondaryColor,
              ),
            ),
          ),
          onChanged: (_) => _clearErrorMessage(),
          onFieldSubmitted: (_) {
            if (!_isLoading) {
              _handleLogin();
            }
          },
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRememberMe() {
    return InkWell(
      onTap: _isLoading
          ? null
          : () {
              setState(() {
                _rememberMe = !_rememberMe;
              });
            },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _rememberMe,
                onChanged: _isLoading
                    ? null
                    : (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                activeColor: _primaryColor,
                checkColor: Colors.white,
                side: const BorderSide(
                  color: Color(0xFFABB5AF),
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Ghi nhớ đăng nhập',
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          disabledBackgroundColor: _primaryColor.withOpacity(0.65),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey<String>('loading'),
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : const Row(
                  key: ValueKey<String>('login'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 9),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17211B).withOpacity(0.055),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildErrorMessage(),
              _buildUsernameField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 14),
              _buildRememberMe(),
              const SizedBox(height: 26),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLoginButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimaryColor,
          backgroundColor: _surfaceColor,
          disabledForegroundColor: _textSecondaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          side: const BorderSide(
            color: _borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: _primaryDarkColor,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogin() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(
              child: Divider(
                color: _borderColor,
                height: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Tài khoản kiểm thử',
                style: TextStyle(
                  color: _textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: _borderColor,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _buildQuickLoginButton(
              title: 'Giảng viên',
              icon: Icons.school_outlined,
              onPressed: () {
                _fillMockCredentials(
                  'teacher',
                  'teacher123',
                );
              },
            ),
            const SizedBox(width: 12),
            _buildQuickLoginButton(
              title: 'Sinh viên',
              icon: Icons.person_outline_rounded,
              onPressed: () {
                _fillMockCredentials(
                  'student',
                  'student123',
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Text(
      'Flipped Classroom',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 14),
                      _buildHeader(),
                      const SizedBox(height: 34),
                      _buildLoginForm(),
                      const SizedBox(height: 30),
                      _buildQuickLogin(),
                      const SizedBox(height: 30),
                      _buildFooter(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}