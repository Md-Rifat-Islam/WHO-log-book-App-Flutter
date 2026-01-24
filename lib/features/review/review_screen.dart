import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/firebase_refs.dart';
import '../../stores/session_store.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String? _status = 'Pending'; // Default to Pending for Reviewers
  String? _logType;

  static const Color tealWater = Color(0xFF0B6E69);
  static const Color bgColor = Color(0xFFF7F8FA);

  Query<Map<String, dynamic>> _buildQuery() {
    final user = SessionStore.instance.currentUser!;
    final isAdmin = user.roleId.toLowerCase() == 'admin';
    final assigned = user.assignedDistrictIds ?? [];

    Query<Map<String, dynamic>> q = logsRef;

    if (!isAdmin) {
      // If supervisor has no districts assigned, they shouldn't see anything
      if (assigned.isEmpty) {
        return logsRef.limit(0);
      }
      q = q.where('districtId', whereIn: assigned);
    }

    if (_status != null) q = q.where('status', isEqualTo: _status);
    if (_logType != null) q = q.where('logType', isEqualTo: _logType);

    return q.orderBy('createdAt', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('No profile found.')));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        foregroundColor: Colors.black87,
        elevation: 0.5,
        toolbarHeight: 95,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.water_drop_rounded,
                    color: tealWater,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Review Center',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5),
                  ),
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.7)),
                  ),
                  Text(
                    '(${user.districtId})',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return _errorWidget(snap.error.toString());
                if (snap.connectionState == ConnectionState.waiting) return _loadingWidget();

                final docs = snap.data!.docs;
                if (docs.isEmpty) return _emptyWidget();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) => _buildLogCard(docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _filterChip(
              label: 'Status',
              value: _status,
              items: ['Pending', 'Approved', 'Rejected'],
              onSelected: (v) => setState(() => _status = v),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _filterChip(
              label: 'Log Type',
              value: _logType,
              items: ['daily', 'weekly', 'monthly', 'quarterly'],
              onSelected: (v) => setState(() => _logType = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required String? value, required List<String> items, required Function(String?) onSelected}) {
    return PopupMenuButton<String?>(
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text('All $label')),
        ...items.map((e) => PopupMenuItem(value: e, child: Text(e)))
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
                color: value != null ? tealWater : Colors.black54,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final status = (m['status'] ?? 'Pending').toString();
    final type = (m['logType'] ?? 'N/A').toString();

    return Container(
      key: ValueKey(d.id), // Added key for stable rendering
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias, // Ensures hover/splash stays inside
        child: InkWell(
          onTap: () {
            // Use push instead of go to maintain the tracker state
            context.push('/review/${d.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 50, width: 50,
                  decoration: BoxDecoration(
                      color: tealWater.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: const Icon(Icons.assignment_rounded, color: tealWater, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${type.toUpperCase()} - ${m['districtId']}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text('Period: ${m['periodKey']}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                _statusBadge(status),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String s) {
    Color color;
    switch (s.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(s.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _loadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/app_logo.png', width: 60, height: 60),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: tealWater, strokeWidth: 3),
        ],
      ),
    );
  }

  Widget _emptyWidget() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No logs found.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Widget _errorWidget(String e) => Center(child: Text('Error: $e'));
}