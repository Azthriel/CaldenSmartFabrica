import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/loggerble.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/resmon.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../master.dart';

class PatitoPage extends StatefulWidget {
  const PatitoPage({super.key});

  @override
  PatitoPageState createState() => PatitoPageState();
}

class PatitoPageState extends State<PatitoPage> {
  TextEditingController textController = TextEditingController();
  final PageController _pageController = PageController(initialPage: 0);
  int _selectedIndex = 0;

  List<double> aceleracionX = List<double>.filled(1000, 0.0, growable: true);
  List<double> aceleracionY = List<double>.filled(1000, 0.0, growable: true);
  List<double> aceleracionZ = List<double>.filled(1000, 0.0, growable: true);
  List<double> giroX = List<double>.filled(1000, 0.0, growable: true);
  List<double> giroY = List<double>.filled(1000, 0.0, growable: true);
  List<double> giroZ = List<double>.filled(1000, 0.0, growable: true);
  List<double> sumaAcc = List<double>.filled(1000, 0.0, growable: true);
  List<double> sumaGiro = List<double>.filled(1000, 0.0, growable: true);
  List<double> promAcc = List<double>.filled(1000, 0.0, growable: true);
  List<double> promGiro = List<double>.filled(1000, 0.0, growable: true);
  List<DateTime> dates =
      List<DateTime>.filled(1000, DateTime.now(), growable: true);
  bool recording = false;
  List<List<dynamic>> recordedData = [];
  List<int> _patitoData = [];
  String _batteryPercentage = 'N/A';
  String _batterymv = '0';
  bool _isCharging = false;

  final String pc = DeviceManager.getProductCode(deviceName);
  final String sn = DeviceManager.extractSerialNumber(deviceName);
  final bool newGen = bluetoothManager.newGeneration;

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

    // Battery page (si disponible)
    if (bluetoothManager.hasBatteryService) {
      if (pageType == 'battery') return index;
      index++;
    }

