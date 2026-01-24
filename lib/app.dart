import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/auth/auth_gate.dart';
import 'core/router/go_router_refresh_stream.dart';
import 'features/auth/login_screen.dart';
import 'features/bootstrap/bootstrap_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/logs/daily/daily_log_screen.dart';
import 'features/logs/dynamic/dynamic_log_screen.dart';
import 'features/logs/view/log_view_screen.dart';
import 'features/history/history_screen.dart';
import 'features/notifications/notification_screen.dart';
import 'features/review/review_screen.dart';
import 'features/review/review_detail_screen.dart';

class WhoLogApp extends StatelessWidget {
  const WhoLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0B6E69);
    const scaffoldBg = Color(0xFFF7F8FA);

    final router = GoRouter(
      refreshListenable:
      GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
      redirect: (context, state) {
        final loggedIn = FirebaseAuth.instance.currentUser != null;
        final isLogin = state.matchedLocation == '/login';

        if (!loggedIn) {
          return isLogin ? null : '/login';
        }

        if (isLogin) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthGate(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/bootstrap',
          builder: (context, state) => const BootstrapScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/daily-log',
          builder: (context, state) => const DailyLogScreen(),
        ),
        GoRoute(
          path: '/log',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            return DynamicLogScreen(
              logType: args['logType'] as String,
              eventType: args['eventType'] as String,
            );
          },
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/log-view/:logId',
          builder: (context, state) {
            final logId = state.pathParameters['logId']!;
            return LogViewScreen(logId: logId);
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) => const ReviewScreen(),
        ),
        GoRoute(
          path: '/review/:logId',
          builder: (context, state) => ReviewDetailScreen(
            logId: state.pathParameters['logId']!,
          ),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'WHO Log Sheet',
      theme: ThemeData(
        useMaterial3: true,
        // Global color scheme based on your Teal-Water seed
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          primary: primaryTeal,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: scaffoldBg,

        // Font customization
        textTheme: GoogleFonts.notoSansBengaliTextTheme(
          Theme.of(context).textTheme,
        ),

        // Elegant AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: primaryTeal,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.notoSansBengali(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
          iconTheme: const IconThemeData(color: primaryTeal),
        ),

        // Modern Card Theme for dashboard and log sections
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
        ),

        // Unified Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryTeal, width: 2),
          ),
        ),

        // Unified Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}