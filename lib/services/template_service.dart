import '../core/firebase_refs.dart';
import '../models/form_template.dart';

class TemplateService {
  Future<FormTemplate?> fetchActiveTemplate({
    required String roleId,
    required String districtId,
    required String logType,
    String? eventType,
  }) async {
    final et = (eventType == null || eventType.trim().isEmpty)
        ? 'general'
        : eventType.trim();

    // Fix: Normalize IDs to lowercase and trim to match DB keys exactly
    final cleanRole = roleId.toLowerCase().trim();
    final cleanDist = districtId.toLowerCase().trim();

    // 1) Primary: with eventType
    try {
      final q1 = await templatesRef
          .where('roleId', isEqualTo: cleanRole)
          .where('districtId', isEqualTo: cleanDist)
          .where('logType', isEqualTo: logType)
          .where('eventType', isEqualTo: et)
          .where('isActive', isEqualTo: true)
          .orderBy('version', descending: true)
          .limit(1)
          .get();

      if (q1.docs.isNotEmpty) {
        final doc = q1.docs.first;
        return FormTemplate.fromMap(doc.id, doc.data());
      }
    } catch (e) {
      // Index error handling remains the same
    }

    // 2) Fallback: without eventType
    final q2 = await templatesRef
        .where('roleId', isEqualTo: cleanRole)
        .where('districtId', isEqualTo: cleanDist)
        .where('logType', isEqualTo: logType)
        .where('isActive', isEqualTo: true)
        .orderBy('version', descending: true)
        .limit(1)
        .get();

    if (q2.docs.isEmpty) return null;
    final doc = q2.docs.first;
    return FormTemplate.fromMap(doc.id, doc.data());
  }
}