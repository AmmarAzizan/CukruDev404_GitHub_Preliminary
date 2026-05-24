import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BudgetCategory {
  final String category;
  final String icon;
  final double amount;
  final String color;

  const BudgetCategory({
    required this.category,
    required this.icon,
    required this.amount,
    required this.color,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
        category: (json['category'] as String?) ?? 'Other',
        icon: (json['icon'] as String?) ?? 'category',
        amount: ((json['amount'] as num?) ?? 0).toDouble(),
        color: (json['color'] as String?) ?? '#9E9E9E',
      );

  Map<String, dynamic> toJson() => {
        'category': category,
        'icon': icon,
        'amount': amount,
        'color': color,
        'spent': 0.0,
      };

  BudgetCategory copyWith({
    String? category,
    String? icon,
    double? amount,
    String? color,
  }) =>
      BudgetCategory(
        category: category ?? this.category,
        icon: icon ?? this.icon,
        amount: amount ?? this.amount,
        color: color ?? this.color,
      );

  Color get flutterColor {
    try {
      final hex = color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF9E9E9E);
    }
  }

  IconData get flutterIcon => iconMap[icon] ?? Icons.category_rounded;

  static const Map<String, IconData> iconMap = {
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_rounded,
    'school': Icons.school_rounded,
    'movie': Icons.movie_rounded,
    'savings': Icons.savings_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'home': Icons.home_rounded,
    'receipt': Icons.receipt_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'phone': Icons.phone_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'coffee': Icons.coffee_rounded,
    'electric_bolt': Icons.electric_bolt_rounded,
    'wifi': Icons.wifi_rounded,
    'category': Icons.category_rounded,
  };

  static const List<String> presetColors = [
    '#FF6B6B', '#4ECDC4', '#FFE66D', '#5C6BC0',
    '#2ECC71', '#E67E22', '#9B59B6', '#3498DB',
    '#E74C3C', '#1ABC9C', '#F39C12', '#00897B',
  ];
}

class BudgetModel {
  final String month;
  final DateTime generatedAt;
  final bool isAIGenerated;
  final List<BudgetCategory> categories;

  const BudgetModel({
    required this.month,
    required this.generatedAt,
    required this.isAIGenerated,
    required this.categories,
  });

  factory BudgetModel.fromFirestore(Map<String, dynamic> data) {
    final cats = (data['categories'] as List<dynamic>? ?? [])
        .map((c) => BudgetCategory.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
    return BudgetModel(
      month: (data['month'] as String?) ?? '',
      generatedAt:
          (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAIGenerated: (data['isAIGenerated'] as bool?) ?? false,
      categories: cats,
    );
  }

  double get totalBudgeted => categories.fold(0.0, (s, c) => s + c.amount);
}

class BudgetReviewArgs {
  final List<BudgetCategory> categories;
  final bool fromSetup;
  const BudgetReviewArgs({required this.categories, this.fromSetup = false});
}
