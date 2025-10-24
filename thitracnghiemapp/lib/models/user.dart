class User {
  final String id;
  final String userName;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final DateTime? birthday;
  final String? gender;
  final String? avatarUrl;
  final bool isLocked;
  final DateTime createdAt;
  final List<String> roles;

  const User({
    required this.id,
    required this.userName,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.birthday,
    this.gender,
    this.avatarUrl,
    required this.isLocked,
    required this.createdAt,
    required this.roles,
  });

  bool get isAdmin => roles.any((role) => role.toLowerCase() == 'admin');

  User copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    DateTime? birthday,
    String? gender,
    String? avatarUrl,
    bool? isLocked,
    List<String>? roles,
  }) {
    return User(
      id: id,
      userName: userName,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt,
      roles: roles ?? this.roles,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      userName: json['userName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['soDienThoai'] as String?,
      birthday: json['ngaySinh'] != null
          ? DateTime.tryParse(json['ngaySinh'] as String)
          : null,
      gender: json['gioiTinh'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isLocked: json['trangThaiKhoa'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ??
                DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'fullName': fullName,
      'soDienThoai': phoneNumber,
      'ngaySinh': birthday?.toIso8601String(),
      'gioiTinh': gender,
      'avatarUrl': avatarUrl,
      'trangThaiKhoa': isLocked,
      'createdAt': createdAt.toIso8601String(),
      'roles': roles,
    };
  }
}
