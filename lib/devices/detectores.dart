import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:flutter/material.dart';
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
  int tempMicro = 0;
  String rs = '';
  String rrco = '';
  int rsValue = 0;
  int rrcoValue = 0;
  bool rsInvalid = false;
  bool rrcoInvalid = false;
  bool rsOver35k = false;
  int ppmCO = 0;
  int ppmCH4 = 0;
  //*-Calibracion-*\\
  //*-Regulacion-*\\
  List<String> valoresReg = [];
  final ScrollController _scrollController = ScrollController();
  bool regulationDone = false;
  //*-Regulacion-*\\
  //*-Debug-*\\
  List<String> debug = [];
  List<int> lastValue = [];
  int regIniIns = 0;
  //*-Debug-*\\
  //*-Light-*\\
  double _sliderValue = 100.0;
  //*-Light-*\\

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
    _setVrms02InputController.dispose();
    _setVrmsInputController.dispose();
    _setVccInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
    if (factoryMode) {
      _calValues = calibrationValues;
      ppmCO = workValues[5] + workValues[6] << 8;
      ppmCH4 = workValues[7] + workValues[8] << 8;
      updateValuesCalibracion(_calValues);
      _subscribeToCalCharacteristic();
      _subscribeToWorkCharacteristic();
      _readValues();
      _subscribeValue();
      updateDebugValues(debugValues);
      _subscribeDebug();
    }
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

  void _setVcc(String newValue) {
    if (newValue.isEmpty) {
      printLog('STRING EMPTY');
      return;
    }

    printLog('changing VCC!');

    List<int> vccNewOffset = List<int>.filled(3, 0);
    vccNewOffset[0] = int.parse(newValue);
    vccNewOffset[1] = 0; // only 8 bytes value
    vccNewOffset[2] = 0; // calibration point: vcc

    try {
      myDevice.calibrationUuid.write(vccNewOffset);
    } catch (e, stackTrace) {
      printLog('Error al escribir vcc offset $e $stackTrace');
      showToast('Error al escribir vcc offset');
      // handleManualError(e, stackTrace);
    }

    setState(() {});
  }

  void _setVrms(String newValue) {
    if (newValue.isEmpty) {
      return;
    }

    List<int> vrmsNewOffset = List<int>.filled(3, 0);
    vrmsNewOffset[0] = int.parse(newValue);
    vrmsNewOffset[1] = 0; // only 8 bytes value
    vrmsNewOffset[2] = 1; // calibration point: vrms

    try {
      myDevice.calibrationUuid.write(vrmsNewOffset);
    } catch (e, stackTrace) {
      printLog('Error al setear vrms offset $e $stackTrace');
      showToast('Error al setear vrms offset');
      // handleManualError(e, stackTrace);
    }

    setState(() {});
  }

  void _setVrms02(String newValue) {
    if (newValue.isEmpty) {
      return;
    }

    List<int> vrms02NewOffset = List<int>.filled(3, 0);
    vrms02NewOffset[0] = int.parse(newValue);
    vrms02NewOffset[1] = 0; // only 8 bytes value
    vrms02NewOffset[2] = 2; // calibration point: vrms02

    try {
      myDevice.calibrationUuid.write(vrms02NewOffset);
    } catch (e, stackTrace) {
      printLog('Error al setear vrms offset $e $stackTrace');
      showToast('Error al setear vrms02 offset');
      // handleManualError(e, stackTrace);
    }

    setState(() {});
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

      tempMicro = _calValues[7];
      rsValue = _calValues[8];
      rsValue += _calValues[9] << 8;

      rrcoValue = _calValues[10];
      rrcoValue = _calValues[11] << 8;

      if (rsValue >= 35000) {
        rsInvalid = true;
        rsOver35k = true;
        rsValue = 35000;
      } else {
        rsInvalid = false;
      }
      if (rsValue < 3500) {
        rsInvalid = true;
      } else {
        rsInvalid = false;
      }
      if (rrcoValue > 28000) {
        rrcoInvalid = false;
      } else {
        rrcoValue = 0;
        rrcoInvalid = true;
      }

      if (rsInvalid == true) {
        if (rsOver35k == true) {
          rs = '>35kΩ';
          rsColor = Colors.red;
        } else {
          rs = '<3.5kΩ';
          rsColor = Colors.red;
        }
      } else {
        var fun = rsValue / 1000;
        rs = '${fun}KΩ';
      }
      if (rrcoInvalid == true) {
        rrco = '<28kΩ';
        rrcoColor = Colors.red;
      } else {
        var fun = rrcoValue / 1000;
        rrco = '${fun}KΩ';
      }
    }

    setState(() {}); //reload the screen in each notification
  }

  void _subscribeToCalCharacteristic() async {
    if (!alreadySubCal) {
      await myDevice.calibrationUuid.setNotifyValue(true);
      alreadySubCal = true;
    }
    final calSub =
        myDevice.calibrationUuid.onValueReceived.listen((List<int> status) {
      updateValuesCalibracion(status);
    });

    myDevice.device.cancelWhenDisconnected(calSub);
  }

  void _subscribeToWorkCharacteristic() async {
    if (!alreadySubWork) {
      await myDevice.workUuid.setNotifyValue(true);
      alreadySubWork = true;
    }
    final workSub =
        myDevice.workUuid.onValueReceived.listen((List<int> status) {
      setState(() {
        ppmCO = status[5] + (status[6] << 8);
        ppmCH4 = status[7] + (status[8] << 8);
      });
    });

    myDevice.device.cancelWhenDisconnected(workSub);
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
      await myDevice.regulationUuid.setNotifyValue(true);
      alreadySubReg = true;
    }
    printLog('Me turbosuscribi a regulacion');
    final regSub =
        myDevice.regulationUuid.onValueReceived.listen((List<int> status) {
      updateValuesCalibracion(status);
    });

    myDevice.device.cancelWhenDisconnected(regSub);
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

  void _sendValueToBle(int value) async {
    try {
      final data = [value];
      myDevice.lightUuid.write(data, withoutResponse: true);
    } catch (e, stackTrace) {
      printLog('Error al mandar el valor del brillo $e $stackTrace');
      // handleManualError(e, stackTrace);
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
      await myDevice.debugUuid.setNotifyValue(true);
      alreadySubDebug = true;
    }
    printLog('Me turbosuscribi a regulacion');
    final debugSub =
        myDevice.debugUuid.onValueReceived.listen((List<int> status) {
      updateDebugValues(status);
    });

    myDevice.device.cancelWhenDisconnected(debugSub);
  }

  String _textToShow(int num) {
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

  //! VISUAL
  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;

    final List<Widget> pages = [
      if (accessLevel > 1) ...[
        //*- Página 1 TOOLS -*\\
        const ToolsPage(),

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
                        text: rs,
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
                    value: rsValue.toDouble(),
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
                        text: rrco,
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
                    value: rrcoValue.toDouble(),
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
                        text: tempMicro.toString(),
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
                        text: '$ppmCO',
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
                        text: '$ppmCH4',
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
                            color: const Color.fromARGB(255, 247, 230, 82),
                            textAlign: TextAlign.center,
                            widthFactor: 0.8,
                          ),
                          if (index == valoresReg.length - 1)
                            Padding(
                              padding:
                                  EdgeInsets.only(bottom: bottomBarHeight + 20),
                            ),
                        ],
                      );
                    },
                  ),
                )
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
                color: Colors.yellow.withOpacity(_sliderValue / 100),
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
                      _sendValueToBle(_sliderValue.toInt());
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
                const Text('Valores del PIC ADC',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: color1,
                        fontWeight: FontWeight.bold,
                        fontSize: 30)),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: debug.length + 1,
                    itemBuilder: (context, index) {
                      return index == 0
                          ? ListBody(
                              children: [
                                Row(
                                  children: [
                                    const Text('RegIniIns: ',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: color1,
                                            fontWeight: FontWeight.normal,
                                            fontSize: 20)),
                                    Text(regIniIns.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: color1,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20)),
                                  ],
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                      disabledActiveTrackColor: color0,
                                      disabledInactiveTrackColor: color3,
                                      trackHeight: 12,
                                      thumbShape: SliderComponentShape.noThumb),
                                  child: Slider(
                                    value: regIniIns.toDouble(),
                                    min: 0,
                                    max: pow(2, 32).toDouble(),
                                    onChanged: null,
                                    onChangeStart: null,
                                  ),
                                ),
                              ],
                            )
                          : ListBody(
                              children: [
                                Row(
                                  children: [
                                    Text(_textToShow(index - 1),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: color1,
                                            fontWeight: FontWeight.normal,
                                            fontSize: 20)),
                                    Text(debug[index - 1],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: color1,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20)),
                                  ],
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                      disabledActiveTrackColor: color0,
                                      disabledInactiveTrackColor: color3,
                                      trackHeight: 12,
                                      thumbShape: SliderComponentShape.noThumb),
                                  child: Slider(
                                    value: double.parse(debug[index - 1]),
                                    min: 0,
                                    max: 1024,
                                    onChanged: null,
                                    onChangeStart: null,
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        //*- Página 6 CREDENTIALS -*\\
        const CredsTab(),
      ],

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
                items: <Widget>[
                  if (accessLevel > 1) ...[
                    const Icon(Icons.settings, size: 30, color: color4),
                    if (factoryMode) ...[
                      const Icon(Icons.numbers, size: 30, color: color4),
                      const Icon(Icons.tune, size: 30, color: color4),
                    ],
                  ],
                  const Icon(Icons.lightbulb_sharp, size: 30, color: color4),
                  if (accessLevel > 1) ...[
                    if (factoryMode) ...[
                      const Icon(Icons.catching_pokemon,
                          size: 30, color: color4),
                    ],
                    const Icon(Icons.person, size: 30, color: color4),
                  ],
                  const Icon(Icons.send, size: 30, color: color4),
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
