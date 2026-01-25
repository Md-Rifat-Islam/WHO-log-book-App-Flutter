import 'package:flutter/material.dart';
import '../core/firebase_refs.dart';
import '../models/form_template.dart';

class TemplateService {
  Future<FormTemplate?> fetchActiveTemplate({
    required String roleId,
    required String districtId,
    required String logType,
    String? eventType,
  }) async {
    final cleanRole = roleId.toLowerCase().trim();
    final cleanDist = districtId.toLowerCase().trim();
    final cleanLogType = logType.toLowerCase().trim();
    final et = (eventType == null || eventType.trim().isEmpty) ? 'general' : eventType.trim();

    try {
      // এই একটি কুয়েরিই সব ধরণের (General/Flooded) টেমপ্লেট খুঁজে আনবে
      final snapshot = await templatesRef
          .where('roleId', isEqualTo: cleanRole)
          .where('districtId', isEqualTo: cleanDist)
          .where('logType', isEqualTo: cleanLogType)
          .where('eventType', isEqualTo: et)
          .where('isActive', isEqualTo: true)
          .orderBy('version', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return FormTemplate.fromMap(doc.id, doc.data());
      } else {
        // debugPrint("ℹ️ Skip: $cleanLogType ($et) not assigned to $cleanRole");
      }
    } catch (e) {
      // ইনডেক্স না থাকলে এখানে লিংক আসবে, সেই লিংকে একবার ক্লিক করলেই সারাজীবনের জন্য সমাধান
      debugPrint("❌ Firestore Error: $e");
    }
    return null;
  }
}