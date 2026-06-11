class MoodEntry {
  final String id;
  final DateTime timestamp;
  final String mood;
  final int energyLevel;
  final String stressLevel;
  final String sleepQuality;

  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.mood,
    required this.energyLevel,
    required this.stressLevel,
    required this.sleepQuality,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        mood: json['mood'] as String,
        energyLevel: json['energyLevel'] as int,
        stressLevel: json['stressLevel'] as String,
        sleepQuality: json['sleepQuality'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'mood': mood,
        'energyLevel': energyLevel,
        'stressLevel': stressLevel,
        'sleepQuality': sleepQuality,
      };

  static const Map<String, String> moodEmojis = {
    'happy': '😊',
    'energetic': '⚡',
    'calm': '😌',
    'focused': '🎯',
    'cozy': '🛋️',
    'tired': '😴',
    'stressed': '😰',
  };

  static const Map<String, String> moodLabels = {
    'happy': 'Happy',
    'energetic': 'Energetic',
    'calm': 'Calm',
    'focused': 'Focused',
    'cozy': 'Cozy',
    'tired': 'Tired',
    'stressed': 'Stressed',
  };

  String get moodEmoji => moodEmojis[mood] ?? '🙂';
  String get moodLabel => moodLabels[mood] ?? mood;

  String get energyLabel {
    switch (energyLevel) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Medium';
    }
  }

  static const Map<String, String> stressLabels = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
  };

  static const Map<String, String> sleepLabels = {
    'poor': 'Poor 😔',
    'normal': 'Normal 😐',
    'good': 'Good 😊',
  };

  String get backendMoodTag {
    switch (mood) {
      case 'tired':
        return 'energetic';
      case 'stressed':
        return 'calm';
      default:
        return mood;
    }
  }
}
