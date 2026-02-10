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

class DomoticaPage extends StatefulWidget {
  const DomoticaPage({super.key});

  @override
  DomoticaPageState createState() => DomoticaPageState();
}

class DomoticaPageState extends State<DomoticaPage> {
  TextEditingController textController = TextEditingController();
  final PageController _pageController = PageController(initialPage: 0);

  bool varsLoaded = false;

  bool testingIN = false;
  bool testingOUT = false;
  List<bool> stateIN = List<bool>.filled(8, false, growable: false);
  List<bool> stateOUT = List<bool>.filled(4, false, growable: false);

  int _selectedIndex = 0;

  final bool canControl = (accessLevel >= 3 || owner == '');
  final List<String> _pulse_mode = [];
  final List<String> _pulse_mode_timers = [];
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

      if (pageType == 'variables') return index; // página de variables
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
                if (accessLevel > 1)
                  ListTile(
                    leading: const Icon(Icons.tune, color: color4),
                    title: const Text('Variables',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('variables'));
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
    processVarsValues(varsValues);
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

  void processVarsValues(List<int> values) {
    try {
      varsValues = values;
      var fun = utf8.decode(values);
      fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
      var parts = fun.split(':');
      printLog('Vars Valores: $parts', "Amarillo");

      if (parts.length < 11) {
        printLog('Error: Lectura de vars incompleta. Se bloquean ediciones.');
        setState(() {
          varsLoaded = false;
        });
        return;
      }

      awsInit = parts[1] == '1';
      burneoDone = parts[2] == '1';

      _pulse_mode.clear();
      _pulse_mode_timers.clear();

      _pulse_mode.addAll([parts[3], parts[4], parts[5], parts[6]]);
      _pulse_mode_timers.addAll([parts[7], parts[8], parts[9], parts[10]]);

      setState(() {
        varsLoaded = true;
      });
    } catch (e) {
      printLog('Error crítico procesando vars: $e');
      setState(() {
        varsLoaded = false;
      });
    }
  }

  void sendDeviceBehaviour(String pin, bool isSwitch) {
    String pc = DeviceManager.getProductCode(deviceName);
    String serialNumber = DeviceManager.extractSerialNumber(deviceName);
    String msg = '$pc[16]($pin#${isSwitch ? '0' : '1'})';
    printLog('Se volvio el pin $pin a ${isSwitch ? 'SWITCH' : 'PULSE'}');
    bluetoothManager.toolsUuid.write(msg.codeUnits);
    registerActivity(pc, serialNumber,
        'Cambio de comportamiento del pin $pin a ${isSwitch ? 'SWITCH' : 'PULSE'}');
  }

  void sendPulseTimer(String pin, String timer) {
    String pc = DeviceManager.getProductCode(deviceName);
    String serialNumber = DeviceManager.extractSerialNumber(deviceName);
    String msg = '$pc[17]($pin#$timer)';
    printLog('Se cambio el tiempo de pulso del pin $pin a $timer milisegundos');
    bluetoothManager.toolsUuid.write(msg.codeUnits);
    registerActivity(pc, serialNumber,
        'Cambio del tiempo de pulso del pin $pin a $timer milisegundos');
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
                          : canControl
                              ? Switch(
                                  activeThumbColor: color4,
                                  activeTrackColor: color1,
                                  inactiveThumbColor: color1,
                                  inactiveTrackColor: color4,
                                  value: estado[index] == '1',
                                  onChanged: (value) async {
                                    String fun = '$index#${value ? '1' : '0'}';
                                    await bluetoothManager.ioUuid
                                        .write(fun.codeUnits);
                                  },
                                )
                              : const SizedBox.shrink(),
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
                      if (hardwareVersion == '240422A' && canControl) ...[
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

        //*- Página 5 VARIABLES -*\\
        Scaffold(
          backgroundColor: color4,
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                color: color4,
                child: Column(
                  children: [
                    const Text(
                      "Configuración de Salidas",
                      style: TextStyle(
                        color: color0,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      varsLoaded
                          ? "Selecciona comportamiento (Switch/Pulso) y duración"
                          : "⚠ Opciones no disponibles para el equipo",
                      style: TextStyle(
                        color: varsLoaded
                            ? color0.withValues(alpha: 0.7)
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 4,
                  padding: const EdgeInsets.only(top: 10, bottom: 100),
                  itemBuilder: (context, index) {
                    if (index >= _pulse_mode.length) {
                      return const SizedBox.shrink();
                    }

                    bool isPulse = _pulse_mode[index] == '1';

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: color0,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: color1, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Salida $index",
                                style: const TextStyle(
                                  color: color4,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: !varsLoaded
                                    ? null
                                    : () {
                                        setState(
                                            () => _pulse_mode[index] = '0');
                                        sendDeviceBehaviour(
                                            index.toString(), true);
                                      },
                                child: Opacity(
                                  opacity: varsLoaded ? 1.0 : 0.5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: !isPulse
                                          ? color4
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: color4),
                                    ),
                                    child: Text(
                                      "Switch",
                                      style: TextStyle(
                                          color: !isPulse ? color1 : color4,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: !varsLoaded
                                    ? null
                                    : () {
                                        setState(
                                            () => _pulse_mode[index] = '1');
                                        sendDeviceBehaviour(
                                            index.toString(), false);
                                      },
                                child: Opacity(
                                  opacity: varsLoaded ? 1.0 : 0.5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          isPulse ? color4 : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: color4),
                                    ),
                                    child: Text(
                                      "Pulse",
                                      style: TextStyle(
                                          color: isPulse ? color1 : color4,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isPulse) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: color1.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Icon(Icons.timer,
                                      color: color4, size: 18),
                                  const SizedBox(width: 8),
                                  const Text("Duración:",
                                      style: TextStyle(
                                          color: color4, fontSize: 14)),
                                  const Spacer(),
                                  Text(
                                    _pulse_mode_timers.length > index
                                        ? '${_pulse_mode_timers[index]} ms'
                                        : '---',
                                    style: const TextStyle(
                                        color: color4,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 5),
                                  InkWell(
                                    onTap: !varsLoaded
                                        ? null
                                        : () {
                                            TextEditingController timeCtrl =
                                                TextEditingController();
                                            if (_pulse_mode_timers.length >
                                                index) {
                                              timeCtrl.text =
                                                  _pulse_mode_timers[index];
                                            }
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: color0,
                                                title: const Text("Tiempo (ms)",
                                                    style: TextStyle(
                                                        color: color4)),
                                                content: TextField(
                                                  controller: timeCtrl,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  style: const TextStyle(
                                                      color: color4),
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText: "Ej: 500",
                                                    hintStyle: TextStyle(
                                                        color: Colors.white30),
                                                    enabledBorder:
                                                        UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    color:
                                                                        color4)),
                                                    focusedBorder:
                                                        UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                    color:
                                                                        color4,
                                                                    width: 2)),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: const Text(
                                                        "Cancelar",
                                                        style: TextStyle(
                                                            color: color4)),
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                  ),
                                                  TextButton(
                                                    child: const Text("Guardar",
                                                        style: TextStyle(
                                                            color: color4,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    onPressed: () {
                                                      if (timeCtrl
                                                          .text.isNotEmpty) {
                                                        sendPulseTimer(
                                                            index.toString(),
                                                            timeCtrl.text);
                                                        setState(() {
                                                          _pulse_mode_timers[
                                                                  index] =
                                                              timeCtrl.text;
                                                        });
                                                      }
                                                      Navigator.pop(ctx);
                                                    },
                                                  )
                                                ],
                                              ),
                                            );
                                          },
                                    child: Icon(Icons.edit,
                                        color: varsLoaded
                                            ? color4
                                            : color4.withValues(alpha: 0.3),
                                        size: 20),
                                  )
                                ],
                              ),
                            )
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        //*- Página 6 CREDENTIAL -*\\
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
          title: Text(
            deviceName,
            style: const TextStyle(
              color: color4,
            ),
            overflow: TextOverflow.ellipsis,
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
