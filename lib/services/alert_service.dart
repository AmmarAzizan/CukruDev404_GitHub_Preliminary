import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlertInfo {
  final String key;
  final String title;
  final String message;
  final bool isOverBudget;
  final String? category;

  const AlertInfo({
    required this.key,
    required this.title,
    required this.message,
    required this.isOverBudget,
    this.category,
  });
}

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Navigation handler set by the app once the router is ready.
  static void Function(String route)? _onNotificationTap;
  static void setNavigationHandler(void Function(String route) handler) {
    _onNotificationTap = handler;
  }

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (response) {
        _onNotificationTap?.call('/profile');
      },
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<List<AlertInfo>> checkAlerts(String uid) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final budgetDoc = await db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(monthKey)
        .get();
    if (!budgetDoc.exists) return [];

    final cats =
        (budgetDoc.data()!['categories'] as List<dynamic>);

    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final txSnapshot = await db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    final spending = <String, double>{};
    double totalSpent = 0;
    for (final doc in txSnapshot.docs) {
      final data = doc.data();
      final cat = data['category'] as String;
      final amount = (data['amount'] as num).toDouble();
      spending[cat] = (spending[cat] ?? 0) + amount;
      totalSpent += amount;
    }

    final alertDoc = await db
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .doc(monthKey)
        .get();
    final sentKeys = alertDoc.exists
        ? Set<String>.from(alertDoc.data()!.keys)
        : <String>{};

    final newAlerts = <AlertInfo>[];
    final newKeys = <String, dynamic>{};
    double totalBudgeted = 0;

    for (final cat in cats) {
      final catName = cat['category'] as String;
      final budget = (cat['amount'] as num).toDouble();
      totalBudgeted += budget;
      if (budget <= 0) continue;

      final spent = spending[catName] ?? 0;
      final pct = spent / budget;

      if (pct >= 1.0 && !sentKeys.contains('cat_${catName}_100')) {
        final key = 'cat_${catName}_100';
        newAlerts.add(AlertInfo(
          key: key,
          title: '$catName Budget Exceeded',
          message: 'You have exceeded your $catName budget.',
          isOverBudget: true,
          category: catName,
        ));
        newKeys[key] = FieldValue.serverTimestamp();
      } else if (pct >= 0.8 && !sentKeys.contains('cat_${catName}_80')) {
        final key = 'cat_${catName}_80';
        newAlerts.add(AlertInfo(
          key: key,
          title: '$catName Budget Warning',
          message:
              'You\'ve used ${(pct * 100).toStringAsFixed(0)}% of your $catName budget.',
          isOverBudget: false,
          category: catName,
        ));
        newKeys[key] = FieldValue.serverTimestamp();
      }
    }

    if (totalBudgeted > 0) {
      final overallPct = totalSpent / totalBudgeted;
      if (overallPct >= 1.0 && !sentKeys.contains('overall_100')) {
        newAlerts.add(AlertInfo(
          key: 'overall_100',
          title: 'Total Budget Exceeded',
          message: 'You have exceeded your total monthly budget.',
          isOverBudget: true,
        ));
        newKeys['overall_100'] = FieldValue.serverTimestamp();
      } else if (overallPct >= 0.8 && !sentKeys.contains('overall_80')) {
        newAlerts.add(AlertInfo(
          key: 'overall_80',
          title: 'Total Budget Warning',
          message:
              'You\'ve used ${(overallPct * 100).toStringAsFixed(0)}% of your total monthly budget.',
          isOverBudget: false,
        ));
        newKeys['overall_80'] = FieldValue.serverTimestamp();
      }
    }

    if (newKeys.isNotEmpty) {
      await db
          .collection('users')
          .doc(uid)
          .collection('alerts')
          .doc(monthKey)
          .set(newKeys, SetOptions(merge: true));

      for (int i = 0; i < newAlerts.length; i++) {
        await _sendNotification(i, newAlerts[i]);
      }
    }

    return newAlerts;
  }

  Future<void> _sendNotification(int id, AlertInfo alert) async {
    const androidDetails = AndroidNotificationDetails(
      'spendly_alerts',
      'Spending Alerts',
      channelDescription:
          'Alerts when you approach or exceed your budget',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _notifications.show(
      id,
      alert.title,
      alert.message,
      const NotificationDetails(android: androidDetails),
    );
  }
}