    // Creds page (solo si accessLevel > 1)
    if (accessLevel > 1) {
      if (pageType == 'creds') return index;
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
                // Battery page (si disponible)
                if (bluetoothManager.hasBatteryService)
                  ListTile(
                    leading: const Icon(Icons.battery_std, color: color4),
                    title:
                        const Text('Batería', style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('battery'));
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

  void processValues() {
    if (newGen) {
      setState(() {
        addData(aceleracionX, bluetoothManager.data['acc_x'] ?? 0.0,
            windowSize: 5);
        addData(aceleracionY, bluetoothManager.data['acc_y'] ?? 0.0,
            windowSize: 5);
        addData(aceleracionZ, bluetoothManager.data['acc_z'] ?? 0.0,
            windowSize: 5);
        addData(giroX, bluetoothManager.data['gyr_x'] ?? 0.0, windowSize: 5);
        addData(giroY, bluetoothManager.data['gyr_y'] ?? 0.0, windowSize: 5);
        addData(giroZ, bluetoothManager.data['gyr_z'] ?? 0.0, windowSize: 5);
        addDate(dates, DateTime.now());

        addData(sumaAcc,
            (aceleracionX.last + aceleracionY.last + aceleracionZ.last));
        addData(promAcc,
            (aceleracionX.last + aceleracionY.last + aceleracionZ.last) / 3);
        addData(sumaGiro, (giroX.last + giroY.last + giroZ.last));
        addData(promGiro, (giroX.last + giroY.last + giroZ.last) / 3);
      });

      if (recording) {
        recordedData.add([
          DateTime.now(),
          bluetoothManager.data['acc_x'] ?? 0.0,
          bluetoothManager.data['acc_y'] ?? 0.0,
          bluetoothManager.data['acc_z'] ?? 0.0,
          bluetoothManager.data['gyr_x'] ?? 0.0,
          bluetoothManager.data['gyr_y'] ?? 0.0,
          bluetoothManager.data['gyr_z'] ?? 0.0,
          (bluetoothManager.data['acc_x'] ?? 0.0) +
              (bluetoothManager.data['acc_y'] ?? 0.0) +
              (bluetoothManager.data['acc_z'] ?? 0.0),
          ((bluetoothManager.data['acc_x'] ?? 0.0) +
                  (bluetoothManager.data['acc_y'] ?? 0.0) +
                  (bluetoothManager.data['acc_z'] ?? 0.0)) /
              3,
          (bluetoothManager.data['gyr_x'] ?? 0.0) +
              (bluetoothManager.data['gyr_y'] ?? 0.0) +
              (bluetoothManager.data['gyr_z'] ?? 0.0),
          ((bluetoothManager.data['gyr_x'] ?? 0.0) +
                  (bluetoothManager.data['gyr_y'] ?? 0.0) +
                  (bluetoothManager.data['gyr_z'] ?? 0.0)) /
              3
        ]);
      }
    } else {
      if (_patitoData.isEmpty) return;
      setState(() {
        addData(aceleracionX, transformToDouble(_patitoData.sublist(0, 4)),
            windowSize: 5);
        addData(aceleracionY, transformToDouble(_patitoData.sublist(4, 8)),
            windowSize: 5);
        addData(aceleracionZ, transformToDouble(_patitoData.sublist(8, 12)),
            windowSize: 5);
        addData(giroX, transformToDouble(_patitoData.sublist(12, 16)),
            windowSize: 5);
        addData(giroY, transformToDouble(_patitoData.sublist(16, 20)),
            windowSize: 5);
        addData(giroZ, transformToDouble(_patitoData.sublist(20)),
            windowSize: 5);
        addDate(dates, DateTime.now());

        addData(sumaAcc,
            (aceleracionX.last + aceleracionY.last + aceleracionZ.last));
        addData(promAcc,
            (aceleracionX.last + aceleracionY.last + aceleracionZ.last) / 3);
        addData(sumaGiro, (giroX.last + giroY.last + giroZ.last));
        addData(promGiro, (giroX.last + giroY.last + giroZ.last) / 3);
      });

      if (recording) {
        recordedData.add([
          DateTime.now(),
          transformToDouble(_patitoData.sublist(0, 4)),
          transformToDouble(_patitoData.sublist(4, 8)),
          transformToDouble(_patitoData.sublist(8, 12)),
          transformToDouble(_patitoData.sublist(12, 16)),
          transformToDouble(_patitoData.sublist(16, 20)),
          transformToDouble(_patitoData.sublist(20)),
          (transformToDouble(_patitoData.sublist(0, 4)) +
              transformToDouble(_patitoData.sublist(4, 8)) +
              transformToDouble(_patitoData.sublist(8, 12))),
          ((transformToDouble(_patitoData.sublist(0, 4)) +
                  transformToDouble(_patitoData.sublist(4, 8)) +
                  transformToDouble(_patitoData.sublist(8, 12))) /
              3),
          (transformToDouble(_patitoData.sublist(12, 16)) +
              transformToDouble(_patitoData.sublist(16, 20)) +
              transformToDouble(_patitoData.sublist(20))),
          ((transformToDouble(_patitoData.sublist(12, 16)) +
                  transformToDouble(_patitoData.sublist(16, 20)) +
                  transformToDouble(_patitoData.sublist(20))) /
              3)
        ]);
      }
    }

    if (bluetoothManager.hasBatteryService) {
      bluetoothManager.data.containsKey('charging')
          ? _isCharging = bluetoothManager.data['charging'] ?? false
          : null;
      bluetoothManager.data.containsKey('mv')
          ? _batterymv = (bluetoothManager.data['mv'] ?? 0).toString()
          : null;
      bluetoothManager.data.containsKey('%')
          ? _batteryPercentage = (bluetoothManager.data['%'] ?? 0).toString()
          : null;
    }
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
    processValues();
    if (newGen) {
      subToWifiData();
      subToAppData();
    } else {
      updateWifiValues(toolsValues);
      subscribeToWifiStatus();
      subToPatito();
    }

    if (bluetoothManager.hasBatteryService) {
      subToBatteryData();
      readInitialBatteryData();
    }
  }

  // OLD GEN

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

  void subToPatito() {
    bluetoothManager.patitoUuid.setNotifyValue(true);
    final patitoSub =
        bluetoothManager.patitoUuid.onValueReceived.listen((event) {
      if (context.mounted) {
        _patitoData = event;
        processValues();
      }
    });
    bluetoothManager.device.cancelWhenDisconnected(patitoSub);
  }

  // NEW GEN

  void subToWifiData() {
    final wifiSub =
        bluetoothManager.wifiDataUuid.onValueReceived.listen((List<int> data) {
      var map = deserialize(Uint8List.fromList(data));
      Map<String, dynamic> appMap = Map<String, dynamic>.from(map);
      printLog('Datos WiFi recibidos: $map');

      setState(() {
        bluetoothManager.data.addAll(appMap);
        if (appMap['wcs'] == true) {
          nameOfWifi = appMap['ssid'] ?? '';
          isWifiConnected = true;

          setState(() {
            textState = 'CONECTADO';
            statusColor = Colors.green;
            wifiIcon = Icons.wifi;
          });
        } else if (appMap['wcs'] == false) {
          isWifiConnected = false;

          setState(() {
            textState = 'DESCONECTADO';
            statusColor = Colors.red;
            wifiIcon = Icons.wifi_off;
          });

          if (appMap['wcs'] == false && atemp == true) {
            //If comes from subscription, parts[1] = reason of error.
            setState(() {
              wifiIcon = Icons.warning_amber_rounded;
              werror = true;
            });

            if (appMap['wifi_codes'] == 202 || appMap['wifi_codes'] == 15) {
              errorMessage = 'Contraseña incorrecta';
            } else if (appMap['wifi_codes'] == 201) {
              errorMessage = 'La red especificada no existe';
            } else if (appMap['wifi_codes'] == 1) {
              errorMessage = 'Error desconocido';
            } else {
              errorMessage = appMap['wifi_codes'].toString();
            }

            if (appMap['wifi_codes'] != null) {
              errorSintax = getWifiErrorSintax(appMap['wifi_codes']);
            }
          }
        }
      });
    });

    bluetoothManager.wifiDataUuid.setNotifyValue(true);

    bluetoothManager.device.cancelWhenDisconnected(wifiSub);
  }

  void subToAppData() {
    final appDataSub =
        bluetoothManager.appDataUuid.onValueReceived.listen((List<int> data) {
      var map = deserialize(Uint8List.fromList(data));
      Map<String, dynamic> appMap = Map<String, dynamic>.from(map);
      printLog('Datos App recibidos: $map');

      setState(() {
        bluetoothManager.data.addAll(appMap);
        processValues();
      });
    });

    bluetoothManager.appDataUuid.setNotifyValue(true);

    bluetoothManager.device.cancelWhenDisconnected(appDataSub);
  }

  void subToBatteryData() {
    final batteryDataSub =
        bluetoothManager.batteryUuid.onValueReceived.listen((List<int> data) {
      var map = deserialize(Uint8List.fromList(data));
      Map<String, dynamic> appMap = Map<String, dynamic>.from(map);
      printLog('Datos Batería recibidos: $map');

      setState(() {
        bluetoothManager.data.addAll(appMap);
        processValues();
      });
    });

    bluetoothManager.batteryUuid.setNotifyValue(true);

    bluetoothManager.device.cancelWhenDisconnected(batteryDataSub);
  }

  void readInitialBatteryData() async {
    try {
      List<int> data = await bluetoothManager.batteryUuid.read();
      var map = deserialize(Uint8List.fromList(data));
      Map<String, dynamic> appMap = Map<String, dynamic>.from(map);
      printLog('Datos iniciales de batería leídos: $map');

      setState(() {
        bluetoothManager.data.addAll(appMap);
        processValues();
      });
    } catch (e) {
      printLog('Error al leer datos iniciales de batería: $e');
    }
  }

  // BOTH GEN

  void addData(List<double> list, double value, {int windowSize = 5}) {
    if (list.length >= 1000) {
      list.removeAt(0);
    }
    list.add(value);
    if (list.length > windowSize) {
      list[list.length - 1] = movingAverage(list, windowSize);
    }
  }

  void addDate(List<DateTime> list, DateTime date) {
    if (list.length >= 1000) {
      list.removeAt(0);
    }
    list.add(date);
  }

  double transformToDouble(List<int> data) {
    ByteData byteData = ByteData(4);
    for (int i = 0; i < data.length; i++) {
      byteData.setInt8(i, data[i]);
    }

    double value =
        double.parse(byteData.getFloat32(0, Endian.little).toStringAsFixed(4));

    if (value < -15.0) {
      return -15.0;
    } else if (value > 15.0) {
      return 15.0;
    } else {
      return value;
    }
  }

  void saveDataToCsv() async {
    List<List<dynamic>> rows = [
      [
        "Timestamp",
        "AccX",
        "AccY",
        "AccZ",
        "GiroX",
        "GiroY",
        "GiroZ",
        "SumaAcc",
        "PromAcc",
        "SumaGiro",
        "PromGiro"
      ]
    ];
    rows.addAll(recordedData);

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFileToWrite = '${directory.path}/recorded_data.csv';
    File file = File(pathOfTheFileToWrite);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'CSV PATITO');
  }

  double movingAverage(List<double> data, int windowSize) {
    int n = data.length;
    if (n < windowSize) return data.last;
    double sum = 0.0;
    for (int i = n - windowSize; i < n; i++) {
      sum += data[i];
    }
    return sum / windowSize;
  }

  // Métodos auxiliares para la batería
  Color _getBatteryColor() {
    double percentage = double.tryParse(_batteryPercentage) ?? 0.0;
    if (percentage > 50) {
      return Colors.green;
    } else if (percentage > 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getBatteryIcon() {
    double percentage = double.tryParse(_batteryPercentage) ?? 0.0;
    if (_isCharging) {
      return Icons.battery_charging_full;
    } else if (percentage > 75) {
      return Icons.battery_full;
    } else if (percentage > 50) {
      return Icons.battery_5_bar;
    } else if (percentage > 25) {
      return Icons.battery_3_bar;
    } else if (percentage > 10) {
      return Icons.battery_2_bar;
    } else {
      return Icons.battery_1_bar;
    }
  }

  //! VISUAL
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      //*- Página 1 TOOLS -*\\
      const ToolsPage(),
      if (accessLevel > 1) ...[
        //*- Página 2 PARAMS -*\\
        const ParamsTab(),
      ],

      //*- Página 3 CONTROL -*\\
      Scaffold(
        backgroundColor: color4,
        body: SafeArea(
          child: Column(
            children: [
              // Header con botón de grabación
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: color1,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: recording
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: recording ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            recording = !recording;
                          });
                          if (!recording) {
                            saveDataToCsv();
                            recordedData.clear();
                          }
                        },
                        icon: recording
                            ? const Icon(
                                Icons.pause,
                                size: 30,
                                color: Colors.red,
                              )
                            : const Icon(
                                Icons.play_arrow,
                                size: 30,
                                color: Colors.green,
                              ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recording ? 'Grabando...' : 'Presiona para grabar',
                      style: TextStyle(
                        fontSize: 12,
                        color: color4.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de gráficos
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: [
                    const SizedBox(height: 10),
                    createChart('Aceleración X', dates, aceleracionX),
                    createChart('Giro X', dates, giroX),
                    createChart('Aceleración Y', dates, aceleracionY),
                    createChart('Giro Y', dates, giroY),
                    createChart('Aceleración Z', dates, aceleracionZ),
                    createChart('Giro Z', dates, giroZ),
                    createChart('Suma Aceleración', dates, sumaAcc),
                    createChart('Promedio Aceleración', dates, promAcc),
                    createChart('Suma Giro', dates, sumaGiro),
                    createChart('Promedio Giro', dates, promGiro),
                    SizedBox(height: bottomBarHeight + 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      if (bluetoothManager.hasBatteryService) ...[
        //*- Página BATTERY -*\\
        Scaffold(
          backgroundColor: color4,
          body: Center(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: color1,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF522B5B)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isCharging
                                  ? Icons.battery_charging_full
                                  : Icons.battery_std,
                              color: _isCharging ? Colors.green : color4,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estado de la Batería',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: color4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isCharging ? 'Cargando' : 'En uso',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: color4.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Battery Percentage Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: color1,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF522B5B),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Nivel de Carga',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: color4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_batteryPercentage%',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: color4,
                                      ),
                                    ),
                                    Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: double.tryParse(
                                                    _batteryPercentage) !=
                                                null
                                            ? (double.parse(
                                                        _batteryPercentage) /
                                                    100)
                                                .clamp(0.0, 1.0)
                                            : 0.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _getBatteryColor(),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      _getBatteryColor().withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  _getBatteryIcon(),
                                  color: _getBatteryColor(),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Battery Voltage Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: color1,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF522B5B),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Voltaje de la Batería',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: color4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_batterymv mV',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: _getBatteryColor(),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(double.tryParse(_batterymv) ?? 0) / 1000} V',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: color4.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: bottomBarHeight + 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],

      if (accessLevel > 1) ...[
        //*- Página 4 CREDENTIAL -*\\
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

  Widget createChart(String title, List<DateTime> dates, List<double> values) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color1,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF522B5B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color4,
                  ),
                ),
              ),
              // Indicador del valor actual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF522B5B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  values.isNotEmpty ? values.last.toStringAsFixed(2) : '0.00',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LineChart(
                  LineChartData(
                    minY: -30.0,
                    maxY: 30.0,
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.round().toString(),
                                style: TextStyle(
                                  color: color4.withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      drawHorizontalLine: true,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFF522B5B),
                        spots: values
                            .asMap()
                            .entries
                            .map(
                              (e) => FlSpot(e.key.toDouble(), e.value),
                            )
                            .toList(),
                        barWidth: 2.5,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF522B5B).withValues(alpha: 0.3),
                              const Color(0xFF522B5B).withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        dotData: FlDotData(
                          show: values.isNotEmpty,
                          checkToShowDot: (spot, barData) {
                            return spot.x == values.length - 1;
                          },
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF522B5B),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
