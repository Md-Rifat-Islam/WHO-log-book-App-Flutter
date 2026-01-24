class FormTemplate {
  final String id;
  final String roleId;
  final String districtId;
  final String logType;
  final String eventType;
  final int version;
  final bool isActive;
  final Map<String, dynamic> templateJson;

  FormTemplate({
    required this.id,
    required this.roleId,
    required this.districtId,
    required this.logType,
    required this.eventType,
    required this.version,
    required this.isActive,
    required this.templateJson,
  });

  factory FormTemplate.fromMap(String id, Map<String, dynamic> map) {
    return FormTemplate(
      id: id,
      // Fixed: Normalize to lowercase to match DB 'yesno' and lowercase logic
      roleId: (map['roleId'] ?? '').toString().toLowerCase().trim(),
      districtId: (map['districtId'] ?? '').toString().toLowerCase().trim(),
      logType: (map['logType'] ?? '').toString(),
      eventType: (map['eventType'] ?? 'general').toString(),
      version: (map['version'] is int) ? map['version'] as int : 1,
      isActive: map['isActive'] == true,
      templateJson: Map<String, dynamic>.from(map['templateJson'] ?? {}),
    );
  }

  // --- GETTERS ---

  String get titleBn => (templateJson['titleBn'] ?? 'দৈনিক লগ').toString();

  /// Extract header fields (usually metadata like Date, Name)
  List<Map<String, dynamic>> get headerFields => _extractList('headerFields');

  /// Extract main form fields
  List<Map<String, dynamic>> get fields => _extractList('fields');

  // Helper to safely parse lists from JSON
  List<Map<String, dynamic>> _extractList(String key) {
    final raw = templateJson[key];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // --- UTILITIES ---

  Map<String, dynamic> toMap() {
    return {
      'roleId': roleId,
      'districtId': districtId,
      'logType': logType,
      'eventType': eventType,
      'version': version,
      'isActive': isActive,
      'templateJson': templateJson,
    };
  }

  /// Useful for testing or creating a modified version of a template
  FormTemplate copyWith({bool? isActive, int? version}) {
    return FormTemplate(
      id: id,
      roleId: roleId,
      districtId: districtId,
      logType: logType,
      eventType: eventType,
      version: version ?? this.version,
      isActive: isActive ?? this.isActive,
      templateJson: templateJson,
    );
  }
}