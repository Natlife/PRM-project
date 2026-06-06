import 'package:flutter/material.dart';
import 'screens/common/splash_screen.dart';
import 'screens/common/login_screen.dart';
import 'screens/common/profile_screen.dart';
import 'screens/common/notification_screen.dart';
import 'screens/teacher/teacher_home_screen.dart';
import 'screens/student/student_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flipped Classroom',
      debugShowCheckedModeBanner: false,
      
      // Premium Sleek Dark Theme configuration
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5A57FF),       // Electric Violet
          secondary: Color(0xFFD946EF),     // Magenta
          surface: Color(0xFF1E293B),       // Slate 800
          background: Color(0xFF0F172A),    // Slate 900
          error: Colors.redAccent,
        ),
        
        // Font customization
        fontFamily: 'Roboto', // Default fallback, customizable
        
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF5A57FF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A57FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
        ),
        
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF5A57FF);
            }
            return Colors.transparent;
          }),
          side: const BorderSide(color: Colors.white30, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      
      // Initial Route starts at Splash
      initialRoute: '/',
      
      // Page route mappings
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/teacher_home': (context) => const TeacherHomeScreen(),
        '/student_home': (context) => const StudentHomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }
}
