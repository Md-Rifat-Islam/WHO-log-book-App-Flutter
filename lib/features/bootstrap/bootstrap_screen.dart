import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../stores/session_store.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  final _userService = UserService();
  final Color tealWater = const Color(0xFF0B6E69);

  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _error = null);
    try {
      final AppUser profile = await _userService.fetchCurrentUserProfile();
      SessionStore.instance.currentUser = profile;

      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background for a premium feel
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tealWater, tealWater.withOpacity(0.8)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Icon placeholder
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            if (_error == null) ...[
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'অ্যাপটি লোড হচ্ছে...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ] else
              _buildErrorContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'প্রোফাইল পাওয়া যায়নি',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'আপনার প্রোফাইলটি এখনো তৈরি করা হয়নি অথবা ডাটাবেসে সমস্যা রয়েছে। অনুগ্রহ করে অ্যাডমিনের সাথে যোগাযোগ করুন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const Divider(height: 30),
                Text(
                  'Error Details:\n$_error',
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: tealWater,
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _bootstrap,
            icon: const Icon(Icons.refresh),
            label: const Text('আবার চেষ্টা করুন'),
          ),
        ],
      ),
    );
  }
}