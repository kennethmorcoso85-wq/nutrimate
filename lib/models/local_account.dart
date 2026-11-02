class LocalAccount {
  LocalAccount({
    required this.name,
    required this.email,
    this.id,
    this.dateJoined,
    this.role = 'user',
    this.active = true,
  });

  final int? id;
  final String name;
  final String email;
  final DateTime? dateJoined;
  final String role;
  bool active;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'email': email,
    'role': role,
    'is_active': active,
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
  );

  bool get isAdmin => role.toLowerCase() == 'admin';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
