import 'dart:async';
import 'dart:convert';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:flutter/material.dart';
import '../master.dart';

class DomoticaPage extends StatefulWidget {
  const DomoticaPage({super.key});

  @override
  DomoticaPageState createState() => DomoticaPageState();
}

class DomoticaPageState extends State<DomoticaPage> {
  TextEditingController textController = TextEditingController();
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
    textController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
  }

  void updateWifiValues(List<int> data) {
    var fun =
        utf8.decode(data); //Wifi status | wifi ssid | ble status | nickname
    fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    printLog(fun);
    var parts = fun.split(':');
    if (parts[0] == 'WCS_CONNECTED') {
      nameOfWifi = parts[1];
      isWifiConnected = true;
      printLog('sis $isWifiConnected');
      setState(() {
        textState = 'CONECTADO';
        statusColor = Colors.green;
        wifiIcon = Icons.wifi;
      });
    } else if (parts[0] == 'WCS_DISCONNECTED') {
      isWifiConnected = false;
      printLog('non $isWifiConnected');

      setState(() {
        textState = 'DESCONECTADO';
        statusColor = Colors.red;
        wifiIcon = Icons.wifi_off;
      });

      if (parts[0] == 'WCS_DISCONNECTED' && atemp == true) {
        //If comes from subscription, parts[1] = reason of error.
        setState(() {
          wifiIcon = Icons.warning_amber_rounded;
        });

        if (parts[1] == '202' || parts[1] == '15') {
          errorMessage = 'Contraseña incorrecta';
        } else if (parts[1] == '201') {
          errorMessage = 'La red especificada no existe';
        } else if (parts[1] == '1') {
          errorMessage = 'Error desconocido';
        } else {
          errorMessage = parts[1];
        }

        if (int.tryParse(parts[1]) != null) {
          errorSintax = getWifiErrorSintax(int.parse(parts[1]));
        }
      }
    }

    setState(() {});
  }

  void subscribeToWifiStatus() async {
    printLog('Se subscribio a wifi');
    await myDevice.toolsUuid.setNotifyValue(true);

    final wifiSub =
        myDevice.toolsUuid.onValueReceived.listen((List<int> status) {
      updateWifiValues(status);
    });

    myDevice.device.cancelWhenDisconnected(wifiSub);
  }

  //! VISUAL
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      //*- Página 1 TOOLS -*\\
      const ToolsPage(),

      //*- Página 2 PARAMS -*\\
      const ParamsTab(),

      //TODO: Cambiar diseño
      //*- Página 3 CONTROL -*\\

      //*- Página 4 CREDENTIAL -*\\
      const CredsTab(),

      //*- Página 5 OTA -*\\
      const OtaTab(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, A) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: color1,
              content: Row(
                children: [
                  Image.asset('assets/Loading.gif', width: 100, height: 100),
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    child: const Text(
                      "Desconectando...",
                      style: TextStyle(color: color4),
                    ),
                  ),
                ],
              ),
            );
          },
        );
        Future.delayed(const Duration(seconds: 2), () async {
          await myDevice.device.disconnect();
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/menu');
          }
        });
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: color1,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                deviceName,
                style: const TextStyle(color: color4),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: color4,
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: color1,
                    content: Row(
                      children: [
                        Image.asset('assets/Loading.gif',
                            width: 100, height: 100),
                        Container(
                          margin: const EdgeInsets.only(left: 15),
                          child: const Text(
                            "Desconectando...",
                            style: TextStyle(color: color4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
              Future.delayed(const Duration(seconds: 2), () async {
                await myDevice.device.disconnect();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/menu');
                }
              });
              return;
            },
          ),
          actions: [
            IconButton(
              icon: Icon(wifiIcon, color: color4),
              onPressed: () {
                wifiText(context);
              },
            ),
          ],
        ),
        backgroundColor: color4,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: pages,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CurvedNavigationBar(
                index: _selectedIndex,
                height: 75.0,
                items: const <Widget>[
                  Icon(Icons.settings, size: 30, color: color4),
                  Icon(Icons.star, size: 30, color: color4),
                  Icon(Icons.thermostat, size: 30, color: color4),
                  Icon(Icons.person, size: 30, color: color4),
                  Icon(Icons.send, size: 30, color: color4),
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
      ),
    );
  }
}
