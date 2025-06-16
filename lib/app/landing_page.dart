import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/app/home/permission_controller_screen.dart';
import 'package:flutter_steps_tracker/app/home/services/permission_model.dart';
import 'package:flutter_steps_tracker/app/login_page/sign_in_page.dart';
import 'package:flutter_steps_tracker/services/auth.dart';
import 'package:flutter_steps_tracker/services/my_database.dart';
import 'package:flutter_steps_tracker/widgets/loading_screen.dart';
import 'package:provider/provider.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthBase>(context, listen: false);
    return StreamBuilder<UserModel?>(
      stream: auth.onAuthStateChanged,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          UserModel? user = snapshot.data;
          if (user == null) {
            return SignInPage.create(context);
          }
          return FutureBuilder<String>(
              future: auth.currentUserName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingScreen();
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Scaffold(body: LoadingScreen());
                }
                final nickname = snapshot.data as String;
                if (user.uid == null) {
                  return const Scaffold(body: LoadingScreen());
                }
                return FutureBuilder<void>(
                  future: MyDatabase.initialize(user.uid!, nickname),
                  builder: (context, dbSnapshot) {
                    if (dbSnapshot.connectionState != ConnectionState.done) {
                      return const LoadingScreen();
                    }
                    return Provider<UserModel>.value(
                      value: UserModel(
                        displayName: nickname,
                        uid: user.uid,
                        email: user.email,
                      ),
                      child: MultiProvider(
                        providers: [
                          ChangeNotifierProvider<MyDatabase>.value(
                            value: MyDatabase.instance,
                          ),
                          ChangeNotifierProvider<PermissionModel>(
                            create: (_) => PermissionModel(),
                          ),
                        ],
                        child: const PermissionControllerScreen(),
                      ),
                    );
                  },
                );
              });
        } else {
          return const Scaffold(body: LoadingScreen());
        }
      },
    );
  }
}
