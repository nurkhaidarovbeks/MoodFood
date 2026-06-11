class ProfileModel {
  final int? age;
  final String? goal;
  final String? lifestyle;
  final String? budgetLevel;
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final List<String> customRestrictions;
  final bool onboardingCompleted;

  const ProfileModel({
    this.age,
    this.goal,
    this.lifestyle,
    this.budgetLevel,
    this.dietaryRestrictions = const [],
    this.allergies = const [],
    this.customRestrictions = const [],
    this.onboardingCompleted = false,
  });

  factory ProfileModel.empty() => const ProfileModel();

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      age: json['age'] as int?,
      goal: json['goal'] as String?,
      lifestyle: json['lifestyle'] as String?,
      budgetLevel: json['budgetLevel'] as String?,
      dietaryRestrictions: (json['dietaryRestrictions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      customRestrictions: (json['customRestrictions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (age != null) 'age': age,
        if (goal != null && goal!.isNotEmpty) 'goal': goal,
        if (lifestyle != null) 'lifestyle': lifestyle,
        if (budgetLevel != null) 'budgetLevel': budgetLevel,
        'dietaryRestrictions': dietaryRestrictions,
        'allergies': allergies,
        'customRestrictions': customRestrictions,
      };

  ProfileModel copyWith({
    int? age,
    String? goal,
    String? lifestyle,
    String? budgetLevel,
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    List<String>? customRestrictions,
    bool? onboardingCompleted,
  }) =>
      ProfileModel(
        age: age ?? this.age,
        goal: goal ?? this.goal,
        lifestyle: lifestyle ?? this.lifestyle,
        budgetLevel: budgetLevel ?? this.budgetLevel,
        dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
        allergies: allergies ?? this.allergies,
        customRestrictions: customRestrictions ?? this.customRestrictions,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      );

  static const Map<String, String> lifestyleLabels = {
    'student': 'Student',
    'professional': 'Young Professional',
    'other': 'Other',
  };

  static const Map<String, String> budgetLabels = {
    'low': 'Low (budget meals)',
    'medium': 'Medium',
    'high': 'High (no limit)',
  };

  static const Map<String, String> restrictionLabels = {
    'vegan': 'Vegan',
    'vegetarian': 'Vegetarian',
    'pescatarian': 'Pescatarian',
    'lactose_free': 'Lactose-free',
    'gluten_free': 'Gluten-free',
    'halal': 'Halal',
    'kosher': 'Kosher',
    'nut_allergy': 'Nut allergy',
    'egg_allergy': 'Egg allergy',
    'soy_allergy': 'Soy allergy',
  };
}
