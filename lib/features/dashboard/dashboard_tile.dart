import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../stores/session_store.dart';
import '../../core/constants.dart';
import '../../services/template_service.dart';

// --- 1. DASHBOARD TILE (Your Optimized Design) ---
class DashTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Map<String, dynamic>? extra;
  final Gradient gradient;

  const DashTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.gradient,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.12)),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(route, extra: extra);
                },
                splashColor: Colors.white.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 22, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. MAIN DASHBOARD SCREEN (Sliver + Dynamic Logic) ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color tealWater = Color(0xFF0B6E69);
  static const Color bgColor = Color(0xFFF7F8FA);

  // Helper class for building buttons
  late Future<List<_DashBtnData>> _dynamicButtons;

  @override
  void initState() {
    super.initState();
    final user = SessionStore.instance.currentUser;
    if (user != null) {
      _dynamicButtons = _fetchAvailableTemplates(user);
    }
  }

  // Logic to check Firestore for which buttons to show
  Future<List<_DashBtnData>> _fetchAvailableTemplates(AppUser user) async {
    final List<_DashBtnData> buttons = [];
    const eventType = "general"; // Matches your DB eventType

    Future<void> check(String title, String sub, IconData icon, String type, List<Color> colors) async {
      print("Checking: Role: ${user.roleId}, Dist: ${user.districtId}, Type: $type");

      final template = await TemplateService().fetchActiveTemplate(
        roleId: user.roleId,
        districtId: user.districtId?.toLowerCase() ?? '',
        logType: type,
        eventType: eventType,
      );

      if (template != null) {
        print("✅ Found $type for ${user.roleId}");
        buttons.add(_DashBtnData(
          title: title, sub: sub, icon: icon, type: type,
          gradient: LinearGradient(colors: colors),
        ));
      } else {
        print("❌ NOT FOUND: $type. Check if isActive is true in DB.");
      }
    }

    // Checking all possibilities in parallel for speed
    await Future.wait([
      check('দৈনিক লগ', 'Daily Report', Icons.assignment_rounded, LogTypes.daily, [tealWater, const Color(0xFF07524E)]),
      check('মাসিক লগ', 'Monthly Report', Icons.calendar_month, LogTypes.monthly, [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]),
      check('বন্যা রিপোর্ট', 'Flood Data', Icons.tsunami_rounded, LogTypes.flood, [const Color(0xFFE67E22), const Color(0xFFD35400)]),
      check('নতুন সংযোগ', 'New Connection', Icons.add_link, LogTypes.newConnection, [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)]),
    ]);

    // History is always added
    buttons.add(_DashBtnData(
      title: 'ইতিহাস', sub: 'Log History', icon: Icons.manage_search_rounded, type: 'history',
      gradient: const LinearGradient(colors: [Color(0xFF14A098), Color(0xFF0B6E69)]),
    ));

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('User not found')));

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // 1. Premium Sliver Header
          _buildHeader(user),

          // 2. Dynamic Grid
          FutureBuilder<List<_DashBtnData>>(
            future: _dynamicButtons,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: tealWater)),
                );
              }
              final buttons = snapshot.data ?? [];

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final b = buttons[index];
                      return DashTile(
                        title: b.title,
                        subtitle: b.sub,
                        icon: b.icon,
                        route: b.type == 'history' ? '/history' : '/log',
                        gradient: b.gradient,
                        extra: b.type == 'history' ? null : {'logType': b.type, 'eventType': 'general'},
                      );
                    },
                    childCount: buttons.length,
                  ),
                ),
              );
            },
          ),

          // 3. Stats Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('সাম্প্রতিক অবস্থা', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealWater)),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20),
                children: [
                  _miniStatCard('জমা হয়েছে', '১২', Colors.blue),
                  _miniStatCard('অনুমোদিত', '১০', Colors.green),
                  _miniStatCard('পেন্ডিং', '০২', Colors.orange),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppUser user) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: tealWater,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned(top: -50, right: -50, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35, backgroundColor: Colors.white24,
                    child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('স্বাগতম, ${user.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('জেলা: ${user.districtId}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_active_outlined, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(String label, String value, Color color) {
    return Container(
      width: 130, margin: const EdgeInsets.only(right: 12, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// Simple model for building the dynamic list
class _DashBtnData {
  final String title, sub, type;
  final IconData icon;
  final Gradient gradient;
  _DashBtnData({required this.title, required this.sub, required this.icon, required this.type, required this.gradient});
}