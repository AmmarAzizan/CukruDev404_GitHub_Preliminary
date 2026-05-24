import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<bool> isProfileCompleted() async {
    final profile = await getUserProfile();
    return profile?['profileCompletedAt'] != null;
  }

  Future<void> saveProfile({
    required String profileType,
    required double monthlyBudget,
    double savingTarget = 0,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    await _firestore.collection('users').doc(user.uid).update({
      'profileType': profileType,
      'monthlyBudget': monthlyBudget,
      'savingTarget': savingTarget,
      'profileCompletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile({
    required String profileType,
    required double monthlyBudget,
    double savingTarget = 0,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    await _firestore.collection('users').doc(user.uid).update({
      'profileType': profileType,
      'monthlyBudget': monthlyBudget,
      'savingTarget': savingTarget,
    });
  }
}
