import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/loggerble.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/resmon.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:flutter/material.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import '../master.dart';

class DetectorPage extends StatefulWidget {
  const DetectorPage({super.key});

  @override
  DetectorPageState createState() => DetectorPageState();
}

class DetectorPageState extends State<DetectorPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _selectedIndex = 0;

  //*-Calibracion-*\\
  final TextEditingController _setVccInputController = TextEditingController();
  final TextEditingController _setVrmsInputController = TextEditingController();
  final TextEditingController _setVrms02InputController =
      TextEditingController();
  Color _vrmsColor = color0;
  Color _vccColor = color0;
  Color rsColor = color0;
  Color rrcoColor = color0;
  List<int> _calValues = List<int>.filled(11, 0);
  int _vrms = 0;
  int _vcc = 0;
  int _vrmsOffset = 0;
  int _vrms02Offset = 0;
  int _vccOffset = 0;
  int _tempMicro = 0;
  String _rs = '';
  String _rrco = '';
  int _rsValue = 0;
  int _rrcoValue = 0;
  bool rsInvalid = false;
  bool rrcoInvalid = false;
  bool rsOver35k = false;
  int _ppmCO = 0;
  int _ppmCH4 = 0;
  //*-Calibracion-*\\
  //*-Regulacion-*\\
  List<String> valoresReg = [];
  final ScrollController _scrollController = ScrollController();
  bool regulationDone = false;
  String _res_sen_gas_20C = '';
  String _res_sen_gas_30C = '';
  String _res_sen_gas_40C = '';
  String _res_sen_gas_50C = '';
  String _res_sen_gas_xC = '';
  String _cor_temp_20C = '';
  String _cor_temp_30C = '';
  String _cor_temp_40C = '';
  String _cor_temp_50C = '';
  String _cor_temp_xC = '';
  String _res_sen_co_20C = '';
  String _res_sen_co_30C = '';
  String _res_sen_co_40C = '';
  String _res_sen_co_50C = '';
  String _res_sen_co_xC = '';
  String _res_sen_gas_aire_limpio = '';
  String _res_sen_co_aire_limpio = '';
  //*-Regulacion-*\\
  //*-Debug-*\\
  List<String> debug = [];
  List<int> lastValue = [];
  int regIniIns = 0;
  String _gasout = '';
  String _gasout_estable_ch4 = '';
  String _gasout_estable_co = '';
  String _vcc_reg = '';
  String _vcc_estable = '';
  String _temp = '';
  String _temp_estable = '';
  String _pwm_rising = '';
  String _pwm_falling = '';
  String _pwm = '';
  String _pwm_estable = '';
  //*-Debug-*\\
  //*-Light-*\\
  double _sliderValue = 100.0;
  //*-Light-*\\

  final String pc = DeviceManager.getProductCode(deviceName);
  final String sn = DeviceManager.extractSerialNumber(deviceName);
  final bool newGen = bluetoothManager.newGeneration;

  // Obtener el índice correcto para cada página
  int _getPageIndex(String pageType) {
    int index = 0;

    // Tools page (siempre presente)
    if (pageType == 'tools') return index;
    index++;

    // Numbers page (solo si accessLevel > 1 y factoryMode)
    if (accessLevel > 1 && factoryMode) {
      if (pageType == 'numbers') return index;
      index++;
    }

    // Tune page (solo si accessLevel > 1 y factoryMode)
    if (accessLevel > 1 && factoryMode) {
      if (pageType == 'tune') return index;
      index++;
    }

    // Control page (siempre presente)
    if (pageType == 'control') return index;
    index++;

    // Pokemon page (solo si accessLevel > 1 y factoryMode)
    if (accessLevel > 1 && factoryMode) {
      if (pageType == 'pokemon') return index;
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

    if (pageType == 'vars') return index;
    index++;

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
                // Numbers page (factory mode)
                if (accessLevel > 1 && factoryMode)
                  ListTile(
                    leading: const Icon(Icons.numbers, color: color4),
                    title: const Text('Carácteristicas',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('numbers'));
                    },
                  ),
                // Tune page (factory mode)
                if (accessLevel > 1 && factoryMode)
                  ListTile(
                    leading: const Icon(Icons.tune, color: color4),
                    title: const Text('Regulación',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('tune'));
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
                // Pokemon page (factory mode)
                if (accessLevel > 1 && factoryMode)
                  ListTile(
                    leading: const Icon(Icons.catching_pokemon, color: color4),
                    title: const Text('PIC Debug',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('pokemon'));
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

                ListTile(
                  leading: const Icon(Icons.vibration_sharp, color: color4),
                  title:
                      const Text('Variables', style: TextStyle(color: color4)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTab(_getPageIndex('vars'));
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
      printLog('Procesando valores: ${bluetoothManager.data}');
      setState(() {
        // calibration values
        bluetoothManager.data.containsKey('vrms')
            ? _vrms =
                int.tryParse(bluetoothManager.data['vrms'].toString()) ?? 0
            : null;
        bluetoothManager.data.containsKey('vcc')
            ? _vcc = int.tryParse(bluetoothManager.data['vcc'].toString()) ?? 0
            : null;
        bluetoothManager.data.containsKey('rs')
            ? _rsValue =
                int.tryParse(bluetoothManager.data['rs'].toString()) ?? 0
            : null;
        bluetoothManager.data.containsKey('rrco')
            ? _rrcoValue =
                int.tryParse(bluetoothManager.data['rrco'].toString()) ?? 0
            : null;
        bluetoothManager.data.containsKey('temp_micro')
            ? _tempMicro =
                int.tryParse(bluetoothManager.data['temp_micro'].toString()) ??
                    0
            : null;
        bluetoothManager.data.containsKey('ppm_co')
            ? _ppmCO =
                int.tryParse(bluetoothManager.data['ppm_co'].toString()) ?? 0
            : null;
        bluetoothManager.data.containsKey('ppm_ch4')
            ? _ppmCH4 =
                int.tryParse(bluetoothManager.data['ppm_ch4'].toString()) ?? 0
            : null;
        bluetoothManager.data.containsKey('rs_value')
            ? _rsValue =
                int.tryParse(bluetoothManager.data['rs_value'].toString()) ?? 0
            : null;
        bluetoothManager.data.containsKey('rrco_value')
            ? _rrcoValue =
                int.tryParse(bluetoothManager.data['rrco_value'].toString()) ??
                    0
            : null;
        bluetoothManager.data.containsKey('vcc_offset')
            ? _vccOffset =
                int.tryParse(bluetoothManager.data['vcc_offset'].toString()) ??
                    0
            : null;
        bluetoothManager.data.containsKey('vrms_offset')
            ? _vrmsOffset =
                int.tryParse(bluetoothManager.data['vrms_offset'].toString()) ??
                    0
            : null;
        bluetoothManager.data.containsKey('vrms02_offset')
            ? _vrms02Offset = int.tryParse(
                    bluetoothManager.data['vrms02_offset'].toString()) ??
                0
            : null;

        bluetoothManager.data.containsKey('regulation_done')
            ? regulationDone = bluetoothManager.data['regulation_done'] == true
            : null;

        // Debug values
        bluetoothManager.data.containsKey('gasout')
            ? _gasout = bluetoothManager.data['gasout'].toString()
            : null;
        bluetoothManager.data.containsKey('gasout_estable_ch4')
            ? _gasout_estable_ch4 =
                bluetoothManager.data['gasout_estable_ch4'].toString()
            : null;
        bluetoothManager.data.containsKey('gasout_estable_co')
            ? _gasout_estable_co =
                bluetoothManager.data['gasout_estable_co'].toString()
            : null;
        bluetoothManager.data.containsKey('vcc_reg')
            ? _vcc_reg = bluetoothManager.data['vcc_reg'].toString()
            : null;
        bluetoothManager.data.containsKey('vcc_estable')
            ? _vcc_estable = bluetoothManager.data['vcc_estable'].toString()
            : null;
        bluetoothManager.data.containsKey('temp')
            ? _temp = bluetoothManager.data['temp'].toString()
            : null;
        bluetoothManager.data.containsKey('temp_estable')
            ? _temp_estable = bluetoothManager.data['temp_estable'].toString()
            : null;
        bluetoothManager.data.containsKey('pwm_rising')
            ? _pwm_rising = bluetoothManager.data['pwm_rising'].toString()
            : null;
        bluetoothManager.data.containsKey('pwm_falling')
            ? _pwm_falling = bluetoothManager.data['pwm_falling'].toString()
            : null;
        bluetoothManager.data.containsKey('pwm')
            ? _pwm = bluetoothManager.data['pwm'].toString()
            : null;
        bluetoothManager.data.containsKey('pwm_estable')
            ? _pwm_estable = bluetoothManager.data['pwm_estable'].toString()
            : null;
        // Regulation values
        bluetoothManager.data.containsKey('res_sen_gas_20C')
            ? _res_sen_gas_20C =
                bluetoothManager.data['res_sen_gas_20C'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_gas_30C')
            ? _res_sen_gas_30C =
                bluetoothManager.data['res_sen_gas_30C'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_gas_40C')
            ? _res_sen_gas_40C =
                bluetoothManager.data['res_sen_gas_40C'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_gas_50C')
            ? _res_sen_gas_50C =
                bluetoothManager.data['res_sen_gas_50C'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_gas_xC')
            ? _res_sen_gas_xC =
                bluetoothManager.data['res_sen_gas_xC'].toString()
            : null;
        bluetoothManager.data.containsKey('cor_temp_20C')
            ? _cor_temp_20C = bluetoothManager.data['cor_temp_20C'].toString()
            : null;
        bluetoothManager.data.containsKey('cor_temp_30C')
            ? _cor_temp_30C = bluetoothManager.data['cor_temp_30C'].toString()
            : null;
        bluetoothManager.data.containsKey('cor_temp_40C')
            ? _cor_temp_40C = bluetoothManager.data['cor_temp_40C'].toString()
            : null;
        bluetoothManager.data.containsKey('cor_temp_50C')
            ? _cor_temp_50C = bluetoothManager.data['cor_temp_50C'].toString()
            : null;
        bluetoothManager.data.containsKey('cor_temp_xC')
            ? _cor_temp_xC = bluetoothManager.data['cor_temp_xC'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_co_20C')
            ? _res_sen_co_20C =
                bluetoothManager.data['res_sen_co_20C'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_co_30C')
            ? _res_sen_co_30C =
                bluetoothManager.data['res_sen_co_30C'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_co_40C')
            ? _res_sen_co_40C =
                bluetoothManager.data['res_sen_co_40C'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_co_50C')
            ? _res_sen_co_50C =
                bluetoothManager.data['res_sen_co_50C'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_co_xC')
            ? _res_sen_co_xC = bluetoothManager.data['res_sen_co_xC'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_gas_aire_limpio')
            ? _res_sen_gas_aire_limpio =
                bluetoothManager.data['res_sen_gas_aire_limpio'].toString()
            : null;
        bluetoothManager.data.containsKey('res_sen_co_aire_limpio')
            ? _res_sen_co_aire_limpio =
                bluetoothManager.data['res_sen_co_aire_limpio'].toString()
            : null;

        if (_rsValue >= 35000) {
          rsInvalid = true;
          rsOver35k = true;
          _rsValue = 35000;
        } else {
          rsInvalid = false;
        }
        if (_rsValue < 3500) {
          rsInvalid = true;
        } else {
          rsInvalid = false;
        }
        if (_rrcoValue > 28000) {
          rrcoInvalid = false;
        } else {
          _rrcoValue = 0;
          rrcoInvalid = true;
        }

        if (rsInvalid == true) {
          if (rsOver35k == true) {
            _rs = '>35kΩ';
            rsColor = Colors.red;
          } else {
            _rs = '<3.5kΩ';
            rsColor = Colors.red;
          }
        } else {
          var fun = _rsValue / 1000;
          _rs = '${fun}KΩ';
        }
        if (rrcoInvalid == true) {
          _rrco = '<28kΩ';
          rrcoColor = Colors.red;
        } else {
          var fun = _rrcoValue / 1000;
          _rrco = '${fun}KΩ';
        }

        if (_vcc > 5000) {
          _vccColor = Colors.red;
        } else {
          _vccColor = color0;
        }

        if (_vrms > 900) {
          _vrmsColor = Colors.red;
        } else {
          _vrmsColor = color0;
        }
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _setVrms02InputController.dispose();
    _setVrmsInputController.dispose();
    _setVccInputController.dispose();
    _scrollController.dispose();
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
      if (factoryMode) {
        _calValues = calibrationValues;
        _ppmCO = workValues[5] + workValues[6] << 8;
        _ppmCH4 = workValues[7] + workValues[8] << 8;
        updateValuesCalibracion(_calValues);
        _subscribeToCalCharacteristic();
        _subscribeToWorkCharacteristic();
        _readValues();
        _subscribeValue();
        updateDebugValues(debugValues);
        _subscribeDebug();
      }
    }
  }

  //NEW GEN

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
        // calibration values
        appMap.containsKey('vrms')
            ? _vrms = int.tryParse(appMap['vrms'].toString()) ?? 0
            : null;
        appMap.containsKey('vcc')
            ? _vcc = int.tryParse(appMap['vcc'].toString()) ?? 0
            : null;
        appMap.containsKey('rs')
            ? _rsValue = int.tryParse(appMap['rs'].toString()) ?? 0
            : null;
        appMap.containsKey('rrco')
            ? _rrcoValue = int.tryParse(appMap['rrco'].toString()) ?? 0
            : null;
        appMap.containsKey('temp_micro')
            ? _tempMicro = int.tryParse(appMap['temp_micro'].toString()) ?? 0
            : null;
        appMap.containsKey('ppm_co')
            ? _ppmCO = int.tryParse(appMap['ppm_co'].toString()) ?? 0
            : null;
        appMap.containsKey('ppm_ch4')
            ? _ppmCH4 = int.tryParse(appMap['ppm_ch4'].toString()) ?? 0
            : null;
        appMap.containsKey('rs_value')
            ? _rsValue = int.tryParse(appMap['rs_value'].toString()) ?? 0
            : null;
        appMap.containsKey('rrco_value')
            ? _rrcoValue = int.tryParse(appMap['rrco_value'].toString()) ?? 0
            : null;
        appMap.containsKey('vcc_offset')
            ? _vccOffset = int.tryParse(appMap['vcc_offset'].toString()) ?? 0
            : null;
        appMap.containsKey('vrms_offset')
            ? _vrmsOffset = int.tryParse(appMap['vrms_offset'].toString()) ?? 0
            : null;
        appMap.containsKey('vrms02_offset')
            ? _vrms02Offset =
                int.tryParse(appMap['vrms02_offset'].toString()) ?? 0
            : null;

        appMap.containsKey('regulation_done')
            ? regulationDone = appMap['regulation_done'] == true
            : null;

        // Debug values
        appMap.containsKey('gasout')
            ? _gasout = appMap['gasout'].toString()
            : null;
        appMap.containsKey('gasout_estable_ch4')
            ? _gasout_estable_ch4 = appMap['gasout_estable_ch4'].toString()
            : null;
        appMap.containsKey('gasout_estable_co')
            ? _gasout_estable_co = appMap['gasout_estable_co'].toString()
            : null;
        appMap.containsKey('vcc_reg')
            ? _vcc_reg = appMap['vcc_reg'].toString()
            : null;
        appMap.containsKey('vcc_estable')
            ? _vcc_estable = appMap['vcc_estable'].toString()
            : null;
        appMap.containsKey('temp') ? _temp = appMap['temp'].toString() : null;
        appMap.containsKey('temp_estable')
            ? _temp_estable = appMap['temp_estable'].toString()
            : null;
        appMap.containsKey('pwm_rising')
            ? _pwm_rising = appMap['pwm_rising'].toString()
            : null;
        appMap.containsKey('pwm_falling')
            ? _pwm_falling = appMap['pwm_falling'].toString()
            : null;
        appMap.containsKey('pwm') ? _pwm = appMap['pwm'].toString() : null;
        appMap.containsKey('pwm_estable')
            ? _pwm_estable = appMap['pwm_estable'].toString()
            : null;
        // Regulation values
        appMap.containsKey('res_sen_gas_20C')
            ? _res_sen_gas_20C = appMap['res_sen_gas_20C'].toString()
            : null;
        appMap.containsKey('res_sen_gas_30C')
            ? _res_sen_gas_30C = appMap['res_sen_gas_30C'].toString()
            : null;
        appMap.containsKey('res_sen_gas_40C')
            ? _res_sen_gas_40C = appMap['res_sen_gas_40C'].toString()
            : null;
        appMap.containsKey('res_sen_gas_50C')
            ? _res_sen_gas_50C = appMap['res_sen_gas_50C'].toString()
            : null;
        appMap.containsKey('res_sen_gas_xC')
            ? _res_sen_gas_xC = appMap['res_sen_gas_xC'].toString()
            : null;
        appMap.containsKey('cor_temp_20C')
            ? _cor_temp_20C = appMap['cor_temp_20C'].toString()
            : null;
        appMap.containsKey('cor_temp_30C')
            ? _cor_temp_30C = appMap['cor_temp_30C'].toString()
            : null;
        appMap.containsKey('cor_temp_40C')
            ? _cor_temp_40C = appMap['cor_temp_40C'].toString()
            : null;
        appMap.containsKey('cor_temp_50C')
            ? _cor_temp_50C = appMap['cor_temp_50C'].toString()
            : null;
        appMap.containsKey('cor_temp_xC')
            ? _cor_temp_xC = appMap['cor_temp_xC'].toString()
            : null;
        appMap.containsKey('res_sen_co_20C')
            ? _res_sen_co_20C = appMap['res_sen_co_20C'].toString()
            : null;
        appMap.containsKey('res_sen_co_30C')
            ? _res_sen_co_30C = appMap['res_sen_co_30C'].toString()
            : null;
        appMap.containsKey('res_sen_co_40C')
            ? _res_sen_co_40C = appMap['res_sen_co_40C'].toString()
            : null;
        appMap.containsKey('res_sen_co_50C')
            ? _res_sen_co_50C = appMap['res_sen_co_50C'].toString()
            : null;
        appMap.containsKey('res_sen_co_xC')
            ? _res_sen_co_xC = appMap['res_sen_co_xC'].toString()
            : null;
        appMap.containsKey('res_sen_gas_aire_limpio')
            ? _res_sen_gas_aire_limpio =
                appMap['res_sen_gas_aire_limpio'].toString()
            : null;
        appMap.containsKey('res_sen_co_aire_limpio')
            ? _res_sen_co_aire_limpio =
                appMap['res_sen_co_aire_limpio'].toString()
            : null;

        if (_rsValue >= 35000) {
          rsInvalid = true;
          rsOver35k = true;
          _rsValue = 35000;
        } else {
          rsInvalid = false;
        }
        if (_rsValue < 3500) {
          rsInvalid = true;
        } else {
          rsInvalid = false;
        }
        if (_rrcoValue > 28000) {
          rrcoInvalid = false;
        } else {
          _rrcoValue = 0;
          rrcoInvalid = true;
        }

        if (rsInvalid == true) {
          if (rsOver35k == true) {
            _rs = '>35kΩ';
            rsColor = Colors.red;
          } else {
            _rs = '<3.5kΩ';
            rsColor = Colors.red;
          }
        } else {
          var fun = _rsValue / 1000;
          _rs = '${fun}KΩ';
        }
        if (rrcoInvalid == true) {
          _rrco = '<28kΩ';
          rrcoColor = Colors.red;
        } else {
          var fun = _rrcoValue / 1000;
          _rrco = '${fun}KΩ';
        }

        if (_vcc > 5000) {
          _vccColor = Colors.red;
        } else {
          _vccColor = color0;
        }

        if (_vrms > 900) {
          _vrmsColor = Colors.red;
        } else {
          _vrmsColor = color0;
        }
      });
    });

    bluetoothManager.appDataUuid.setNotifyValue(true);

    bluetoothManager.device.cancelWhenDisconnected(appDataSub);
  }

  //OLD GEN

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

  void updateValuesCalibracion(List<int> newValues) async {
    _calValues = newValues;
    printLog('Valores actualizados: $_calValues');

    if (_calValues.isNotEmpty) {
      _vccOffset = _calValues[0];
      _vrmsOffset = _calValues[1];
      _vrms02Offset = _calValues[2];

      _vcc = _calValues[3];
      _vcc += _calValues[4] << 8;
      printLog(_vcc);

      double adcPwm = _calValues[5].toDouble();
      adcPwm += _calValues[6] << 8;
      adcPwm *= 2.001955034213099;
      _vrms = adcPwm.toInt();
      printLog(_vrms);

      //

      if (_vcc >= 8000 || _vrms >= 2000) {
        _vcc = 0;
        _vrms = 0;
      }

      //

      if (_vcc > 5000) {
        _vccColor = Colors.red;
      } else {
        _vccColor = color0;
      }

      if (_vrms > 900) {
        _vrmsColor = Colors.red;
      } else {
        _vrmsColor = color0;
      }

      _tempMicro = _calValues[7];
      _rsValue = _calValues[8];
      _rsValue += _calValues[9] << 8;

      _rrcoValue = _calValues[10];
      _rrcoValue = _calValues[11] << 8;

      if (_rsValue >= 35000) {
        rsInvalid = true;
        rsOver35k = true;
        _rsValue = 35000;
      } else {
        rsInvalid = false;
      }
      if (_rsValue < 3500) {
        rsInvalid = true;
      } else {
        rsInvalid = false;
      }
      if (_rrcoValue > 28000) {
        rrcoInvalid = false;
      } else {
        _rrcoValue = 0;
        rrcoInvalid = true;
      }

      if (rsInvalid == true) {
        if (rsOver35k == true) {
          _rs = '>35kΩ';
          rsColor = Colors.red;
        } else {
          _rs = '<3.5kΩ';
          rsColor = Colors.red;
        }
      } else {
        var fun = _rsValue / 1000;
        _rs = '${fun}KΩ';
      }
      if (rrcoInvalid == true) {
        _rrco = '<28kΩ';
        rrcoColor = Colors.red;
      } else {
        var fun = _rrcoValue / 1000;
        _rrco = '${fun}KΩ';
      }
    }

    setState(() {}); //reload the screen in each notification
  }

  void _subscribeToCalCharacteristic() async {
    if (!alreadySubCal) {
      await bluetoothManager.calibrationUuid.setNotifyValue(true);
      alreadySubCal = true;
    }
    final calSub = bluetoothManager.calibrationUuid.onValueReceived
        .listen((List<int> status) {
      updateValuesCalibracion(status);
    });

    bluetoothManager.device.cancelWhenDisconnected(calSub);
  }

  void _subscribeToWorkCharacteristic() async {
    if (!alreadySubWork) {
      await bluetoothManager.workUuid.setNotifyValue(true);
      alreadySubWork = true;
    }
    final workSub =
        bluetoothManager.workUuid.onValueReceived.listen((List<int> status) {
      setState(() {
        _ppmCO = status[5] + (status[6] << 8);
        _ppmCH4 = status[7] + (status[8] << 8);
      });
    });

    bluetoothManager.device.cancelWhenDisconnected(workSub);
  }

  void _readValues() {
    setState(() {
      for (int i = 0; i < 10; i += 2) {
        printLog('i = $i');
        int datas = regulationValues[i] + (regulationValues[i + 1] << 8);
        valoresReg.add(datas.toString());
      }
      for (int j = 10; j < 15; j++) {
        printLog('j = $j');
        valoresReg.add(regulationValues[j].toString());
      }
      for (int k = 15; k < 29; k += 2) {
        printLog('k = $k');
        int dataj = regulationValues[k] + (regulationValues[k + 1] << 8);
        valoresReg.add(dataj.toString());
      }

      if (regulationValues[29] == 0) {
        regulationDone = false;
      } else if (regulationValues[29] == 1) {
        regulationDone = true;
      }
    });
  }

  void _subscribeValue() async {
    if (!alreadySubReg) {
      await bluetoothManager.regulationUuid.setNotifyValue(true);
      alreadySubReg = true;
    }
    printLog('Me turbosuscribi a regulacion');
    final regSub = bluetoothManager.regulationUuid.onValueReceived
        .listen((List<int> status) {
      updateValuesCalibracion(status);
    });

    bluetoothManager.device.cancelWhenDisconnected(regSub);
  }

  void updateValuesRegulation(List<int> data) {
    valoresReg.clear();
    printLog('Entro: $data');
    setState(() {
      for (int i = 0; i < 10; i += 2) {
        int datas = data[i] + (data[i + 1] << 8);
        valoresReg.add(datas.toString());
      }
      for (int j = 10; j < 15; j++) {
        valoresReg.add(data[j].toString());
      }
      for (int k = 15; k < 29; k += 2) {
        int dataj = data[k] + (data[k + 1] << 8);
        valoresReg.add(dataj.toString());
      }

      if (data[29] == 0) {
        regulationDone = false;
      } else if (data[29] == 1) {
        regulationDone = true;
      }
    });
  }

  String textToShow(int index) {
    switch (index) {
      case 0:
        return 'Resistencia del sensor en gas a 20 grados';
      case 1:
        return 'Resistencia del sensor en gas a 30 grados';
      case 2:
        return 'Resistencia del sensor en gas a 40 grados';
      case 3:
        return 'Resistencia del sensor en gas a 50 grados';
      case 4:
        return 'Resistencia del sensor en gas a x grados';
      case 5:
        return 'Corrector de temperatura a 20 grados';
      case 6:
        return 'Corrector de temperatura a 30 grados';
      case 7:
        return 'Corrector de temperatura a 40 grados';
      case 8:
        return 'Corrector de temperatura a 50 grados';
      case 9:
        return 'Corrector de temperatura a x grados';
      case 10:
        return 'Resistencia de sensor en monoxido a 20 grados';
      case 11:
        return 'Resistencia de sensor en monoxido a 30 grados';
      case 12:
        return 'Resistencia de sensor en monoxido a 40 grados';
      case 13:
        return 'Resistencia de sensor en monoxido a 50 grados';
      case 14:
        return 'Resistencia de sensor en monoxido a x grados';
      case 15:
        return 'Resistencia del sensor de CH4 en aire limpio';
      case 16:
        return 'Resistencia del sensor de CO en aire limpio';
      default:
        return 'Error inesperado';
    }
  }

  void updateDebugValues(List<int> values) {
    debug.clear();
    lastValue.clear();
    printLog('Aqui esta esto: $values');
    printLog('Largo del valor: ${values.length}');

    setState(() {
      // Procesar valores de 16 bits y añadirlos a la lista debug
      for (int i = 0; i < values.length - 5; i += 2) {
        int datas = values[i] + (values[i + 1] << 8);
        debug.add(datas.toString());
      }

      // Actualizar lastValue para que contenga solo los últimos 4 elementos
      lastValue = values.sublist(values.length - 4);

      printLog('Largo del último valor: ${lastValue.length}');

      // Verificar que la lista tiene exactamente 4 elementos
      if (lastValue.length == 4) {
        regIniIns = (lastValue[3] << 24) |
            (lastValue[2] << 16) |
            (lastValue[1] << 8) |
            lastValue[0];
        printLog('Valor mistico: $regIniIns');
      } else {
        printLog('No hay suficientes valores para procesar regIniIns.');
      }
    });
  }

  void _subscribeDebug() async {
    if (!alreadySubDebug) {
      await bluetoothManager.debugUuid.setNotifyValue(true);
      alreadySubDebug = true;
    }
    printLog('Me turbosuscribi a regulacion');
    final debugSub =
        bluetoothManager.debugUuid.onValueReceived.listen((List<int> status) {
      updateDebugValues(status);
    });

    bluetoothManager.device.cancelWhenDisconnected(debugSub);
  }

  String _textToShowADC(int num) {
    switch (num + 1) {
      case 1:
        return 'Gasout: ';
      case 2:
        return 'Gasout estable CH4: ';
      case 3:
        return 'Gasout estable CO: ';
      case 4:
        return 'VCC: ';
      case 5:
        return 'VCC estable: ';
      case 6:
        return 'Temperatura: ';
      case 7:
        return 'Temperatura estable: ';
      case 8:
        return 'PWM Rising point: ';
      case 9:
        return 'PWM Falling point: ';
      case 10:
        return 'PWM: ';
      case 11:
        return 'PWM estable: ';
      default:
        return 'Error';
    }
  }

  //BOTH GEN

  void _setVcc(String newValue) {
    if (newValue.isEmpty) {
      printLog('STRING EMPTY');
      return;
    }

    printLog('changing VCC!');

    if (newGen) {
      Map<String, dynamic> map = {
        'set_vcc': int.parse(newValue),
      };
      List<int> encoded = serialize(map);
      try {
        bluetoothManager.appDataUuid.write(encoded);
      } catch (e, stackTrace) {
        printLog('Error al escribir vcc offset $e $stackTrace');
        showToast('Error al escribir vcc offset');
        // handleManualError(e, stackTrace);
      }
    } else {
      List<int> vccNewOffset = List<int>.filled(3, 0);
      vccNewOffset[0] = int.parse(newValue);
      vccNewOffset[1] = 0; // only 8 bytes value
      vccNewOffset[2] = 0; // calibration point: vcc

      try {
        bluetoothManager.calibrationUuid.write(vccNewOffset);
      } catch (e, stackTrace) {
        printLog('Error al escribir vcc offset $e $stackTrace');
        showToast('Error al escribir vcc offset');
        // handleManualError(e, stackTrace);
      }
    }

    setState(() {});
  }

  void _setVrms(String newValue) {
    if (newValue.isEmpty) {
      return;
    }

    if (newGen) {
      Map<String, dynamic> map = {
        'set_vrms': int.parse(newValue),
      };
      List<int> encoded = serialize(map);
      try {
        bluetoothManager.appDataUuid.write(encoded);
      } catch (e, stackTrace) {
        printLog('Error al setear vrms offset $e $stackTrace');
        showToast('Error al setear vrms offset');
      }
    } else {
      List<int> vrmsNewOffset = List<int>.filled(3, 0);
      vrmsNewOffset[0] = int.parse(newValue);
      vrmsNewOffset[1] = 0; // only 8 bytes value
      vrmsNewOffset[2] = 1; // calibration point: vrms

      try {
        bluetoothManager.calibrationUuid.write(vrmsNewOffset);
      } catch (e, stackTrace) {
        printLog('Error al setear vrms offset $e $stackTrace');
        showToast('Error al setear vrms offset');
        // handleManualError(e, stackTrace);
      }
    }
    setState(() {});
  }

  void _setVrms02(String newValue) {
    if (newValue.isEmpty) {
      return;
    }

    if (newGen) {
      Map<String, dynamic> map = {
        'set_vrms02': int.parse(newValue),
      };
      List<int> encoded = serialize(map);
      try {
        bluetoothManager.appDataUuid.write(encoded);
      } catch (e, stackTrace) {
        printLog('Error al setear vrms02 offset $e $stackTrace');
        showToast('Error al setear vrms02 offset');
      }
    } else {
      List<int> vrms02NewOffset = List<int>.filled(3, 0);
      vrms02NewOffset[0] = int.parse(newValue);
      vrms02NewOffset[1] = 0; // only 8 bytes value
      vrms02NewOffset[2] = 2; // calibration point: vrms02

      try {
        bluetoothManager.calibrationUuid.write(vrms02NewOffset);
      } catch (e, stackTrace) {
        printLog('Error al setear vrms offset $e $stackTrace');
        showToast('Error al setear vrms02 offset');
        // handleManualError(e, stackTrace);
      }
    }
    setState(() {});
  }

  void _setBrightness(int value) async {
    if (newGen) {
      try {
        Map<String, dynamic> map = {
          'set_brightness': value,
        };
        List<int> encoded = serialize(map);
        bluetoothManager.appDataUuid.write(encoded);
      } catch (e, stackTrace) {
        printLog('Error al mandar el valor del brillo $e $stackTrace');
      }
    } else {
      try {
        final data = [value];
        bluetoothManager.lightUuid.write(data, withoutResponse: true);
      } catch (e, stackTrace) {
        printLog('Error al mandar el valor del brillo $e $stackTrace');
        // handleManualError(e, stackTrace);
      }
    }
  }

  void _cambiarTipoDeDispositivo(bool deviceEBBR) {
    if (newGen) {
      Map<String, dynamic> map = {
        'set_EBBR': deviceEBBR,
      };
      List<int> encoded = serialize(map);
      try {
        bluetoothManager.appDataUuid.write(encoded);
      } catch (e, stackTrace) {
        printLog('Error al cambiar el tipo de dispositivo $e $stackTrace');
        showToast('Error al cambiar el tipo de dispositivo');
      }
    } else {
      String data = '$pc[11](${deviceEBBR ? 1 : 0})';

      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
    showToast(
        'Tipo de dispositivo cambiado. ${deviceEBBR ? 'EBBR' : 'Normal'}');
  }

  //! VISUAL
  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;

    final List<Widget> pages = [
      //*- Página 1 TOOLS -*\\
      const ToolsPage(),
      if (accessLevel > 1) ...[
        if (factoryMode) ...[
          //*- Página 2 CALIBRACION -*\\
          Scaffold(
            backgroundColor: color4,
            body: ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                Text('Valores de calibracion: $_calValues',
                    textScaler: const TextScaler.linear(1.2),
                    style: const TextStyle(color: color0)),
                const SizedBox(height: 40),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '(C21) VCC:                          ',
                        style: TextStyle(
                          fontSize: 22.0,
                          color: color0,
                        ),
                      ),
                      TextSpan(
                        text: '$_vcc',
                        style: TextStyle(
                          fontSize: 24.0,
                          color: _vccColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' mV',
                        style: TextStyle(
                          fontSize: 22.0,
                          color: _vccColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                      disabledActiveTrackColor: _vccColor,
                      disabledInactiveTrackColor: color3,
                      trackHeight: 12,
                      thumbShape: SliderComponentShape.noThumb),
                  child: Slider(
                    value: _vcc.toDouble(),
                    min: 0,
                    max: 8000,
                    onChanged: null,
                    onChangeStart: null,
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '(C21) VRMS:                          ',
                        style: TextStyle(
                          fontSize: 22.0,
                          color: color0,
                        ),
                      ),
                      TextSpan(
                        text: '$_vrms',
                        style: TextStyle(
                          fontSize: 24.0,
                          color: _vrmsColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' mV',
                        style: TextStyle(
                          fontSize: 22.0,
                          color: _vrmsColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                      disabledActiveTrackColor: _vrmsColor,
                      disabledInactiveTrackColor: color3,
                      trackHeight: 12,
                      thumbShape: SliderComponentShape.noThumb),
                  child: Slider(
                    value: _vrms.toDouble(),
                    min: 0,
                    max: 2000,
                    onChanged: null,
                    onChangeStart: null,
                  ),
                ),
                const SizedBox(height: 50),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '(C20) VCC Offset:                  ',
                        style: TextStyle(fontSize: 22.0, color: color0),
                      ),
                      TextSpan(
                        text: '$_vccOffset ',
                        style: const TextStyle(
                            fontSize: 22.0,
                            color: color0,
                            fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: 'ADCU',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: color0,
                        ),
                      ),
                    ],
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.550,
                  alignment: Alignment.bottomLeft,
                  child: TextField(
                    style: const TextStyle(color: color0),
                    keyboardType: TextInputType.number,
                    controller: _setVccInputController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      prefixText: '(0 - 255)  ',
                      prefixStyle: TextStyle(
                        color: color0,
                      ),
                      hintText: 'Modificar VCC',
                      hintStyle: TextStyle(
                        color: color0,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (int.parse(value) <= 255 && int.parse(value) >= 0) {
                        _setVcc(value);
                      } else {
                        showToast('Valor ingresado invalido');
                      }
                      _setVccInputController.clear();
                    },
                  ),
                ),
                const SizedBox(height: 40),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '(C21) VRMS Offset:            ',
                        style: TextStyle(fontSize: 22.0, color: color0),
                      ),
                      TextSpan(
                        text: '$_vrmsOffset ',
                        style: const TextStyle(
                            fontSize: 22.0,
                            color: color0,
                            fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: 'ADCU',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: color0,
                        ),
                      ),
                    ],
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.550,
                  alignment: Alignment.bottomLeft,
                  child: TextField(
                    style: const TextStyle(
                      color: color0,
                    ),
                    keyboardType: TextInputType.number,
                    controller: _setVrmsInputController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      prefixText: '(0 - 255)  ',
                      prefixStyle: TextStyle(
                        color: color0,
                      ),
                      hintText: 'Modificar VRMS',
                      hintStyle: TextStyle(
                        color: color0,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (int.parse(value) <= 255 && int.parse(value) >= 0) {
                        _setVrms(value);
                      } else {
                        showToast('Valor ingresado invalido');
                      }
                      _setVrmsInputController.clear();
                    },
                  ),
                ),
                const SizedBox(height: 40),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '(C97) VRMS02 Offset:            ',
                        style: TextStyle(fontSize: 22.0, color: color0),
                      ),
                      TextSpan(
                        text: '$_vrms02Offset ',
                        style: const TextStyle(
                            fontSize: 22.0,
                            color: color0,
                            fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: 'ADCU',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: color0,
                        ),
                      ),
                    ],
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.550,
                  alignment: Alignment.bottomLeft,
                  child: TextField(
                    style: const TextStyle(
                      color: color0,
                    ),
                    keyboardType: TextInputType.number,
                    controller: _setVrms02InputController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      prefixText: '(0 - 255)  ',
                      prefixStyle: TextStyle(
                        color: color0,
                      ),
                      hintText: 'Modificar VRMS',
                      hintStyle: TextStyle(
                        color: color0,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (int.parse(value) <= 255 && int.parse(value) >= 0) {
                        _setVrms02(value);
                      } else {
                        showToast('Valor ingresado invalido');
                      }
                      _setVrms02InputController.clear();
                    },
                  ),
                ),
                const SizedBox(height: 70),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Resistencia del sensor en GAS: ',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: color0,
                        ),
                      ),
                      TextSpan(
                        text: _rs,
                        style: TextStyle(
                          fontSize: 24.0,
                          color: rsColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    disabledActiveTrackColor: rsColor,
                    disabledInactiveTrackColor: color3,
                    trackHeight: 12,
                    thumbShape: SliderComponentShape.noThumb,
                  ),
                  child: Slider(
                    value: _rsValue.toDouble(),
                    min: 0,
                    max: 35000,
                    onChanged: null,
                    onChangeStart: null,
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Resistencia de sensor en monoxido: ',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: color0,
                        ),
                      ),
                      TextSpan(
                        text: _rrco,
                        style: TextStyle(
                          fontSize: 24.0,
                          color: rrcoColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    disabledActiveTrackColor: rrcoColor,
                    disabledInactiveTrackColor: color3,
                    trackHeight: 12,
                    thumbShape: SliderComponentShape.noThumb,
                  ),
                  child: Slider(
                    value: _rrcoValue.toDouble(),
                    min: 0,
                    max: 100000,
                    onChanged: null,
                    onChangeStart: null,
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Temperatura del micro: ',
                        style: TextStyle(
                          fontSize: 22.0,
                          color: color0,
                        ),
                      ),
                      TextSpan(
                        text: _tempMicro.toString(),
                        style: const TextStyle(
                          fontSize: 24.0,
                          color: color0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: '°C',
                        style: TextStyle(
                          fontSize: 24.0,
                          color: color0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'PPM CO: ',
                        style: TextStyle(
                          fontSize: 22.0,
                          color: color0,
                        ),
                      ),
                      TextSpan(
                        text: '$_ppmCO',
                        style: const TextStyle(
                          fontSize: 24.0,
                          color: color0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'PPM CH4: ',
                        style: TextStyle(
                          fontSize: 22.0,
                          color: color0,
                        ),
                      ),
                      TextSpan(
                        text: '$_ppmCH4',
                        style: const TextStyle(
                          fontSize: 24.0,
                          color: color0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.only(bottom: bottomBarHeight + 20),
                ),
              ],
            ),
          ),

          //*- Página 3 REGULATION -*\\
          Scaffold(
            backgroundColor: color4,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'Regulación completada:\n',
                      style:
                          TextStyle(color: color4, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: regulationDone ? 'SI' : 'NO',
                      style: TextStyle(
                          color: regulationDone ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (newGen) ...[
                  // Nueva generación - mostrar valores individuales
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      children: [
                        if (_res_sen_gas_20C.isNotEmpty) ...[
                          buildText(
                            text: 'Resistencia del sensor en gas a 20 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_gas_20C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_gas_30C.isNotEmpty) ...[
                          buildText(
                            text: 'Resistencia del sensor en gas a 30 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_gas_30C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_gas_40C.isNotEmpty) ...[
                          buildText(
                            text: 'Resistencia del sensor en gas a 40 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_gas_40C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_gas_50C.isNotEmpty) ...[
                          buildText(
                            text: 'Resistencia del sensor en gas a 50 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_gas_50C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_gas_xC.isNotEmpty) ...[
                          buildText(
                            text: 'Resistencia del sensor en gas a x grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_gas_xC,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_cor_temp_20C.isNotEmpty) ...[
                          buildText(
                            text: 'Corrector de temperatura a 20 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _cor_temp_20C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_cor_temp_30C.isNotEmpty) ...[
                          buildText(
                            text: 'Corrector de temperatura a 30 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _cor_temp_30C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_cor_temp_40C.isNotEmpty) ...[
                          buildText(
                            text: 'Corrector de temperatura a 40 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _cor_temp_40C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_cor_temp_50C.isNotEmpty) ...[
                          buildText(
                            text: 'Corrector de temperatura a 50 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _cor_temp_50C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_cor_temp_xC.isNotEmpty) ...[
                          buildText(
                            text: 'Corrector de temperatura a x grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _cor_temp_xC,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_co_20C.isNotEmpty) ...[
                          buildText(
                            text:
                                'Resistencia de sensor en monoxido a 20 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_co_20C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_co_30C.isNotEmpty) ...[
                          buildText(
                            text:
                                'Resistencia de sensor en monoxido a 30 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_co_30C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_co_40C.isNotEmpty) ...[
                          buildText(
                            text:
                                'Resistencia de sensor en monoxido a 40 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_co_40C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_co_50C.isNotEmpty) ...[
                          buildText(
                            text:
                                'Resistencia de sensor en monoxido a 50 grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_co_50C,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_co_xC.isNotEmpty) ...[
                          buildText(
                            text:
                                'Resistencia de sensor en monoxido a x grados',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_co_xC,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_gas_aire_limpio.isNotEmpty) ...[
                          buildText(
                            text:
                                'Resistencia del sensor de CH4 en aire limpio',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_gas_aire_limpio,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (_res_sen_co_aire_limpio.isNotEmpty) ...[
                          buildText(
                            text: 'Resistencia del sensor de CO en aire limpio',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.left,
                            widthFactor: 0.8,
                          ),
                          buildText(
                            text: _res_sen_co_aire_limpio,
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          const SizedBox(height: 15),
                        ],
                        Padding(
                          padding:
                              EdgeInsets.only(bottom: bottomBarHeight + 20),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Vieja generación - mostrar valores de valoresReg
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: valoresReg.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            buildText(
                              text: textToShow(index),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              textAlign: TextAlign.left,
                              widthFactor: 0.8,
                            ),
                            buildText(
                              text: valoresReg[index],
                              fontSize: 30,
                              fontWeight: FontWeight.normal,
                              textAlign: TextAlign.center,
                              widthFactor: 0.8,
                            ),
                            if (index == valoresReg.length - 1) ...[
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: bottomBarHeight + 20,
                                ),
                              )
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],

      //*- Página 4 LIGHT -*\\
      Scaffold(
        backgroundColor: color4,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb,
                size: 200,
                color: Colors.yellow.withValues(alpha: (_sliderValue / 100)),
              ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    valueIndicatorColor: color4,
                    thumbColor: color1,
                    activeTrackColor: color0,
                    inactiveTrackColor: color3,
                    trackHeight: 50.0,
                    thumbShape: IconThumbSlider(
                        iconData: _sliderValue > 50
                            ? Icons.light_mode
                            : Icons.nightlight,
                        thumbRadius: 28),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    min: 0.0,
                    max: 100.0,
                    onChanged: (double value) {
                      setState(() {
                        _sliderValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {
                        _sliderValue = value;
                      });
                      _setBrightness(_sliderValue.toInt());
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              buildText(
                  text: 'Valor del brillo: ${_sliderValue.toStringAsFixed(0)}'),
            ],
          ),
        ),
      ),

      if (accessLevel > 1) ...[
        if (factoryMode) ...[
          //*- Página 5 DEBUG -*\\
          Scaffold(
            backgroundColor: color4,
            body: Column(
              children: [
                const Text(
                  'Valores del PIC ADC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color1,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                if (newGen) ...[
                  // Nueva generación - mostrar valores individuales
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      children: [
                        if (_gasout.isNotEmpty) ...[
                          buildText(
                            text: 'Gasout: $_gasout',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_gasout_estable_ch4.isNotEmpty) ...[
                          buildText(
                            text: 'Gasout estable CH4: $_gasout_estable_ch4',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_gasout_estable_co.isNotEmpty) ...[
                          buildText(
                            text: 'Gasout estable CO: $_gasout_estable_co',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_vcc_reg.isNotEmpty) ...[
                          buildText(
                            text: 'VCC: $_vcc_reg',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_vcc_estable.isNotEmpty) ...[
                          buildText(
                            text: 'VCC estable: $_vcc_estable',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_temp.isNotEmpty) ...[
                          buildText(
                            text: 'Temperatura: $_temp',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_temp_estable.isNotEmpty) ...[
                          buildText(
                            text: 'Temperatura estable: $_temp_estable',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_pwm_rising.isNotEmpty) ...[
                          buildText(
                            text: 'PWM Rising point: $_pwm_rising',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_pwm_falling.isNotEmpty) ...[
                          buildText(
                            text: 'PWM Falling point: $_pwm_falling',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_pwm.isNotEmpty) ...[
                          buildText(
                            text: 'PWM: $_pwm',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_pwm_estable.isNotEmpty) ...[
                          buildText(
                            text: 'PWM estable: $_pwm_estable',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        Padding(
                          padding:
                              EdgeInsets.only(bottom: bottomBarHeight + 20),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Vieja generación - mostrar valores de valoresReg
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: debug.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            buildText(
                              text: _textToShowADC(index),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              textAlign: TextAlign.left,
                              widthFactor: 0.8,
                            ),
                            buildText(
                              text: debug[index],
                              fontSize: 30,
                              fontWeight: FontWeight.normal,
                              textAlign: TextAlign.center,
                              widthFactor: 0.8,
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                  disabledActiveTrackColor: color0,
                                  disabledInactiveTrackColor: color3,
                                  trackHeight: 12,
                                  thumbShape: SliderComponentShape.noThumb),
                              child: Slider(
                                value: double.parse(debug[index]),
                                min: 0,
                                max: 1024,
                                onChanged: null,
                                onChangeStart: null,
                              ),
                            ),
                            if (index == valoresReg.length - 1) ...[
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: bottomBarHeight + 20),
                              ),
                            ]
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        //*- Página 6 CREDENTIALS -*\\
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

      Scaffold(
        backgroundColor: color4,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildText(
                text: 'Cambiar tipo de dispositivo:',
              ),
              const SizedBox(height: 20),
              buildButton(
                text: 'Si es EBBR',
                onPressed: () => _cambiarTipoDeDispositivo(true),
              ),
              const SizedBox(height: 10),
              buildButton(
                text: 'No es EBBR',
                onPressed: () => _cambiarTipoDeDispositivo(false),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      //*- Página 7 OTA -*\\
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
                          height: 100,
                        ),
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
