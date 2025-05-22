import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/app/home/pedometer/steps_counter_screen.dart';
import 'package:flutter_steps_tracker/app/home/profile/profile_screen.dart';
import 'package:flutter_steps_tracker/app/home/shop/shop_screen.dart';
import 'package:flutter_steps_tracker/utils/colors.dart';
import 'package:flutter_steps_tracker/app/home/devices/devices_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.menuScreenContext});
  final BuildContext menuScreenContext;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      StepsCounterScreen(
        menuScreenContext: widget.menuScreenContext,
      ),
      ShopScreen(
        menuScreenContext: widget.menuScreenContext,
      ),
      ProfileScreen(
        menuScreenContext: widget.menuScreenContext,
      ),
      DevicesScreen(
        menuScreenContext: widget.menuScreenContext,
      ),

    ]);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedIndex: _selectedIndex,
          backgroundColor: Colors.black,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.directions_run),
              label: "Шагомер",
            ),
            NavigationDestination(
              icon: Icon(Icons.shop),
              label: "Магазин",
            ),
            NavigationDestination(
              icon: Icon(Icons.watch),
              label: "Устройства",
            ),
            NavigationDestination(
              icon: Icon(Icons.person),
              label: "Профиль",
            ),
          ],
        ),
      ),
    );
  }
}