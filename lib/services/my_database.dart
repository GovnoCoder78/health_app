import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/app/home/shop/models/shop.dart';
import 'package:flutter_steps_tracker/models/bought_item.dart';
import 'package:flutter_steps_tracker/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyDatabase with ChangeNotifier {
  static MyDatabase? _instance;
  static MyDatabase get instance {
    if (_instance == null) {
      throw Exception('MyDatabase не инициализирован. Вызовите MyDatabase.initialize() перед использованием.');
    }
    return _instance!;
  }

  static Future<void> initialize(String uid, String name) async {
    _instance = MyDatabase._internal(uid: uid, name: name);
    await _instance!.initDatabase();
  }

  MyDatabase._internal({required this.uid, required this.name});
  
  final String name;
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _points = 0;
  final List<BoughtItem> _allBoughtItems = [];

  List<BoughtItem> get allBoughtItems {
    return [..._allBoughtItems];
  }

  int get points {
    return _points;
  }

  Future<void> initDatabase() async {
    final userData = await _firestore.collection("user").doc(uid).get();
    final mydoc = userData.data();
    if (mydoc?["points"] != null) {
      _points = mydoc!["points"];
    }
    if (mydoc?["buyLog"] != null) {
      for (var boughtItem in mydoc!["buyLog"]) {
        _allBoughtItems.add(BoughtItem.fromMap(boughtItem));
      }
    }
  }

  Future<void> deleteAccount() async{
    try{
      await _firestore.collection('user').doc(uid).delete();
    }
    catch (e){
      print('error deleting doc: $e');
    }
  }

  Future<void> updateSteps(int newSteps) async{
    try{
      //int totalSteps = currentSteps + newSteps;
      await _firestore.collection('user').doc(uid).update({'steps': newSteps});
    } catch (e){
      print('Error while updating steps: $e');
    }
  }

  Future<int> getSteps() async{
    try {
      DocumentSnapshot doc = await _firestore
          .collection('user')
          .doc(uid)
          .get();
      Map <String, dynamic> data = doc.data() as Map<String, dynamic>;
      int currentSteps = data['steps'];
      return currentSteps;
    }
    catch (e){
      print('Error while get steps: $e');
      return 0;
    }
  }

  Future<void> updatePoints() async {
    _points = points + 10;
    _firestore.collection("user").doc(uid).update({"points": _points});
    notifyListeners();
  }

  Future<void> buyItem(int points, Shop shop) async {
    _points = points;
    final buyLog = BoughtItem(
        date: dateFormat.format(DateTime.now()),
        itemId: shop.id,
        itemName: shop.name,
        itemCost: shop.cost);
    _allBoughtItems.add(buyLog);
    _firestore.collection("user").doc(uid).update({"points": points});
    _firestore.collection("user").doc(uid).update({
      "buyLog": [
        ..._allBoughtItems.map((e) => e.toMap()).toList(),
      ]
    });
    notifyListeners();
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  Future<bool> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String nickname,
  }) async {
    try {
      // Создаем пользователя в Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Создаем документ пользователя в Firestore
        await _firestore.collection('user').doc(userCredential.user!.uid).set({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'nickname': nickname,
          'points': 0,
          'steps': 0,
          'buyLog': [],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Инициализируем базу данных после успешной регистрации
        await MyDatabase.initialize(userCredential.user!.uid, nickname);
        return true;
      }
      return false;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user != null;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
