import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_steps_tracker/services/auth.dart';

class SignInManager {
  SignInManager({required this.auth, required this.isLoading});
  final AuthBase auth;
  final ValueNotifier<bool> isLoading;

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;
      return await auth.signInWithEmailAndPassword(email, password);
    } catch (e) {
      isLoading.value = false;
      rethrow;
    }
  }
}
