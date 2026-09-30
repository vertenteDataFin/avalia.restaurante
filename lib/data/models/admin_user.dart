class AdminUser {
  final String uid;
  final String email;
  final String name;
  final bool isApproved;
  final String role; // 'admin' ou 'viewer'

  AdminUser({
    required this.uid,
    required this.email,
    required this.name,
    this.isApproved = false,
    this.role = 'admin',
  });

  bool get isAdmin => role == 'admin';
  bool get isViewer => role == 'viewer';
  bool get canDelete => role == 'admin';
  bool get canManageUsers => role == 'admin';

  String get roleLabel {
    switch (role) {
      case 'viewer':
        return 'Visualizador';
      case 'admin':
      default:
        return 'Administrador';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'isApproved': isApproved,
      'role': role,
    };
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isApproved: json['isApproved'] as bool? ?? false,
      role: json['role'] as String? ?? 'admin',
    );
  }

  AdminUser copyWith({
    String? uid,
    String? email,
    String? name,
    bool? isApproved,
    String? role,
  }) {
    return AdminUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      isApproved: isApproved ?? this.isApproved,
      role: role ?? this.role,
    );
  }
}
