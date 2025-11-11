class DeviceProfile {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;
  final String? avatarPath;
  final String? deviceLabel;

  const DeviceProfile({
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.avatarPath,
    this.deviceLabel,
  });

  Map<String, dynamic> toMap() => {
    'id': 1,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'avatar_path': avatarPath,
    'device_label': deviceLabel,
  };

  static DeviceProfile fromMap(Map<String, Object?> m) => DeviceProfile(
    fullName: m['full_name'] as String?,
    email: m['email'] as String?,
    phone: m['phone'] as String?,
    role: m['role'] as String?,
    avatarPath: m['avatar_path'] as String?,
    deviceLabel: m['device_label'] as String?,
  );

  bool get isComplete => (fullName?.isNotEmpty ?? false);
}
