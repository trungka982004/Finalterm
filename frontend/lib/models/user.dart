class User {
  final String phone;
  final String? email;
  final String? name;
  final String? picture;
  final bool twoFactorEnabled;
  final bool isEmailVerified;

  User({
    required this.phone,
    this.email,
    this.name,
    this.picture,
    this.twoFactorEnabled = false,
    this.isEmailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      name: json['name'] as String?,
      picture: json['picture'] as String?,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'name': name,
      'picture': picture,
      'twoFactorEnabled': twoFactorEnabled,
      'isEmailVerified': isEmailVerified,
    };
  }
}