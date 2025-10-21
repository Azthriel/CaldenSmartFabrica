// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/loggerble.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/resmon.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:flutter/material.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import '../master.dart';

class RollerPage extends StatefulWidget {
  const RollerPage({super.key});

  @override
  RollerPageState createState() => RollerPageState();
}

class RollerPageState extends State<RollerPage> {
  TextEditingController textController = TextEditingController();
  final PageController _pageController = PageController(initialPage: 0);
  TextEditingController rLargeController = TextEditingController();
  TextEditingController workController = TextEditingController();
  TextEditingController tpwmthrsController = TextEditingController();
  TextEditingController sgthrsController = TextEditingController();
  TextEditingController tcoolthrsController = TextEditingController();

  int _selectedIndex = 0;

  final String pc = DeviceManager.getProductCode(deviceName);
  final String sn = DeviceManager.extractSerialNumber(deviceName);
  final bool newGen = bluetoothManager.newGeneration;

  int _positionInDegrees = 0;
  int _actualPosition = 0;
  int _workingPosition = 0;
  bool _rollermoving = false;
  String _rollerLength = '';
  String _rollerPolarity = '';
  String _contrapulseTime = '';
  String _rollerRPM = '';
  String _rollerMicroStep = '';
  String _rollerIMAX = '';
  String _rollerIRMSRUN = '';
  String _rollerIRMSHOLD = '';
  bool _rollerFreewheeling = false;
  String _rollerTPWMTHRS = '';
  String _rollerTCOOLTHRS = '';
  String _rollerSGTHRS = '';

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
        bluetoothManager.data.containsKey('roller_position_degreees')
            ? _positionInDegrees =
                bluetoothManager.data['roller_position_degrees']
            : null;
        bluetoothManager.data.containsKey('roller_position')
            ? _actualPosition = bluetoothManager.data['roller_position']
            : null;
        bluetoothManager.data.containsKey('roller_target_position')
            ? _workingPosition = bluetoothManager.data['roller_target_position']
            : null;
        bluetoothManager.data.containsKey('roller_moving')
            ? _rollermoving = bluetoothManager.data['roller_moving']
            : null;
        bluetoothManager.data.containsKey('roller_length')
            ? _rollerLength = bluetoothManager.data['roller_length'].toString()
            : null;
        bluetoothManager.data.containsKey('roller_polarity')
            ? _rollerPolarity = bluetoothManager.data['roller_polarity']
            : null;
        bluetoothManager.data.containsKey('contrapulse_time')
            ? _contrapulseTime =
                bluetoothManager.data['contrapulse_time'].toString()
            : null;
        bluetoothManager.data.containsKey('motor_rpm')
            ? _rollerRPM = bluetoothManager.data['motor_rpm'].toString()
            : null;
        bluetoothManager.data.containsKey('microstep')
            ? _rollerMicroStep = bluetoothManager.data['microstep'].toString()
            : null;
        bluetoothManager.data.containsKey('motor_current_max')
            ? _rollerIMAX =
                bluetoothManager.data['motor_current_max'].toString()
            : null;
        bluetoothManager.data.containsKey('motor_current_run')
            ? _rollerIRMSRUN =
                bluetoothManager.data['motor_current_run'].toString()
            : null;
        bluetoothManager.data.containsKey('motor_current_hold')
            ? _rollerIRMSHOLD =
                bluetoothManager.data['motor_current_hold'].toString()
            : null;
        bluetoothManager.data.containsKey('free_wheeling')
            ? _rollerFreewheeling = bluetoothManager.data['free_wheeling']
            : null;
        bluetoothManager.data.containsKey('tpwm_thrs')
            ? _rollerTPWMTHRS = bluetoothManager.data['tpwm_thrs'].toString()
            : null;
        bluetoothManager.data.containsKey('tcool_thrs')
            ? _rollerTCOOLTHRS = bluetoothManager.data['tcool_thrs'].toString()
            : null;
        bluetoothManager.data.containsKey('sg_thrs')
            ? _rollerSGTHRS = bluetoothManager.data['sg_thrs'].toString()
            : null;
      });
    } else {
      setState(() {
        _positionInDegrees = actualPositionGrades;
        _actualPosition = actualPosition;
        _workingPosition = workingPosition;
        _rollermoving = rollerMoving;
        _rollerLength = rollerlength;
        _rollerPolarity = rollerPolarity;
        _contrapulseTime = contrapulseTime;
        _rollerRPM = rollerRPM;
        _rollerMicroStep = rollerMicroStep;
        _rollerIRMSRUN = rollerIRMSRUN;
        _rollerIRMSHOLD = rollerIRMSHOLD;
        _rollerFreewheeling = rollerFreewheeling;
        _rollerTPWMTHRS = rollerTPWMTHRS;
        _rollerTCOOLTHRS = rollerTCOOLTHRS;
        _rollerSGTHRS = rollerSGTHRS;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    textController.dispose();
    rLargeController.dispose();
    workController.dispose();
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
      subToVars();
    }
  }

  //BOTH GEN

  void setRange(int mm) {
    if (newGen) {
      final map = {
        "roller_length": mm,
      };
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[7]($mm)';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
  }

  void setDistance(int pc) {
    if (newGen) {
      final map = {
        "roller_position": pc,
      };
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[7]($pc%)';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
  }

  void setRollerConfig(int type) {
    if (newGen) {
      var map = {};
      if (type == 1) {
        map = {
          "invert_polarity": true,
        };
      } else {
        map = {
          "set_zero": true,
        };
      }
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[8]($type)';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
  }

  void setMotorSpeed(String rpm) {
    if (newGen) {
      final map = {
        "motor_rpm": int.parse(rpm),
      };
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[10]($rpm)';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
  }

  void setMicroStep(String uStep) {
    if (newGen) {
      final map = {
        "microstep": int.parse(uStep),
      };
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[11]($uStep)';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
  }

  void setMotorCurrent(bool run, String value) {
    if (newGen) {
      final map = {
        (run ? "motor_current_run" : "motor_current_hold"): int.parse(value),
      };
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[12](${run ? '1' : '0'}#$value)';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
  }

  void setFreeWheeling(bool active) {
    if (newGen) {
      final map = {
        "free_wheeling": active,
      };
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[14](${active ? '1' : '0'})';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
  }

  void setTPWMTHRS(String value) {
    if (newGen) {
      final map = {
        "tpwm_thrs": int.parse(value),
      };
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[15]($value)';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
  }

  void setTCOOLTHRS(String value) {
    if (newGen) {
      final map = {
        "tcool_thrs": int.parse(value),
      };
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[16]($value)';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
    }
  }

  void setSGTHRS(String value) {
    if (newGen) {
      final map = {
        "sg_thrs": int.parse(value),
      };
      List<int> messagePackData = serialize(map);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data = '$pc[17]($value)';
      printLog(data);
      bluetoothManager.toolsUuid.write(data.codeUnits);
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
        appMap.containsKey('roller_position_degreees')
            ? _positionInDegrees = appMap['roller_position_degrees']
            : null;
        appMap.containsKey('roller_position')
            ? _actualPosition = appMap['roller_position']
            : null;
        appMap.containsKey('roller_target_position')
            ? _workingPosition = appMap['roller_target_position']
            : null;
        appMap.containsKey('roller_moving')
            ? _rollermoving = appMap['roller_moving']
            : null;
        appMap.containsKey('roller_length')
            ? _rollerLength = appMap['roller_length'].toString()
            : null;
        appMap.containsKey('roller_polarity')
            ? _rollerPolarity = appMap['roller_polarity']
            : null;
        appMap.containsKey('contrapulse_time')
            ? _contrapulseTime = appMap['contrapulse_time'].toString()
            : null;
        appMap.containsKey('motor_rpm')
            ? _rollerRPM = appMap['motor_rpm'].toString()
            : null;
        appMap.containsKey('microstep')
            ? _rollerMicroStep = appMap['microstep'].toString()
            : null;
        appMap.containsKey('motor_current_max')
            ? _rollerIMAX = appMap['motor_current_max'].toString()
            : null;
        appMap.containsKey('motor_current_run')
            ? _rollerIRMSRUN = appMap['motor_current_run'].toString()
            : null;
        appMap.containsKey('motor_current_hold')
            ? _rollerIRMSHOLD = appMap['motor_current_hold'].toString()
            : null;
        appMap.containsKey('free_wheeling')
            ? _rollerFreewheeling = appMap['free_wheeling']
            : null;
        appMap.containsKey('tpwm_thrs')
            ? _rollerTPWMTHRS = appMap['tpwm_thrs'].toString()
            : null;
        appMap.containsKey('tcool_thrs')
            ? _rollerTCOOLTHRS = appMap['tcool_thrs'].toString()
            : null;
        appMap.containsKey('sg_thrs')
            ? _rollerSGTHRS = appMap['sg_thrs'].toString()
            : null;
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
    printLog(fun);
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
          errorSintax = getWifiErrorSintax(
            int.parse(parts[1]),
          );
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

  void subToVars() async {
    printLog('Me subscribo a vars');
    await bluetoothManager.varsUuid.setNotifyValue(true);

    final varsSub =
        bluetoothManager.varsUuid.onValueReceived.listen((List<int> status) {
      var parts = utf8.decode(status).split(':');
      // printLog(parts);
      if (context.mounted) {
        setState(() {
          _actualPosition = int.parse(parts[0]);
          _rollermoving = parts[1] == '1';
        });
      }
    });

    bluetoothManager.device.cancelWhenDisconnected(varsSub);
  }

  //! VISUAL
  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;

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
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    buildText(
                      text: '',
                      textSpans: [
                        const TextSpan(
                          text: 'Posición deseada:',
                          style: TextStyle(
                              color: color4, fontWeight: FontWeight.bold),
                        ),
                      ],
                      fontSize: 20.0,
                      textAlign: TextAlign.center,
                    ),
                    buildTextField(
                      controller: workController,
                      label: 'Modificar:',
                      hint: '',
                      keyboard: TextInputType.number,
                      onSubmitted: (value) {
                        _workingPosition = int.parse(value);
                        setDistance(int.parse(value));
                        workController.clear();
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                            trackHeight: 50.0,
                            valueIndicatorColor: color4,
                            thumbColor: color1,
                            activeTrackColor: color0,
                            inactiveTrackColor: color3,
                            thumbShape: IconThumbSlider(
                                iconData: _workingPosition - 1 <=
                                            _actualPosition &&
                                        _workingPosition + 1 >= _actualPosition
                                    ? Icons.check
                                    : _workingPosition < _actualPosition
                                        ? Icons.arrow_back
                                        : Icons.arrow_forward,
                                thumbRadius: 25)),
                        child: Slider(
                          value: _actualPosition.toDouble(),
                          secondaryTrackValue: _workingPosition.toDouble(),
                          onChanged: (_) {},
                          min: 0,
                          max: 100,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const Text(
                              'Posición actual:',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  color: color0,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            Text(
                              '$_actualPosition%',
                              style: const TextStyle(
                                  fontSize: 15.0,
                                  color: color0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const Text(
                              'Posición deseada:',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  color: color0,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              '$_workingPosition%',
                              style: const TextStyle(
                                  fontSize: 15.0,
                                  color: color0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Estado actual:',
                          style: TextStyle(
                              fontSize: 15.0,
                              color: color0,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Text(
                          _rollermoving ? 'EN MOVIMIENTO' : 'QUIETO',
                          style: const TextStyle(
                              fontSize: 15.0,
                              color: color0,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onLongPressStart: (LongPressStartDetails a) {
                        if (newGen) {
                          final map = {
                            "roller_position": 0,
                          };
                          List<int> messagePackData = serialize(map);
                          bluetoothManager.appDataUuid.write(messagePackData);
                          setState(() {
                            _workingPosition = 0;
                          });
                          printLog('Seteo posición a 0');
                        } else {
                          String data = '$pc[7](0%)';
                          bluetoothManager.toolsUuid.write(data.codeUnits);
                          setState(() {
                            _workingPosition = 0;
                          });
                          printLog(data);
                        }
                      },
                      onLongPressEnd: (LongPressEndDetails a) {
                        if (newGen) {
                          final map = {
                            "roller_position": _actualPosition,
                          };
                          List<int> messagePackData = serialize(map);
                          bluetoothManager.appDataUuid.write(messagePackData);
                          setState(() {
                            _workingPosition = _actualPosition;
                          });
                          printLog('Seteo posición a $_actualPosition');
                        } else {
                          String data = '$pc[7]($_actualPosition%)';
                          bluetoothManager.toolsUuid.write(data.codeUnits);
                          setState(() {
                            _workingPosition = _actualPosition;
                          });
                          printLog(data);
                        }
                      },
                      child: buildButton(
                        text: 'Subir',
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    GestureDetector(
                      onLongPressStart: (LongPressStartDetails a) {
                        if (newGen) {
                          final map = {
                            "roller_position": 100,
                          };
                          List<int> messagePackData = serialize(map);
                          bluetoothManager.appDataUuid.write(messagePackData);
                          setState(() {
                            _workingPosition = 100;
                          });
                          printLog('Seteo posición a 100');
                        } else {
                          String data = '$pc[7](100%)';
                          bluetoothManager.toolsUuid.write(data.codeUnits);
                          setState(() {
                            _workingPosition = 100;
                          });
                          printLog(data);
                        }
                      },
                      onLongPressEnd: (LongPressEndDetails a) {
                        if (newGen) {
                          final map = {
                            "roller_position": _actualPosition,
                          };
                          List<int> messagePackData = serialize(map);
                          bluetoothManager.appDataUuid.write(messagePackData);
                          setState(() {
                            _workingPosition = _actualPosition;
                          });
                          printLog('Seteo posición a $_actualPosition');
                        } else {
                          String data = '$pc[7]($_actualPosition%)';
                          bluetoothManager.toolsUuid.write(data.codeUnits);
                          setState(() {
                            _workingPosition = _actualPosition;
                          });
                          printLog(data);
                        }
                      },
                      child: buildButton(
                        text: 'Bajar',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                buildButton(
                  text: 'Setear punto 0',
                  onPressed: () {
                    setState(() {
                      _workingPosition = 0;
                    });
                    setRollerConfig(0);
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  children: [
                    buildText(
                      text: '',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      textSpans: [
                        const TextSpan(
                          text: 'Largo del Roller: ',
                          style: TextStyle(
                            fontSize: 20.0,
                            color: color4,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: _rollerLength,
                          style: const TextStyle(
                            fontSize: 25.0,
                            color: color4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: ' ° (grados)',
                          style: TextStyle(
                            fontSize: 20.0,
                            color: color4,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    buildButton(
                      text: 'Modificar',
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: color1,
                                title: const Text('Modificar largo (° grados)',
                                    style: TextStyle(color: color4)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: rLargeController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          label: Text(
                                        'Ingresar tamaño:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            color: color4),
                                      )),
                                      onSubmitted: (value) {
                                        int? valor =
                                            int.tryParse(rLargeController.text);
                                        if (valor != null) {
                                          setRange(valor);
                                          setState(() {
                                            _rollerLength = value;
                                          });
                                        } else {
                                          showToast('Valor no permitido');
                                        }
                                        rLargeController.clear();
                                        navigatorKey.currentState?.pop();
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      int? valor =
                                          int.tryParse(rLargeController.text);
                                      if (valor != null) {
                                        setRange(valor);
                                        setState(() {
                                          _rollerLength = rLargeController.text;
                                        });
                                      } else {
                                        showToast('Valor no permitido');
                                      }
                                      rLargeController.clear();
                                      navigatorKey.currentState?.pop();
                                    },
                                    child: const Text(
                                      'Modificar',
                                      style: TextStyle(color: color4),
                                    ),
                                  )
                                ],
                              );
                            });
                      },
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  width: 20,
                ),
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'Polaridad del Roller:\n',
                      style: TextStyle(
                        color: color4,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    TextSpan(
                      text: _rollerPolarity,
                      style: const TextStyle(
                        color: color4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                buildButton(
                  text: 'Invertir',
                  onPressed: () {
                    setRollerConfig(1);
                    _rollerPolarity == '0'
                        ? _rollerPolarity = '1'
                        : _rollerPolarity = '0';
                    context.mounted ? setState(() {}) : null;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    buildText(
                      text: '',
                      textSpans: [
                        const TextSpan(
                          text: 'RPM del motor:\n',
                          style: TextStyle(
                            color: color4,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: _rollerRPM,
                          style: const TextStyle(
                            color: color4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      fontSize: 20.0,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: 300,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 20.0,
                          valueIndicatorColor: color4,
                          thumbColor: color1,
                          activeTrackColor: color0,
                          inactiveTrackColor: color3,
                          thumbShape: const IconThumbSlider(
                            iconData: Icons.speed,
                            thumbRadius: 20,
                          ),
                        ),
                        child: buildTextField(
                          label: 'Modificar:',
                          hint: '',
                          keyboard: TextInputType.number,
                          onSubmitted: (value) {
                            setState(() {
                              _rollerRPM = value;
                            });
                            printLog('Modifico RPM a $value');
                            setMotorSpeed(value);
                          },
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'MicroSteps del roller:\n',
                      style: TextStyle(
                        color: color4,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    TextSpan(
                      text: _rollerMicroStep,
                      style: const TextStyle(
                        color: color4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 10,
                ),
                FractionallySizedBox(
                  alignment: Alignment.center,
                  widthFactor: 0.3,
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 1.0,
                    ),
                    decoration: BoxDecoration(
                      color: color0,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: color4,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Nuevo valor de microStep:',
                        labelStyle: TextStyle(
                          color: color0,
                        ),
                        hintStyle: TextStyle(
                          color: color0,
                        ),
                        border: InputBorder.none,
                      ),
                      dropdownColor: color1,
                      items: <String>[
                        '256',
                        '128',
                        '64',
                        '32',
                        '16',
                        '8',
                        '4',
                        '2',
                        '0',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: color4,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setMicroStep(value);
                          setState(() {
                            _rollerMicroStep = value.toString();
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    buildText(
                      text: '',
                      textSpans: [
                        const TextSpan(
                          text: 'Run current:\n',
                          style: TextStyle(
                            color: color4,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${((int.parse(_rollerIRMSRUN) * 2100) / 31).round()} mA',
                          style: const TextStyle(
                            color: color4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      fontSize: 20.0,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: 300,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 20.0,
                          valueIndicatorColor: color4,
                          thumbColor: color1,
                          activeTrackColor: color0,
                          inactiveTrackColor: color3,
                          thumbShape: const IconThumbSlider(
                            iconData: Icons.electric_bolt,
                            thumbRadius: 20,
                          ),
                        ),
                        child: Slider(
                          min: 0,
                          max: 31,
                          value: double.parse(_rollerIRMSRUN),
                          onChanged: (value) {
                            setState(() {
                              _rollerIRMSRUN = value.round().toString();
                            });
                          },
                          onChangeEnd: (value) {
                            setMotorCurrent(true, value.round().toString());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    buildText(
                      text: '',
                      textSpans: [
                        const TextSpan(
                          text: 'Hold current:\n',
                          style: TextStyle(
                            color: color4,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${((int.parse(_rollerIRMSHOLD) * 2100) / 31).round()} mA',
                          style: const TextStyle(
                            color: color4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      fontSize: 20.0,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: 300,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 20.0,
                          valueIndicatorColor: color4,
                          thumbColor: color1,
                          activeTrackColor: color0,
                          inactiveTrackColor: color3,
                          thumbShape: const IconThumbSlider(
                            iconData: Icons.electric_bolt,
                            thumbRadius: 20,
                          ),
                        ),
                        child: Slider(
                          min: 0,
                          max: 31,
                          value: double.parse(_rollerIRMSHOLD),
                          onChanged: (value) {
                            setState(() {
                              _rollerIRMSHOLD = value.round().toString();
                            });
                          },
                          onChangeEnd: (value) {
                            setMotorCurrent(false, value.round().toString());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    buildText(
                      text: '',
                      textSpans: [
                        const TextSpan(
                          text: 'Threshold PWM:\n',
                          style: TextStyle(
                              color: color4, fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: _rollerTPWMTHRS,
                          style: const TextStyle(
                              color: color4, fontWeight: FontWeight.bold),
                        ),
                      ],
                      fontSize: 20.0,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    buildTextField(
                      controller: tpwmthrsController,
                      label: 'Modificar:',
                      hint: '',
                      keyboard: TextInputType.number,
                      onSubmitted: (value) {
                        if (int.parse(value) <= 1048575 &&
                            int.parse(value) >= 0) {
                          printLog('Añaseo $value');
                          setTPWMTHRS(value);
                        } else {
                          showToast(
                              'El valor no esta en el rango\n0 - 1048575');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    buildText(
                      text: '',
                      textSpans: [
                        const TextSpan(
                          text: 'Threshold COOL:\n',
                          style: TextStyle(
                              color: color4, fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: _rollerTCOOLTHRS,
                          style: const TextStyle(
                              color: color4, fontWeight: FontWeight.bold),
                        ),
                      ],
                      fontSize: 20.0,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    buildTextField(
                      controller: tcoolthrsController,
                      label: 'Modificar:',
                      hint: '',
                      keyboard: TextInputType.number,
                      onSubmitted: (value) {
                        if (int.parse(value) <= 1048575 &&
                            int.parse(value) >= 1) {
                          setTCOOLTHRS(value);
                        } else {
                          showToast(
                              'El valor no esta en el rango\n1 - 1048575');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    buildText(
                      text: '',
                      textSpans: [
                        const TextSpan(
                          text: 'SG Threshold:\n',
                          style: TextStyle(
                              color: color4, fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: _rollerSGTHRS,
                          style: const TextStyle(
                              color: color4, fontWeight: FontWeight.bold),
                        ),
                      ],
                      fontSize: 20.0,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    buildTextField(
                      controller: sgthrsController,
                      label: 'Modificar:',
                      hint: '',
                      keyboard: TextInputType.number,
                      onSubmitted: (value) {
                        setState(() {
                          _rollerSGTHRS = value;
                        });
                        printLog('Modifique SG Threshold: $value');
                        setSGTHRS(value);
                      },
                    ),
                    // SizedBox(
                    //   width: 300,
                    //   child: TextField(
                    //     style: const TextStyle(color: Color(0xFFdfb6b2)),
                    //     keyboardType: TextInputType.number,
                    //     decoration: const InputDecoration(
                    //       labelText: 'Modificar:',
                    //       labelStyle: TextStyle(
                    //           color: Color(0xFFdfb6b2),
                    //           fontWeight: FontWeight.bold),
                    //     ),
                    //     onSubmitted: (value) {},
                    //   ),
                    // SliderTheme(
                    //   data: SliderTheme.of(context).copyWith(
                    //     trackHeight: 20.0,
                    //     thumbColor: const Color(0xfffbe4d8),
                    //     thumbShape: const IconThumbSlider(
                    //       iconData: Icons.catching_pokemon,
                    //       thumbRadius: 20,
                    //     ),
                    //   ),
                    //   child: Slider(
                    //     min: 0,
                    //     max: 255,
                    //     value: double.parse(rollerSGTHRS),
                    //     onChanged: (value) {
                    //       setState(() {
                    //         rollerSGTHRS = value.round().toString();
                    //       });
                    //     },
                    //     onChangeEnd: (value) {
                    //       setSGTHRS(value.round().toString());
                    //     },
                    //   ),
                    // ),
                    //),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    buildText(
                      text: 'Free Wheeling:',
                      fontSize: 20.0,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: 300,
                      child: Switch(
                        activeThumbColor: color4,
                        activeTrackColor: color1,
                        inactiveThumbColor: color1,
                        inactiveTrackColor: color4,
                        value: _rollerFreewheeling,
                        onChanged: (value) {
                          setFreeWheeling(value);
                          setState(() {
                            _rollerFreewheeling = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                buildButton(
                  text: 'Configurar ciclado',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final TextEditingController cicleController =
                            TextEditingController();
                        return AlertDialog(
                          backgroundColor: color0,
                          title: const Center(
                            child: Text(
                              'Especificar parametros del ciclador:',
                              style: TextStyle(
                                color: color4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  style: const TextStyle(
                                    color: color4,
                                  ),
                                  controller: cicleController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Ingrese cantidad de iteraciones',
                                    labelStyle: TextStyle(
                                      color: color4,
                                    ),
                                    hintStyle: TextStyle(
                                      color: color4,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                navigatorKey.currentState!.pop();
                              },
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: color4,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                registerActivity(pc, sn,
                                    'Se mando el ciclado de este equipo');
                                if (newGen) {
                                  final map = {
                                    'cycle': {
                                      'iter': int.parse(cicleController.text)
                                    }
                                  };
                                  List<int> messagePackData = serialize(map);
                                  bluetoothManager.appDataUuid
                                      .write(messagePackData);
                                } else {
                                  String data =
                                      '$pc[13](${int.parse(cicleController.text)})';
                                  bluetoothManager.toolsUuid
                                      .write(data.codeUnits);
                                  navigatorKey.currentState!.pop();
                                }
                              },
                              child: const Text(
                                'Iniciar proceso',
                                style: TextStyle(
                                  color: color4,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: bottomBarHeight + 20),
                ),
              ],
            ),
          ),
        ),
      ),

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
