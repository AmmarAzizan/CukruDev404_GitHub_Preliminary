import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  Stream<List<ExpenseModel>> watchExpenses(String uid) => _col(uid)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ExpenseModel.fromFirestore).toList());

  Future<void> addExpense(ExpenseModel expense) async {
    final uid = _auth.currentUser!.uid;
    await _col(uid).add(expense.toMap());
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final uid = _auth.currentUser!.uid;
    await _col(uid).doc(expense.id).update(expense.toUpdateMap());
  }

  Future<void> deleteExpense(String id) async {
    final uid = _auth.currentUser!.uid;
    await _col(uid).doc(id).delete();
  }
}
