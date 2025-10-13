import 'package:caldensmartfabrica/aws/mqtt/mqtt.dart';
import 'package:caldensmartfabrica/global/registro.dart';
import 'package:caldensmartfabrica/global/scan.dart';
import 'package:caldensmartfabrica/global/toolsaws.dart';
import 'package:caldensmartfabrica/global/parametersaws.dart';
import 'package:caldensmartfabrica/global/wifi_tester.dart';
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
      appBar: AppBar(
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Calden Smart Fábrica',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color4,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color1,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              color: color4,
              size: 35,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: color1,
                    titlePadding: const EdgeInsets.all(16),
                    contentPadding: const EdgeInsets.all(16),
                    title: Column(
                      children: [
                        const Text(
                          "Información del Usuario",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: color4,
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          child: EasterEggs.profile(legajoConectado),
                        ),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contenedor para Legajo
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  "Legajo:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: color4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    legajoConectado,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: color4,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Contenedor para Nombre
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  "Nombre:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: color4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    completeName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: color4,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Contenedor para Nivel de acceso
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  "Nivel de acceso:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: color4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  accessLevel.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: color4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    actionsPadding: const EdgeInsets.only(bottom: 16, top: 8),
                    actions: <Widget>[
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: color3, width: 1),
                            ),
                            elevation: 5,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: () {
                            String cuerpo =
                                'Solicito que se modifique el nivel de acceso en la app de fabrica para el legajo $legajoConectado\nNivel de acceso actual: $accessLevel\nNivel solicitado: ';
                            launchEmail('ingenieria@caldensmart.com',
                                'Solicitud cambio de nivel de acceso', cuerpo);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.lock_open,
                              size: 20, color: color4),
                          label: const Text(
                            "Solicitar cambio de nivel",
                            style: TextStyle(color: color4, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              const ScanPage(),
              if (accessLevel >= 2) const ToolsAWS(),
              if (accessLevel >= 2) const ParametersAWS(),
              if (accessLevel >= 3) const RegistroScreen(),
              if (accessLevel >= 2) const WifiTestScreen(),
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
                if (accessLevel >= 2) ...[
                  const Icon(Icons.webhook_outlined, color: color4),
                ],
                if (accessLevel >= 2) ...[
                  const Icon(Icons.settings, color: color4),
                ],
                if (accessLevel >= 3) ...[
                  const Icon(Icons.assignment, color: color4),
                ],
                if (accessLevel >= 2) ...[
                  const Icon(Icons.wifi, color: color4),
                ],
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
