import 'dart:async';
import 'dart:convert';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:flutter/material.dart';
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
    rLargeController.dispose();
    workController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
    subToVars();
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
    await myDevice.toolsUuid.setNotifyValue(true);

    final wifiSub =
        myDevice.toolsUuid.onValueReceived.listen((List<int> status) {
      updateWifiValues(status);
    });

    myDevice.device.cancelWhenDisconnected(wifiSub);
  }

  void subToVars() async {
    printLog('Me subscribo a vars');
    await myDevice.varsUuid.setNotifyValue(true);

    final varsSub =
        myDevice.varsUuid.onValueReceived.listen((List<int> status) {
      var parts = utf8.decode(status).split(':');
      // printLog(parts);
      if (context.mounted) {
        setState(() {
          actualPosition = int.parse(parts[0]);
          rollerMoving = parts[1] == '1';
        });
      }
    });

    myDevice.device.cancelWhenDisconnected(varsSub);
  }

  void setRange(int mm) {
    String data = '${DeviceManager.getProductCode(deviceName)}[7]($mm)';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void setDistance(int pc) {
    String data = '${DeviceManager.getProductCode(deviceName)}[7]($pc%)';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void setRollerConfig(int type) {
    String data = '${DeviceManager.getProductCode(deviceName)}[8]($type)';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void setMotorSpeed(String rpm) {
    String data = '${DeviceManager.getProductCode(deviceName)}[10]($rpm)';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void setMicroStep(String uStep) {
    String data = '${DeviceManager.getProductCode(deviceName)}[11]($uStep)';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void setMotorCurrent(bool run, String value) {
    String data =
        '${DeviceManager.getProductCode(deviceName)}[12](${run ? '1' : '0'}#$value)';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void setFreeWheeling(bool active) {
    String data =
        '${DeviceManager.getProductCode(deviceName)}[14](${active ? '1' : '0'})';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void setTPWMTHRS(String value) {
    String data = '${DeviceManager.getProductCode(deviceName)}[15]($value)';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void setTCOOLTHRS(String value) {
    String data = '${DeviceManager.getProductCode(deviceName)}[16]($value)';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void setSGTHRS(String value) {
    String data = '${DeviceManager.getProductCode(deviceName)}[17]($value)';
    printLog(data);
    myDevice.toolsUuid.write(data.codeUnits);
  }

  //! VISUAL
  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;

    final List<Widget> pages = [
      if (accessLevel > 1) ...[
        //*- Página 1 TOOLS -*\\
        const ToolsPage(),

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
                        workingPosition = int.parse(value);
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
                                iconData: workingPosition - 1 <=
                                            actualPosition &&
                                        workingPosition + 1 >= actualPosition
                                    ? Icons.check
                                    : workingPosition < actualPosition
                                        ? Icons.arrow_back
                                        : Icons.arrow_forward,
                                thumbRadius: 25)),
                        child: Slider(
                          value: actualPosition.toDouble(),
                          secondaryTrackValue: workingPosition.toDouble(),
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
                              '$actualPosition%',
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
                              '$workingPosition%',
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
                          rollerMoving ? 'EN MOVIMIENTO' : 'QUIETO',
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
                        String data =
                            '${DeviceManager.getProductCode(deviceName)}[7](0%)';
                        myDevice.toolsUuid.write(data.codeUnits);
                        setState(() {
                          workingPosition = 0;
                        });
                        printLog(data);
                      },
                      onLongPressEnd: (LongPressEndDetails a) {
                        String data =
                            '${DeviceManager.getProductCode(deviceName)}[7]($actualPosition%)';
                        myDevice.toolsUuid.write(data.codeUnits);
                        setState(() {
                          workingPosition = actualPosition;
                        });
                        printLog(data);
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
                        String data =
                            '${DeviceManager.getProductCode(deviceName)}[7](100%)';
                        myDevice.toolsUuid.write(data.codeUnits);
                        setState(() {
                          workingPosition = 100;
                        });
                        printLog(data);
                      },
                      onLongPressEnd: (LongPressEndDetails a) {
                        String data =
                            '${DeviceManager.getProductCode(deviceName)}[7]($actualPosition%)';
                        myDevice.toolsUuid.write(data.codeUnits);
                        setState(() {
                          workingPosition = actualPosition;
                        });
                        printLog(data);
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
                      workingPosition = 0;
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
                          text: rollerlength,
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
                                            rollerlength = value;
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
                                          rollerlength = rLargeController.text;
                                        });
                                      } else {
                                        showToast('Valor no permitido');
                                      }
                                      rLargeController.clear();
                                      navigatorKey.currentState?.pop();
                                    },
                                    child: const Text('Modificar',
                                        style: TextStyle(color: color4)),
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
                      text: rollerPolarity,
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
                    rollerPolarity == '0'
                        ? rollerPolarity = '1'
                        : rollerPolarity = '0';
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
                          text: rollerRPM,
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
                              rollerRPM = value;
                            });
                            printLog('Modifico RPM a $value');
                            setMotorSpeed(value);
                          },
                        ),

                        // Slider(
                        //   min: 0,
                        //   max: 400,
                        //   value: double.parse(rollerRPM),
                        //   onChanged: (value) {
                        //     setState(() {
                        //       rollerRPM = value.round().toString();
                        //     });
                        //   },
                        //   onChangeEnd: (value) {
                        //     setMotorSpeed(value.round().toString());
                        //   },
                        // ),
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
                      text: rollerMicroStep,
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
                            rollerMicroStep = value.toString();
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
                              '${((int.parse(rollerIRMSRUN) * 2100) / 31).round()} mA',
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
                          value: double.parse(rollerIRMSRUN),
                          onChanged: (value) {
                            setState(() {
                              rollerIRMSRUN = value.round().toString();
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
                              '${((int.parse(rollerIRMSHOLD) * 2100) / 31).round()} mA',
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
                          value: double.parse(rollerIRMSHOLD),
                          onChanged: (value) {
                            setState(() {
                              rollerIRMSHOLD = value.round().toString();
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
                          text: rollerTPWMTHRS,
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
                      controller: workController,
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
                          text: rollerTCOOLTHRS,
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
                      controller: workController,
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
                          text: rollerSGTHRS,
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
                      controller: workController,
                      label: 'Modificar:',
                      hint: '',
                      keyboard: TextInputType.number,
                      onSubmitted: (value) {
                        setState(() {
                          rollerSGTHRS = value;
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
                        activeColor: color4,
                        activeTrackColor: color1,
                        inactiveThumbColor: color1,
                        inactiveTrackColor: color4,
                        value: rollerFreewheeling,
                        onChanged: (value) {
                          setFreeWheeling(value);
                          setState(() {
                            rollerFreewheeling = value;
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
                  Image.asset(EasterEggs.legajosMeme.contains(legajoConectado)
                          ? 'assets/eg/DSC.gif'
                          : 'assets/Loading.gif', width: 100, height: 100),
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
                        Image.asset(EasterEggs.legajosMeme.contains(legajoConectado)
                          ? 'assets/eg/DSC.gif'
                          : 'assets/Loading.gif',
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
                items: <Widget>[
                  if (accessLevel > 1) ...[
                    const Icon(Icons.settings, size: 30, color: color4),
                    const Icon(Icons.star, size: 30, color: color4),
                  ],
                  const Icon(Icons.rotate_left_outlined,
                      size: 30, color: color4),
                  if (accessLevel > 1) ...[
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
