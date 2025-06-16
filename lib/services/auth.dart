import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_steps_tracker/services/my_database.dart';

class UserModel {
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
  });
  final String? uid;
  final String? email;
  final String? displayName;
}

abstract class AuthBase {
  Stream<UserModel?> get onAuthStateChanged;
  UserModel? currentUser();
  Future<UserModel?> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<String> currentUserName();
}

class Auth implements AuthBase {
  UserModel? _userFromFirebase(User? user) {
    if (user == null) {
      print('Auth: User is null');
      return null;
    }
    print('Auth: Creating UserModel for user ${user.uid}');
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    print('Auth: Setting up auth state changes stream');
    return FirebaseAuth.instance.authStateChanges().map((user) {
      print('Auth: Auth state changed for user: ${user?.uid}');
      return _userFromFirebase(user);
    });
  }

  @override
  UserModel? currentUser() {
    final user = FirebaseAuth.instance.currentUser;
    print('Auth: Getting current user: ${user?.uid}');
    if (user == null) return null;
    return _userFromFirebase(user);
  }

  @override
  Future<String> currentUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Auth: No current user when getting username');
        return '';
      }
      print('Auth: Getting username for user ${user.uid}');
      final userData = await FirebaseFirestore.instance
          .collection("user")
          .doc(user.uid)
          .get();
      
      if (!userData.exists) {
        print('Auth: No user document found for ${user.uid}');
        return '';
      }
      
      final mydoc = userData.data();
      if (mydoc == null) {
        print('Auth: User document data is null for ${user.uid}');
        return '';
      }
      
      final nickname = mydoc['nickname'] ?? '';
      print('Auth: Got nickname: $nickname for user ${user.uid}');
      return nickname;
    } catch (e) {
      print('Auth: Error getting username: $e');
      return '';
    }
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('Auth: Attempting sign in for email: $email');
      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (authResult.user != null) {
        print('Auth: Sign in successful for user ${authResult.user!.uid}');
        
        // Проверяем существование документа пользователя
        final userData = await FirebaseFirestore.instance
            .collection("user")
            .doc(authResult.user!.uid)
            .get();
            
        if (!userData.exists) {
          print('Auth: No user document found for existing user');
          // Если документ не существует, выходим из системы
          await FirebaseAuth.instance.signOut();
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Пользователь не найден. Пожалуйста, зарегистрируйтесь.',
          );
        }
        
        final userDoc = userData.data();
        if (userDoc == null) {
          print('Auth: User document data is null');
          await FirebaseAuth.instance.signOut();
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Ошибка данных пользователя. Пожалуйста, зарегистрируйтесь заново.',
          );
        }
        
        final nickname = userDoc['nickname'] ?? '';
        print('Auth: Initializing database for user ${authResult.user!.uid} with nickname $nickname');
        await MyDatabase.initialize(
          authResult.user!.uid,
          nickname,
        );
      }
      
      return _userFromFirebase(authResult.user);
    } on FirebaseAuthException catch (e) {
      print('Auth: Firebase auth error during sign in: $e');
      rethrow;
    } catch (e) {
      print('Auth: Unexpected error during sign in: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      print('Auth: Attempting sign out');
      await FirebaseAuth.instance.signOut();
      print('Auth: Sign out successful');
    } catch (e) {
      print('Auth: Error during sign out: $e');
      rethrow;
    }
  }
}
