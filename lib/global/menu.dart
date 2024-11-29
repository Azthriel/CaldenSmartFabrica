import 'package:caldensmartfabrica/aws/mqtt/mqtt.dart';
import 'package:caldensmartfabrica/global/scan.dart';
import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});
  @override
  State<MenuPage> createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if ((index - _selectedIndex).abs() > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    startBluetoothMonitoring();
    startLocationMonitoring();
    setupMqtt();
  }

  //!Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: color3,
      body: Stack(
        children: [
          // PageView que maneja las diferentes vistas
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              const ScanPage(),
              // if (accessLevel >= 1) const ControlTab(),
              // if (accessLevel >= 2) const ToolsAWS(),
              // if (accessLevel >= 3) const Ota2Tab(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CurvedNavigationBar(
              index: _selectedIndex,
              height: 75.0,
              items: [
                const Icon(Icons.bluetooth_searching, color: color4),
                // if (accessLevel >= 1)
                //   const Icon(Icons.assignment, color: color4),
                // if (accessLevel >= 2)
                //   const Icon(Icons.webhook_outlined, color: color4),
                // if (accessLevel >= 3) const Icon(Icons.send, color: color4),
              ],
              color: color1,
              buttonBackgroundColor: color1,
              backgroundColor: Colors.transparent,
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 600),
              onTap: (index) {
                _onItemTapped(index);
              },
              letIndexChange: (index) => true,
            ),
          ),
        ],
      ),
    );
  }
}
