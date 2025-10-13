import 'dart:async';
import 'dart:convert';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/loggerble.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/resmon.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../master.dart';

class ModuloPage extends StatefulWidget {
  const ModuloPage({super.key});

  @override
  ModuloPageState createState() => ModuloPageState();
}

class ModuloPageState extends State<ModuloPage> {
  TextEditingController textController = TextEditingController();
  final PageController _pageController = PageController(initialPage: 0);
  bool testingIN = false;
  bool testingOUT = false;
  List<bool> stateIN = List<bool>.filled(4, false, growable: false);
  List<bool> stateOUT = List<bool>.filled(2, false, growable: false);

  int _selectedIndex = 0;

  // Obtener el índice correcto para cada página
  int _getPageIndex(String pageType) {
    int index = 0;

    // Tools page (siempre presente)
    if (pageType == 'tools') return index;
    index++;

    // Params page (solo si accessLevel > 1)
    if (accessLevel > 1) {
      if (pageType == 'params') return index;
      index++;
    }

    // Control page (siempre presente)
    if (pageType == 'control') return index;
    index++;

    // Burneo page y Creds page (solo si accessLevel > 1)
    if (accessLevel > 1) {
      if (pageType == 'burneo') return index; // página de burneo/control
      index++;

      if (pageType == 'creds') return index; // página de credenciales
      index++;
    }

    // Logger BLE page (si disponible)
    if (bluetoothManager.hasLoggerBle) {
      if (pageType == 'logger') return index;
      index++;
    }

    // Resource Monitor page (si disponible)
    if (bluetoothManager.hasResourceMonitor) {
      if (pageType == 'monitor') return index;
      index++;
    }

    // OTA page (siempre presente)
    if (pageType == 'ota') return index;

    return 0; // fallback
  }

