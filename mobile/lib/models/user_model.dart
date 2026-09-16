class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role; // admin, farmer, transporter, warehouse_manager, buyer
  final String? farmId;
  final String? profileImage;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.farmId,
    this.profileImage,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      userId: id,
      name: map['name'] ?? 'Anonymous User',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'farmer',
      farmId: map['farmId'],
      profileImage: map['profileImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'farmId': farmId,
      'profileImage': profileImage,
    };
  }
}
