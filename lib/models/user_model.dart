class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String role;
  final String? gender;
  final String? profileImage;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    required this.role,
    this.gender,
    this.profileImage,
    required this.isEmailVerified,
    required this.isPhoneVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'provider',
      gender: json['gender'],
      profileImage: json['profile_image'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'gender': gender,
      'profile_image': profileImage,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
    };
  }
}