  void _showCompleteMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: color1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Permite controlar el tamaño del BottomSheet
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.8, // Máximo 80% de la pantalla
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Menú de navegación',
                  style: TextStyle(
                    color: color4,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Tools page (siempre disponible)
                ListTile(
                  leading: const Icon(Icons.settings, color: color4),
                  title: const Text('Herramientas',
                      style: TextStyle(color: color4)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTab(_getPageIndex('tools'));
                  },
                ),
                // Params page (solo si accessLevel > 1)
                if (accessLevel > 1)
                  ListTile(
                    leading: const Icon(Icons.star, color: color4),
                    title: const Text('Parámetros',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('params'));
                    },
                  ),
                // Control page (siempre disponible)
                ListTile(
                  leading: const Icon(Icons.thermostat, color: color4),
                  title: const Text('Control', style: TextStyle(color: color4)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTab(_getPageIndex('control'));
                  },
                ),
                // Burneo page (solo si accessLevel > 1)
                if (accessLevel > 1)
                  ListTile(
                    leading: const Icon(Icons.build, color: color4),
                    title:
                        const Text('Burneo', style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('burneo'));
                    },
                  ),
                // Creds page (solo si accessLevel > 1)
                if (accessLevel > 1)
                  ListTile(
                    leading: const Icon(Icons.person, color: color4),
                    title: const Text('Credenciales',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('creds'));
                    },
                  ),
                // Logger BLE page (si disponible)
                if (bluetoothManager.hasLoggerBle)
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: color4),
                    title: const Text('Logger BLE',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('logger'));
                    },
                  ),
                // Resource Monitor page (si disponible)
                if (bluetoothManager.hasResourceMonitor)
                  ListTile(
                    leading: const Icon(Icons.monitor, color: color4),
                    title: const Text('Resource Monitor',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('monitor'));
                    },
                  ),
                // OTA page (siempre disponible)
                ListTile(
                  leading: const Icon(Icons.send, color: color4),
                  title: const Text('OTA', style: TextStyle(color: color4)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTab(_getPageIndex('ota'));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Navegar a una pestaña específica
  void _navigateToTab(int targetIndex) {
    printLog('=== NAVIGATING TO TAB: $targetIndex ===');
    if ((targetIndex - _selectedIndex).abs() > 1) {
      _pageController.jumpToPage(targetIndex);
    } else {
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _selectedIndex = targetIndex;
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
    subToIO();
    processValues(ioValues);
  }

  void updateWifiValues(List<int> data) {
    var fun =
        utf8.decode(data); //Wifi status | wifi ssid | ble status | nickname
    fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    // printLog(fun);
    var parts = fun.split(':');
    if (parts[0] == 'WCS_CONNECTED') {
      nameOfWifi = parts[1];
      isWifiConnected = true;
      // printLog('sis $isWifiConnected');
      setState(() {
        textState = 'CONECTADO';
        statusColor = Colors.green;
        wifiIcon = Icons.wifi;
      });
    } else if (parts[0] == 'WCS_DISCONNECTED') {
      isWifiConnected = false;
      // printLog('non $isWifiConnected');

      setState(() {
        textState = 'DESCONECTADO';
        statusColor = Colors.red;
        wifiIcon = Icons.wifi_off;
      });

      if (parts[0] == 'WCS_DISCONNECTED' && atemp == true) {
        //If comes from subscription, parts[1] = reason of error.
        setState(() {
          wifiIcon = Icons.warning_amber_rounded;
          werror = true;
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
    await bluetoothManager.toolsUuid.setNotifyValue(true);

    final wifiSub =
        bluetoothManager.toolsUuid.onValueReceived.listen((List<int> status) {
      updateWifiValues(status);
    });

    bluetoothManager.device.cancelWhenDisconnected(wifiSub);
  }

  void processValues(List<int> values) {
    ioValues = values;
    var parts = utf8.decode(values).split('/');
    printLog('Valores: $parts', "Amarillo");
    tipo.clear();
    estado.clear();
    common.clear();
    alertIO.clear();

    for (int i = 0; i < 2; i++) {
      tipo.add('Salida');
      estado.add(parts[i]);
      common.add('0');
      alertIO.add(false);
    }

    for (int j = 2; j < 4; j++) {
      var equipo = parts[j].split(':');
      tipo.add('Entrada');
      estado.add(equipo[0]);
      common.add(equipo[1]);
      alertIO.add(estado[j] != common[j]);

      printLog('¿La entrada$j esta en alerta?: ${alertIO[j]}');
    }
    setState(() {});
  }

  void subToIO() async {
    if (!alreadySubIO) {
      await bluetoothManager.ioUuid.setNotifyValue(true);
      printLog('Subscrito a IO');
      alreadySubIO = true;
    }

    var ioSub = bluetoothManager.ioUuid.onValueReceived.listen((event) {
      printLog('Cambio en IO');
      processValues(event);
    });

    bluetoothManager.device.cancelWhenDisconnected(ioSub);
  }

  void mandarBurneo() async {
    printLog('mande a la google sheet');

    const String url =
        'https://script.google.com/macros/s/AKfycbyESEF-o_iBAotpLi7gszSfelJVLlJbrgSVSiMYWYaHfC8io5fJ2tlAKkGpH7iJYK3p0Q/exec';

    final Map<String, dynamic> queryParams = {
      'productCode': DeviceManager.getProductCode(deviceName),
      'serialNumber': DeviceManager.extractSerialNumber(deviceName),
      'Legajo': legajoConectado,
      'in0': stateIN[0],
      'in1': stateIN[1],
      'out0': stateOUT[0],
      'out1': stateOUT[1],
      'date': DateTime.now().toIso8601String()
    };

    final Uri uri = Uri.parse(url).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      printLog('Anashe');
    } else {
      printLog('!=200 ${response.statusCode}');
    }
  }

  //! VISUAL
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double bottomBarHeight = kBottomNavigationBarHeight;

    final List<Widget> pages = [
      //*- Página 1 TOOLS -*\\
      const ToolsPage(),
      if (accessLevel > 1) ...[
        //*- Página 2 PARAMS -*\\
        const ParamsTab(),
      ],

      //*- Página 3 SET -*\\
      Scaffold(
        backgroundColor: color4,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 2; i++) ...{
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: color0,
                      borderRadius: BorderRadius.circular(20),
                      border: const Border(
                        bottom: BorderSide(color: color1, width: 5),
                        right: BorderSide(color: color1, width: 5),
                        left: BorderSide(color: color1, width: 5),
                        top: BorderSide(color: color1, width: 5),
                      ),
                    ),
                    width: width - 50,
                    height: 250,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tipo[i],
                          style: const TextStyle(
                            color: color4,
                            fontWeight: FontWeight.bold,
                            fontSize: 50,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Transform.scale(
                          scale: 2.0,
                          child: Switch(
                            activeThumbColor: color4,
                            activeTrackColor: color1,
                            inactiveThumbColor: color1,
                            inactiveTrackColor: color4,
                            value: estado[i] == '1',
                            onChanged: (value) async {
                              String fun = '$i#${value ? '1' : '0'}';
                              await bluetoothManager.ioUuid
                                  .write(fun.codeUnits);
                            },
                          ),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.only(bottom: bottomBarHeight + 20),
                        ),
                      ],
                    ),
                  ),
                },
                for (int j = 2; j < 4; j++) ...{
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: color0,
                      borderRadius: BorderRadius.circular(20),
                      border: const Border(
                        bottom: BorderSide(color: color1, width: 5),
                        right: BorderSide(color: color1, width: 5),
                        left: BorderSide(color: color1, width: 5),
                        top: BorderSide(color: color1, width: 5),
                      ),
                    ),
                    width: width - 50,
                    height: 275,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tipo[j],
                          style: const TextStyle(
                            color: color4,
                            fontWeight: FontWeight.bold,
                            fontSize: 50,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        alertIO[j]
                            ? const Icon(
                                Icons.new_releases,
                                color: Color(0xffcb3234),
                                size: 50,
                              )
                            : const Icon(
                                Icons.new_releases,
                                color: color4,
                                size: 50,
                              ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 30,
                            ),
                            const Text(
                              'Estado común:',
                              style: TextStyle(
                                color: color4,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: ChoiceChip(
                                label: const Text('0'),
                                selected: common[j] == '0',
                                shape: const OvalBorder(),
                                pressElevation: 5,
                                showCheckmark: false,
                                selectedColor: color2,
                                onSelected: (value) {
                                  setState(() {
                                    common[j] = '0';
                                  });
                                  String data =
                                      '${DeviceManager.getProductCode(deviceName)}[14]($j#${common[j]})';
                                  printLog(data);
                                  bluetoothManager.toolsUuid
                                      .write(data.codeUnits);
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: ChoiceChip(
                                label: const Text('1'),
                                labelStyle: const TextStyle(
                                  color: color1,
                                ),
                                selected: common[j] == '1',
                                shape: const OvalBorder(),
                                pressElevation: 5,
                                showCheckmark: false,
                                selectedColor: color2,
                                onSelected: (value) {
                                  setState(() {
                                    common[j] = '1';
                                  });
                                  String data =
                                      '${DeviceManager.getProductCode(deviceName)}[14]($j#${common[j]})';
                                  printLog(data);
                                  bluetoothManager.toolsUuid
                                      .write(data.codeUnits);
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                },
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: bottomBarHeight + 30),
                ),
              ],
            ),
          ),
        ),
      ),
      if (accessLevel > 1) ...[
        //*- Página 4 CONTROL -*\\
        Scaffold(
          backgroundColor: color4,
          body: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  const SizedBox(
                    height: 200,
                  ),
                  buildText(
                    text: '',
                    textSpans: [
                      const TextSpan(
                        text: '¿Burneo realizado?\n',
                        style: TextStyle(
                            color: color4, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: burneoDone ? 'SI' : 'NO',
                        style: TextStyle(
                          color: burneoDone ? color4 : const Color(0xffFF0000),
                        ),
                      ),
                    ],
                    fontSize: 20.0,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  buildButton(
                    text: 'Probar entradas',
                    onPressed: () {
                      registerActivity(
                        DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName),
                        'Se envio el testeo de entradas',
                      );
                      setState(() {
                        testingIN = true;
                      });
                    },
                  ),
                  if (testingIN) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    for (int i = 2; i < 4; i++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Funcionamiento Entrada $i: ',
                            style: const TextStyle(
                              fontSize: 15.0,
                              color: color0,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Switch(
                            activeThumbColor: color4,
                            activeTrackColor: color1,
                            inactiveThumbColor: color1,
                            inactiveTrackColor: color4,
                            trackOutlineColor:
                                const WidgetStatePropertyAll(color1),
                            thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return const Icon(Icons.check, color: color1);
                                } else {
                                  return const Icon(Icons.close, color: color4);
                                }
                              },
                            ),
                            value: stateIN[i],
                            onChanged: (value) {
                              setState(() {
                                stateIN[i] = value;
                              });
                              printLog(stateIN);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(
                    height: 10,
                  ),
                  buildButton(
                    text: 'Probar salidas',
                    onPressed: () {
                      if (testingIN) {
                        registerActivity(
                            DeviceManager.getProductCode(deviceName),
                            DeviceManager.extractSerialNumber(deviceName),
                            'Se envio el testeo de salidas');
                        String fun1 =
                            '${DeviceManager.getProductCode(deviceName)}[15](0)';
                        bluetoothManager.toolsUuid.write(fun1.codeUnits);
                        setState(() {
                          testingOUT = true;
                        });
                      } else {
                        showToast('Primero probar entradas');
                      }
                    },
                  ),
                  if (testingOUT) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    for (int i = 0; i < 2; i++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Funcionamiento Salida $i: ',
                            style: const TextStyle(
                              fontSize: 15.0,
                              color: color0,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Switch(
                            activeThumbColor: color4,
                            activeTrackColor: color1,
                            inactiveThumbColor: color1,
                            inactiveTrackColor: color4,
                            trackOutlineColor:
                                const WidgetStatePropertyAll(color1),
                            thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return const Icon(Icons.check, color: color1);
                                } else {
                                  return const Icon(Icons.close, color: color4);
                                }
                              },
                            ),
                            value: stateOUT[i],
                            onChanged: (value) {
                              setState(() {
                                stateOUT[i] = value;
                              });
                              printLog(stateOUT);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(
                    height: 10,
                  ),
                  buildButton(
                    text: 'Enviar burneo',
                    onPressed: () {
                      if (testingIN && testingOUT) {
                        registerActivity(
                          DeviceManager.getProductCode(deviceName),
                          DeviceManager.extractSerialNumber(deviceName),
                          'Se envio el burneo',
                        );
                        printLog('Se envío burneo');
                        mandarBurneo();
                        String fun2 =
                            '${DeviceManager.getProductCode(deviceName)}[15](1)';
                        bluetoothManager.toolsUuid.write(fun2.codeUnits);
                      } else {
                        showToast('Primero probar entradas y salidas');
                      }
                    },
                  ),
                  const SizedBox(
                    height: 200,
                  ),
                ],
              ),
            ),
          ),
        ),

        //*- Página 5 CREDENTIAL -*\\
        const CredsTab(),
      ],

      if (bluetoothManager.hasLoggerBle) ...[
        //*- Página LOGGER -*\\
        const LoggerBlePage(),
      ],

      if (bluetoothManager.hasResourceMonitor) ...[
        //*- Página RESOURCE MONITOR -*\\
        const ResourceMonitorPage(),
      ],

      //*- Página 6 OTA -*\\
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
                  Image.asset(
                      EasterEggs.legajosMeme.contains(legajoConectado)
                          ? 'assets/eg/DSC.gif'
                          : 'assets/Loading.gif',
                      width: 100,
                      height: 100),
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
          await bluetoothManager.device.disconnect();
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
                        Image.asset(
                            EasterEggs.legajosMeme.contains(legajoConectado)
                                ? 'assets/eg/DSC.gif'
                                : 'assets/Loading.gif',
                            width: 100,
                            height: 100),
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
                await bluetoothManager.device.disconnect();
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
          alignment: AlignmentDirectional.center,
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
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: _showCompleteMenu,
                backgroundColor: color2,
                child: const Icon(Icons.menu, color: color4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
