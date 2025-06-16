import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/services/my_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthUtils {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Пожалуйста, введите корректный email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, подтвердите пароль';
    }
    if (value != password) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите имя';
    }
    if (value.length < 2) {
      return 'Имя должно содержать минимум 2 символа';
    }
    return null;
  }

  static String? validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите никнейм';
    }
    if (value.length < 3) {
      return 'Никнейм должен содержать минимум 3 символа';
    }
    return null;
  }

  static Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  static Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String nickname,
  }) async {
    try {
      // Создаем пользователя в Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Не удалось создать пользователя',
        );
      }

      // Создаем документ пользователя в Firestore
      await FirebaseFirestore.instance.collection("user").doc(userCredential.user!.uid).set({
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
        "nickname": nickname,
        "points": 0,
        "steps": 0,
        "buyLog": [],
      });

      // Инициализируем базу данных
      await MyDatabase.initialize(userCredential.user!.uid, nickname);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error during registration: $e');
      rethrow;
    }
  }
} 