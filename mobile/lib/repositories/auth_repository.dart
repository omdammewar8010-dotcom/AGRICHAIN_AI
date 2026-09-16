import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthRepository {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  UserModel _currentDemoUser = const UserModel(
    userId: 'USER-001',
    name: 'Rahul Patil',
    email: 'rahul@agrichain.ai',
    phone: '+91 98230 45678',
    role: AppConstants.roleFarmer,
    farmId: 'FARM-NASHIK-01',
  );

  Stream<User?> get authStateChanges =>
      _auth != null ? _auth!.authStateChanges() : Stream.value(null);

  UserModel get currentDemoUser => _currentDemoUser;

  void setDemoRole(String role) {
    _currentDemoUser = UserModel(
      userId: _currentDemoUser.userId,
      name: role == AppConstants.roleTransporter
          ? 'Vikram Shinde'
          : (role == AppConstants.roleAdmin
              ? 'Admin Command Control'
              : (role == AppConstants.roleBuyer
                  ? 'Reliance Fresh Sourcing'
                  : 'Rahul Patil')),
      email: '${role.toLowerCase()}@agrichain.ai',
      phone: _currentDemoUser.phone,
      role: role,
      farmId: _currentDemoUser.farmId,
    );
  }

  Future<UserModel> getUserProfile(String uid) async {
    try {
      if (_firestore != null) {
        final doc = await _firestore!.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      }
    } catch (_) {
      // Fallback in demo mode
    }
    return _currentDemoUser;
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      if (_auth != null) {
        await _auth!.signInWithEmailAndPassword(email: email, password: password);
      }
    } catch (_) {
      // In offline/demo mode, succeed silently with mock user
    }
  }

  Future<void> signOut() async {
    try {
      if (_auth != null) {
        await _auth!.signOut();
      }
    } catch (_) {}
  }
}
