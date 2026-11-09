class LocalAccount {
  LocalAccount({
    required this.name,
    required this.email,
    this.id,
    this.dateJoined,
    this.role = 'user',
    this.active = true,
    this.emailVerified = false,
    this.preferences = const {},
  });

  final int? id;
  final String name;
  final String email;
  final DateTime? dateJoined;
  final String role;
  bool active;
  final bool emailVerified;
  final Map<String, dynamic> preferences;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'email': email,
    'role': role,
    'is_active': active,
    'is_email_verified': emailVerified,
    'preferences': preferences,
    if (dateJoined != null) 'date_joined': dateJoined!.toIso8601String(),
  };

  factory LocalAccount.fromJson(Map<String, dynamic> json) => LocalAccount(
    id: json['id'] as int?,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String? ?? 'user',
    dateJoined: json['date_joined'] == null
        ? null
        : DateTime.parse(json['date_joined'] as String),
    active: json['is_active'] as bool? ?? json['active'] as bool? ?? true,
    emailVerified: json['is_email_verified'] as bool? ?? false,
    preferences: Map<String, dynamic>.from(
      json['preferences'] as Map? ?? const {},
    ),
  );

  bool get isAdmin => role.toLowerCase() == 'admin';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
