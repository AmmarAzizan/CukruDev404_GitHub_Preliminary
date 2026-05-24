import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HealthScoreModel {
  final String month;
  final int score;
  final String status;
  final int budgetAdherence;
  final int savingProgress;
  final int spendingConsistency;
  final String trend;
  final List<String> tips;
  final DateTime calculatedAt;

  const HealthScoreModel({
    required this.month,
    required this.score,
    required this.status,
    required this.budgetAdherence,
    required this.savingProgress,
    required this.spendingConsistency,
    required this.trend,
    required this.tips,
    required this.calculatedAt,
  });

  factory HealthScoreModel.fromFirestore(Map<String, dynamic> data) {
    return HealthScoreModel(
      month: data['month'] as String? ?? '',
      score: (data['score'] as num? ?? 0).toInt(),
      status: data['status'] as String? ?? 'Fair',
      budgetAdherence: (data['budgetAdherence'] as num? ?? 0).toInt(),
      savingProgress: (data['savingProgress'] as num? ?? 0).toInt(),
      spendingConsistency: (data['spendingConsistency'] as num? ?? 0).toInt(),
      trend: data['trend'] as String? ?? 'stable',
      tips: List<String>.from(data['tips'] as List? ?? []),
      calculatedAt:
          (data['calculatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'month': month,
        'score': score,
        'status': status,
        'budgetAdherence': budgetAdherence,
        'savingProgress': savingProgress,
        'spendingConsistency': spendingConsistency,
        'trend': trend,
        'tips': tips,
        'calculatedAt': FieldValue.serverTimestamp(),
      };

  Color get scoreColor {
    if (score >= 80) return const Color(0xFF2ECC71);
    if (score >= 65) return const Color(0xFF3498DB);
    if (score >= 50) return const Color(0xFFE67E22);
    return const Color(0xFFE74C3C);
  }

  IconData get trendIcon {
    switch (trend) {
      case 'improving':
        return Icons.arrow_upward_rounded;
      case 'declining':
        return Icons.arrow_downward_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  Color get trendColor {
    switch (trend) {
      case 'improving':
        return const Color(0xFF2ECC71);
      case 'declining':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  String get trendLabel {
    switch (trend) {
      case 'improving':
        return 'Improving';
      case 'declining':
        return 'Declining';
      default:
        return 'Stable';
    }
  }
}
