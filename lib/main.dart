import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/app/landing_page.dart';
import 'package:flutter_steps_tracker/services/auth.dart';
import 'package:flutter_steps_tracker/utils/colors.dart';
import 'package:provider/provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Initializing Firebase...');
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    

    print('Initializing Firebase App Check...');
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    );
    print('Firebase App Check initialized successfully');
    
    runApp(const MyApp());
  } catch (e) {
    print('Error during initialization: $e');

    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Ошибка инициализации приложения: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<AuthBase>(
      create: (context) => Auth(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Health Helper',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: mobileBackgroundColor,
        ),
        home: const LandingPage(),
      ),
    );
  }
}
