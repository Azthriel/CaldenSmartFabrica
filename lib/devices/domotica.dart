import 'dart:async';
import 'dart:convert';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/loggerble.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../master.dart';

class DomoticaPage extends StatefulWidget {
  const DomoticaPage({super.key});

  @override
  DomoticaPageState createState() => DomoticaPageState();
}

class DomoticaPageState extends State<DomoticaPage> {
  TextEditingController textController = TextEditingController();
  final PageController _pageController = PageController(initialPage: 0);

  bool testingIN = false;
  bool testingOUT = false;
  List<bool> stateIN = List<bool>.filled(8, false, growable: false);
  List<bool> stateOUT = List<bool>.filled(4, false, growable: false);

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

    if (hardwareVersion == '240422A') {
      for (int i = 0; i < parts.length; i++) {
        var equipo = parts[i].split(':');
        tipo.add(equipo[0] == '0' ? 'Salida' : 'Entrada');
        estado.add(equipo[1]);
        common.add(equipo[2]);
        alertIO.add(estado[i] != common[i]);

        printLog(
            'En la posición $i el modo es ${tipo[i]} y su estado es ${estado[i]}');
        printLog('Su posición de reposo es ${common[i]}');
        printLog('¿Esta en alerta?: ${alertIO[i]}');
      }
      setState(() {});
    } else {
      for (int i = 0; i < 4; i++) {
        tipo.add('Salida');
        estado.add(parts[i]);
        common.add('0');
        alertIO.add(false);
      }

      for (int j = 4; j < 8; j++) {
        var equipo = parts[j].split(':');
        tipo.add('Entrada');
        estado.add(equipo[0]);
        common.add(equipo[1]);
        alertIO.add(estado[j] != common[j]);

        printLog('¿La entrada $j esta en alerta?: ${alertIO[j]}');
      }

      setState(() {});
    }
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
      'in2': stateIN[2],
      'in3': stateIN[3],
      'out0': stateOUT[0],
      'out1': stateOUT[1],
      'out2': stateOUT[2],
      'out3': stateOUT[3],
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
    var parts = utf8.decode(ioValues).split('/');
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
        body: ListView.builder(
          itemCount: parts.length,
          itemBuilder: (context, int index) {
            bool entrada = tipo[index] == 'Entrada';
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  height: entrada ? 275 : 250,
                  child: Column(
                    children: [
                      Text(
                        tipo[index],
                        style: const TextStyle(
                            color: color4,
                            fontWeight: FontWeight.bold,
                            fontSize: 50),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      entrada
                          ? alertIO[index]
                              ? const Icon(
                                  Icons.new_releases,
                                  color: Color(0xffcb3234),
                                  size: 50,
                                )
                              : const Icon(
                                  Icons.new_releases,
                                  color: color4,
                                  size: 50,
                                )
                          : Switch(
                              activeColor: color4,
                              activeTrackColor: color1,
                              inactiveThumbColor: color1,
                              inactiveTrackColor: color4,
                              value: estado[index] == '1',
                              onChanged: (value) async {
                                String fun = '$index#${value ? '1' : '0'}';
                                await bluetoothManager.ioUuid
                                    .write(fun.codeUnits);
                              },
                            ),
                      const SizedBox(
                        height: 10,
                      ),
                      entrada
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 30,
                                ),
                                const Text(
                                  'Estado común:',
                                  style: TextStyle(
                                      color: Color(0xfffbe4d8), fontSize: 15),
                                ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: ChoiceChip(
                                    label: const Text('0'),
                                    selected: common[index] == '0',
                                    shape: const OvalBorder(),
                                    pressElevation: 5,
                                    showCheckmark: false,
                                    selectedColor: const Color(0xfffbe4d8),
                                    onSelected: (value) {
                                      common[index] = '0';
                                      String data =
                                          '${DeviceManager.getProductCode(deviceName)}[14]($index#${common[index]})';
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: ChoiceChip(
                                    label: const Text('1'),
                                    labelStyle: const TextStyle(color: color1),
                                    selected: common[index] == '1',
                                    shape: const OvalBorder(),
                                    pressElevation: 5,
                                    showCheckmark: false,
                                    selectedColor: color4,
                                    onSelected: (value) {
                                      common[index] = '1';
                                      String data =
                                          '${DeviceManager.getProductCode(deviceName)}[14]($index#${common[index]})';
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
                          : const SizedBox(
                              height: 10,
                            ),
                      const SizedBox(
                        height: 5,
                      ),
                      if (hardwareVersion == '240422A') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 30,
                            ),
                            const Text(
                              '¿Cambiar de modo?',
                              style: TextStyle(color: color4, fontSize: 15),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      backgroundColor: color0,
                                      content: Text(
                                        '¿Cambiar de ${tipo[index]} a ${entrada ? 'Salida' : 'Entrada'}?',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: color4,
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dialogContext).pop(),
                                          child: const Text(
                                            'Cancelar',
                                            style: TextStyle(color: color4),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            String fun =
                                                '${DeviceManager.getProductCode(deviceName)}[13]($index#${entrada ? '0' : '1'})';
                                            printLog(fun);
                                            bluetoothManager.toolsUuid
                                                .write(fun.codeUnits);
                                            Navigator.of(dialogContext).pop();
                                          },
                                          child: const Text(
                                            'Cambiar',
                                            style: TextStyle(color: color4),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.change_circle_outlined,
                                color: color4,
                                size: 30,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                if (index == parts.length - 1)
                  Padding(
                    padding: EdgeInsets.only(bottom: bottomBarHeight + 30),
                  ),
              ],
            );
          },
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
                          'Se envio el testeo de entradas');
                      for (int index = 0; index < 4; index++) {
                        String fun =
                            '${DeviceManager.getProductCode(deviceName)}[13]($index#1)';
                        bluetoothManager.toolsUuid.write(fun.codeUnits);
                      }
                      printLog('Ya se cambiaron todos los pines a entrada');
                      setState(() {
                        testingIN = true;
                      });
                    },
                  ),
                  if (testingIN) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    for (int i = 0; i < 4; i++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Funcionamiento Entrada $i: ',
                              style: const TextStyle(
                                  fontSize: 15.0,
                                  color: color0,
                                  fontWeight: FontWeight.normal)),
                          Switch(
                            activeColor: color4,
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
                        for (int index = 0; index < 4; index++) {
                          String fun =
                              '${DeviceManager.getProductCode(deviceName)}[13]($index#0)';
                          bluetoothManager.toolsUuid.write(fun.codeUnits);
                        }
                        printLog('Ya se cambiaron todos los pines a salida');
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
                    for (int i = 0; i < 4; i++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Funcionamiento Salida $i: ',
                            style: const TextStyle(
                                fontSize: 15.0,
                                color: color0,
                                fontWeight: FontWeight.normal),
                          ),
                          Switch(
                            activeColor: color4,
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
                            'Se envio el burneo');
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

      if (hasLoggerBle) ...[
        //*- Página LOGGER -*\\
        const LoggerBlePage(),
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
                items: <Widget>[
                  const Icon(Icons.settings, size: 30, color: color4),
                  if (accessLevel > 1) ...[
                    const Icon(Icons.star, size: 30, color: color4),
                    const Icon(Icons.settings_accessibility,
                        size: 30, color: color4),
                    const Icon(Icons.pending_actions_rounded,
                        size: 30, color: color4),
                    const Icon(Icons.person, size: 30, color: color4),
                    if (hasLoggerBle) ...[
                      const Icon(Icons.receipt_long, size: 30, color: color4),
                    ],
                    const Icon(Icons.send, size: 30, color: color4),
                  ] else ...[
                    const Icon(Icons.settings_accessibility,
                        size: 30, color: color4),
                    const Icon(Icons.send, size: 30, color: color4),
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
      ),
    );
  }
}
