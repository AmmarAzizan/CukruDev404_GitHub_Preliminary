import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeDefinition {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool isMonthly;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.isMonthly,
  });

  static final List<BadgeDefinition> all = [
    const BadgeDefinition(
      id: 'first_step',
      name: 'First Step',
      emoji: '🔥',
      description: 'Recorded your first ever expense.',
      isMonthly: false,
    ),
    const BadgeDefinition(
      id: 'streak_7',
      name: '7-Day Streak',
      emoji: '📅',
      description: 'Maintained a 7-day tracking streak.',
      isMonthly: false,
    ),
    const BadgeDefinition(
      id: 'streak_30',
      name: '30-Day Streak',
      emoji: '💪',
      description: 'Maintained an incredible 30-day streak.',
      isMonthly: false,
    ),
    const BadgeDefinition(
      id: 'budget_master',
      name: 'Budget Master',
      emoji: '💰',
      description: 'Completed a month without exceeding your budget.',
      isMonthly: true,
    ),
    const BadgeDefinition(
      id: 'saving_hero',
      name: 'Saving Hero',
      emoji: '🎯',
      description: 'Reached your saving target for the month.',
      isMonthly: true,
    ),
    const BadgeDefinition(
      id: 'health_champion',
      name: 'Health Champion',
      emoji: '⭐',
      description: 'Achieved a Financial Health Score of 80+ this month.',
      isMonthly: true,
    ),
  ];

  String get currentId {
    if (!isMonthly) return id;
    final now = DateTime.now();
    return '${id}_${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}

class EarnedBadge {
  final String id;
  final String name;
  final DateTime earnedAt;

  const EarnedBadge({
    required this.id,
    required this.name,
    required this.earnedAt,
  });

  factory EarnedBadge.fromMap(Map<String, dynamic> m) => EarnedBadge(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        earnedAt: (m['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'earnedAt': Timestamp.fromDate(earnedAt),
        'isEarned': true,
      };
}

class RewardData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastRecordedDate;
  final List<EarnedBadge> earnedBadges;

  const RewardData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastRecordedDate,
    required this.earnedBadges,
  });

  static const empty = RewardData(
    currentStreak: 0,
    longestStreak: 0,
    lastRecordedDate: null,
    earnedBadges: [],
  );

  factory RewardData.fromFirestore(Map<String, dynamic> data) {
    final rawBadges = data['badges'] as List<dynamic>? ?? [];
    final earned = rawBadges
        .map((b) => EarnedBadge.fromMap(Map<String, dynamic>.from(b as Map)))
        .toList();
    return RewardData(
      currentStreak: (data['currentStreak'] as num? ?? 0).toInt(),
      longestStreak: (data['longestStreak'] as num? ?? 0).toInt(),
      lastRecordedDate:
          (data['lastRecordedDate'] as Timestamp?)?.toDate(),
      earnedBadges: earned,
    );
  }

  bool isBadgeEarned(BadgeDefinition def) =>
      earnedBadges.any((b) => b.id == def.currentId);

  DateTime? badgeEarnedAt(BadgeDefinition def) =>
      earnedBadges.where((b) => b.id == def.currentId).firstOrNull?.earnedAt;

  bool get recordedToday {
    if (lastRecordedDate == null) return false;
    final today = DateTime.now();
    final last = lastRecordedDate!;
    return last.year == today.year &&
        last.month == today.month &&
        last.day == today.day;
  }
}
