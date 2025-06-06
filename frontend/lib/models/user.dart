class User {
  final String phone;
  final String? email;
  final String? name;
  final String? picture;

  User({required this.phone, this.email, this.name, this.picture});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      phone: json['phone'],
      email: json['email'],
      name: json['name'],
      picture: json['picture'],
    );
  }
}