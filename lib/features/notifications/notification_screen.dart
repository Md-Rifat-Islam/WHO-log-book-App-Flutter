import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../stores/session_store.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // Project Theme Colors
  static const Color tealWater = Color(0xFF0B6E69);
  static const Color bgColor = Color(0xFFF7F8FA);

  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items');
  }

  Future<void> _markAllRead(BuildContext context, String uid) async {
    final q = await _itemsRef(uid)
        .where('read', isEqualTo: false)
        .limit(200)
        .get();

    if (q.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('সব নোটিফিকেশন দেখা হয়েছে (Marked as read)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openNotification(
      BuildContext context, {
        required String uid,
        required String docId,
        required String? logId,
        required bool read,
      }) async {
    if (!read) {
      await _itemsRef(uid).doc(docId).update({'read': true});
    }

    if (!context.mounted) return;
    if (logId != null && logId.trim().isNotEmpty) {
      context.go('/log-view/$logId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই নোটিফিকেশনের সাথে কোনো লগ লিংক নেই')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No profile loaded.')));
    }

    final stream = _itemsRef(user.uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: tealWater,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 85, // Standardized height for visibility
        centerTitle: false,
        // Standardizing the back button
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            // --- LOGO IMAGE ---
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                  width: 38,
                  height: 38,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.water_drop_rounded,
                      color: tealWater,
                      size: 24
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // --- TEXT CONTENT ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      letterSpacing: -0.5,
                      color: Colors.white
                    ),
                  ),
                  Text(
                    '${user.name} ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  Text(
                    '(${user.districtId})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            iconSize: 28, // Matches the dashboard action sizes
            icon: const Icon(Icons.mark_chat_read_rounded, color: Colors.white),
            onPressed: () => _markAllRead(context, user.uid),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: tealWater));

          final docs = snap.data!.docs;
          if (docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data();
              final read = (m['read'] == true);

              return _buildNotificationTile(context, user.uid, d.id, m, read);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, String uid, String docId, Map<String, dynamic> m, bool read) {
    final title = (m['title'] ?? 'নোটিফিকেশন').toString();
    final body = (m['body'] ?? '').toString();
    final logId = m['logId']?.toString();
    final timeText = _prettyTimestamp(m['createdAt']);

    return Container(
      decoration: BoxDecoration(
        color: read ? Colors.transparent : tealWater.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: ListTile(
        onTap: () => _openNotification(context, uid: uid, docId: docId, logId: logId, read: read),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: read ? Colors.grey.shade200 : tealWater.withOpacity(0.2),
          child: Icon(
            read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
            color: read ? Colors.grey : tealWater,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: read ? FontWeight.w500 : FontWeight.bold,
                  fontSize: 15,
                  color: read ? Colors.black87 : tealWater,
                ),
              ),
            ),
            if (!read)
              const CircleAvatar(radius: 4, backgroundColor: Colors.orange),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                color: read ? Colors.black54 : Colors.black87,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeText,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('কোনো নোটিফিকেশন নেই', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  String _prettyTimestamp(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      final now = DateTime.now();
      final diff = now.difference(d);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';

      return '${d.day}/${d.month}/${d.year}';
    }
    return '';
  }
}