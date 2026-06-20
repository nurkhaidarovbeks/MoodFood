class UserModel {
  final String id;
  final String email;
  final String? name;
  final String authProvider;
  final bool isEmailVerified;
  final bool isProfileComplete;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    required this.authProvider,
    required this.isEmailVerified,
    required this.isProfileComplete,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      authProvider: json['authProvider'] as String? ?? 'email',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'authProvider': authProvider,
        'isEmailVerified': isEmailVerified,
        'isProfileComplete': isProfileComplete,
      };

  String get displayName => name ?? email.split('@').first;

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? authProvider,
    bool? isEmailVerified,
    bool? isProfileComplete,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        authProvider: authProvider ?? this.authProvider,
        isEmailVerified: isEmailVerified ?? this.isEmailVerified,
        isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      );
}
