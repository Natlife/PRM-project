import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _initializeAnimation();
    _startNavigationTimer();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0,
          0.7,
          curve: Curves.easeOut,
        ),
      ),
    );

    _animationController.forward();
  }

  void _startNavigationTimer() {
    _navigationTimer = Timer(
      const Duration(milliseconds: 2500),
      _checkAuthAndNavigate,
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) {
      return;
    }

    final AuthService authService = AuthService();

    await authService.restoreSession();

    if (!mounted) {
      return;
    }

    if (!authService.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    final UserRole? role = authService.currentUser?.role;

    if (role == UserRole.teacher) {
      Navigator.of(context).pushReplacementNamed('/teacher_home');
    } else {
      Navigator.of(context).pushReplacementNamed('/student_home');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildDecorativeBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -110,
              right: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -100,
              child: Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              top: 170,
              left: -45,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withOpacity(0.04),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_stories_rounded,
        size: 44,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(),
            const SizedBox(height: 26),
            const Text(
              'Flipped Classroom',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimaryColor,
                fontSize: 28,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Học tập chủ động · Kiến tạo tương lai',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              _primaryColor,
            ),
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Đang khởi tạo ứng dụng',
          style: TextStyle(
            color: _textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionLabel() {
    return const Text(
      'Learning made smarter',
      style: TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            _buildDecorativeBackground(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildMainContent(),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 54,
              child: _buildLoadingIndicator(),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: Center(
                child: _buildVersionLabel(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}