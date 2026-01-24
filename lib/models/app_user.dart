class AppUser {
  final String uid;
  final String name;
  final String roleId;
  final String? districtId; // Primary district for Operators
  final List<String> assignedDistrictIds; // List of districts for Supervisors/Admins
  final Map<String, dynamic> permissions;

  const AppUser({
    required this.uid,
    required this.name,
    required this.roleId,
    required this.districtId,
    required this.assignedDistrictIds,
    required this.permissions,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: (map['name'] ?? '').toString(),
      roleId: (map['roleId'] ?? '').toString(),
      districtId: map['districtId']?.toString(),
      assignedDistrictIds: (map['assignedDistrictIds'] is List)
          ? List<String>.from(map['assignedDistrictIds'])
          : const <String>[],
      permissions: (map['permissions'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(map['permissions'])
          : const <String, dynamic>{},
    );
  }

  // --- HELPER GETTERS ---

  bool get isAdmin => roleId.toLowerCase() == 'admin';

  bool get isSupervisor => roleId.toLowerCase() == 'supervisor';

  bool get canApprove => permissions['canApprove'] == true;

  /// Checks if a user has authority over a specific district
  bool hasAccessToDistrict(String? dId) {
    if (isAdmin) return true;
    if (dId == null) return false;
    return assignedDistrictIds.contains(dId) || districtId == dId;
  }

  // --- UTILITIES ---

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'roleId': roleId,
      'districtId': districtId,
      'assignedDistrictIds': assignedDistrictIds,
      'permissions': permissions,
    };
  }

  AppUser copyWith({
    String? name,
    String? roleId,
    String? districtId,
    List<String>? assignedDistrictIds,
    Map<String, dynamic>? permissions,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      roleId: roleId ?? this.roleId,
      districtId: districtId ?? this.districtId,
      assignedDistrictIds: assignedDistrictIds ?? this.assignedDistrictIds,
      permissions: permissions ?? this.permissions,
    );
  }
}