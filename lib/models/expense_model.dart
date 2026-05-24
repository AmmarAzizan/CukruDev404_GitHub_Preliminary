import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExpenseModel {
  final String id;
  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final String source;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    this.source = 'manual',
    required this.createdAt,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String? ?? 'Others',
      note: data['note'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      source: data['source'] as String? ?? 'manual',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'category': category,
        'note': note,
        'date': Timestamp.fromDate(date),
        'source': source,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toUpdateMap() => {
        'amount': amount,
        'category': category,
        'note': note,
        'date': Timestamp.fromDate(date),
      };

  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    String? source,
    DateTime? createdAt,
  }) =>
      ExpenseModel(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        note: note ?? this.note,
        date: date ?? this.date,
        source: source ?? this.source,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ─── Category metadata ────────────────────────────────────────────────────────

class ExpenseCategory {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<ExpenseCategory> kCategories = [
  ExpenseCategory(
    value: 'Food',
    label: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFFF7043),
  ),
  ExpenseCategory(
    value: 'Transport',
    label: 'Transport',
    icon: Icons.directions_car_rounded,
    color: Color(0xFF1E88E5),
  ),
  ExpenseCategory(
    value: 'Entertainment',
    label: 'Entertainment',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFF8E24AA),
  ),
  ExpenseCategory(
    value: 'Shopping',
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFEC407A),
  ),
  ExpenseCategory(
    value: 'Education',
    label: 'Education',
    icon: Icons.school_rounded,
    color: Color(0xFF00897B),
  ),
  ExpenseCategory(
    value: 'Health',
    label: 'Health',
    icon: Icons.favorite_rounded,
    color: Color(0xFFE53935),
  ),
  ExpenseCategory(
    value: 'Others',
    label: 'Others',
    icon: Icons.category_rounded,
    color: Color(0xFF757575),
  ),
];

ExpenseCategory categoryFor(String value) => kCategories.firstWhere(
      (c) => c.value == value,
      orElse: () => kCategories.last,
    );
