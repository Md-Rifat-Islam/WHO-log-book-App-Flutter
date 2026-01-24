import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../stores/session_store.dart';
import '../../core/constants.dart';
import '../../services/template_service.dart';
import 'dashboard_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color tealWater = AppAssets.tealWater;
  static const Color bgColor = Color(0xFFF7F8FA);

  late Future<List<_DashBtn>> _buttonsFuture;

  @override
  void initState() {
    super.initState();
    final user = SessionStore.instance.currentUser;
    if (user != null) {
      _buttonsFuture = _buildButtons(user);
    }
  }

  // --- 1. CLEANED VIBRANT GRADIENTS ---
  Gradient _getLogTypeGradient(String logType, String eventType) {
    if (eventType == EventTypes.flooded) {
      return const LinearGradient(colors: [Color(0xFF009688), Color(0xFF4DB6AC)]);
    }
    if (eventType == EventTypes.new_connection) {
      return const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE040FB)]);
    }

    switch (logType) {
      case LogTypes.daily:
        return const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF00BCD4)]);
      case LogTypes.weekly:
        return const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFC107)]);
      case LogTypes.monthly:
        return const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)]);
      case LogTypes.quarterly:
        return const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5252)]);
      case LogTypes.halfYearly:
        return const LinearGradient(colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)]);
      default:
        return LinearGradient(colors: [Colors.blueGrey.shade600, Colors.blueGrey.shade800]);
    }
  }

  // --- 2. LOGOUT DIALOG ---
  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('লগ আউট?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('আপনি কি নিশ্চিত যে আপনি লগ আউট করতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('হ্যাঁ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // --- 3. TEMPLATE LOGIC ---
  Future<bool> _templateExists({required AppUser user, required String logType, required String eventType}) async {
    try {
      final template = await TemplateService().fetchActiveTemplate(
        roleId: user.roleId,
        districtId: user.districtId?.toLowerCase() ?? '',
        logType: logType,
        eventType: eventType,
      );
      return template != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<_DashBtn>> _buildButtons(AppUser user) async {
    final buttons = <_DashBtn>[];

    Future<void> addLogBtn({
      required String title,
      required String subtitle,
      required IconData icon,
      required String logType,
      String eventType = EventTypes.general
    }) async {
      final exists = await _templateExists(user: user, logType: logType, eventType: eventType);
      if (exists) {
        buttons.add(_DashBtn(
          title: title, subtitle: subtitle, icon: icon, route: '/log',
          gradient: _getLogTypeGradient(logType, eventType),
          extra: {'logType': logType, 'eventType': eventType},
        ));
      }
    }

    // Parallel check for performance
    await Future.wait([
      addLogBtn(title: 'Daily', subtitle: 'দৈনিক লগ', icon: Icons.today, logType: LogTypes.daily),
      addLogBtn(title: 'Weekly', subtitle: 'সাপ্তাহিক লগ', icon: Icons.view_week, logType: LogTypes.weekly),
      addLogBtn(title: 'Monthly', subtitle: 'মাসিক লগ', icon: Icons.calendar_month, logType: LogTypes.monthly),
      addLogBtn(title: 'Quarterly', subtitle: 'ত্রৈমাসিক লগ', icon: Icons.date_range, logType: LogTypes.quarterly),
      addLogBtn(title: 'Half-Yearly', subtitle: 'ষাণ্মাসিক লগ', icon: Icons.event_note, logType: LogTypes.halfYearly),

      // Fixed: Using constants from your updated file
      addLogBtn(title: 'New Connection', subtitle: 'নতুন সংযোগ', icon: Icons.add_link, logType: LogTypes.daily, eventType: EventTypes.new_connection),
      addLogBtn(title: 'Flood/Emergency', subtitle: 'বন্যা/জরুরী', icon: Icons.flood, logType: LogTypes.daily, eventType: EventTypes.flooded),
    ]);

    // History is always available
    buttons.add(_DashBtn(
      title: 'History', subtitle: 'জমা দেওয়া লগ', icon: Icons.history, route: '/history',
      gradient: LinearGradient(colors: [Colors.blueGrey.shade600, Colors.blueGrey.shade900]),
    ));

    // Admin/Supervisor specific buttons using RoleIds constant
    bool isAdmin = user.roleId == RoleIds.admin;
    bool isSupervisor = user.roleId == RoleIds.supervisor;

    if (isAdmin || (isSupervisor && user.permissions['canApprove'] == true)) {
      buttons.add(_DashBtn(
        title: 'Review', subtitle: 'লগ যাচাইকরণ', icon: Icons.verified_user_outlined, route: '/review',
        gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF000000)]),
      ));
    }
    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('User session not found')));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        toolbarHeight: 95,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: FutureBuilder(
            future: _buttonsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator(
                  backgroundColor: AppAssets.bdGreen,
                  valueColor: AlwaysStoppedAnimation<Color>(AppAssets.bdRed),
                  minHeight: 3,
                );
              }
              return const SizedBox(height: 3);
            },
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: tealWater.withOpacity(0.1),
              child: ClipOval(
                child: Image.asset(AppAssets.logo, fit: BoxFit.cover, width: 38, height: 38,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.water_drop_rounded, color: tealWater, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('WHO Logbook', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('${user.name} (${user.districtId})',
                      style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6)),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10)),
              backgroundColor: AppAssets.bdRed,
              child: const Icon(Icons.notifications_none_rounded, color: tealWater, size: 28),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: AppAssets.bdRed, size: 28),
            onPressed: () async {
              final confirm = await _showLogoutDialog(context);
              if (confirm == true) {
                SessionStore.instance.currentUser = null;
                await AuthService().signOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<_DashBtn>>(
        future: _buttonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildBrandedLoader();
          }
          final buttons = snapshot.data ?? [];
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: buttons.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.0,
            ),
            itemBuilder: (context, i) {
              final b = buttons[i];
              return DashTile(
                title: b.title, subtitle: b.subtitle, icon: b.icon,
                route: b.route, extra: b.extra, gradient: b.gradient,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBrandedLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: tealWater),
          const SizedBox(height: 16),
          const Text('তথ্য লোড হচ্ছে...', style: TextStyle(color: tealWater, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DashBtn {
  final String title, subtitle, route;
  final IconData icon;
  final Gradient gradient;
  final Map<String, dynamic>? extra;
  _DashBtn({required this.title, required this.subtitle, required this.icon, required this.route, required this.gradient, this.extra});
}