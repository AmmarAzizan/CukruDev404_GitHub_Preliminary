import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';

class BudgetService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;
  String _monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  DocumentReference _doc(DateTime month) => _db
      .collection('users')
      .doc(_uid)
      .collection('budgets')
      .doc(_monthKey(month));

  Stream<BudgetModel?> watchCurrentBudget() {
    return _doc(DateTime.now()).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return BudgetModel.fromFirestore(snap.data() as Map<String, dynamic>);
    });
  }

  Future<void> saveBudget(List<BudgetCategory> categories) async {
    final now = DateTime.now();
    await _doc(now).set({
      'month': _monthKey(now),
      'generatedAt': FieldValue.serverTimestamp(),
      'isAIGenerated': true,
      'categories': categories.map((c) => c.toJson()).toList(),
    });
  }
}
