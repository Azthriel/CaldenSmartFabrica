import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../aws/dynamo/dynamo.dart';
import '../aws/dynamo/dynamo_certificates.dart';
import '../master.dart';

class CalefactoresPage extends StatefulWidget {
  const CalefactoresPage({super.key});

  @override
  CalefactoresPageState createState() => CalefactoresPageState();
}

class CalefactoresPageState extends State<CalefactoresPage> {
  TextEditingController textController = TextEditingController();

  final TextEditingController roomTempController = TextEditingController();
  final TextEditingController distanceOnController =
      TextEditingController(text: distanceOn);
  final TextEditingController distanceOffController =
      TextEditingController(text: distanceOff);
  final PageController _pageController = PageController(initialPage: 0);

  int _selectedIndex = 0;

  bool ignite = false;
  bool recording = false;

  List<List<dynamic>> recordedData = [];
  Timer? recordTimer;

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
    roomTempController.dispose();
    distanceOnController.dispose();
    distanceOffController.dispose();
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

  void sendDataToDevice() async {
    String dataToSend = textController.text;
    String data = '${DeviceManager.getProductCode(deviceName)}[4]($dataToSend)';
    try {
      await myDevice.toolsUuid.write(data.codeUnits);
    } catch (e) {
      printLog(e);
    }
  }

  void sendTemperature(int temp) {
    String data = '${DeviceManager.getProductCode(deviceName)}[7]($temp)';
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void turnDeviceOn(bool on) {
    int fun = on ? 1 : 0;
    String data = '${DeviceManager.getProductCode(deviceName)}[11]($fun)';
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void sendRoomTemperature(String temp) {
    String data = '${DeviceManager.getProductCode(deviceName)}[8]($temp)';
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void startTempMap() {
    String data = '${DeviceManager.getProductCode(deviceName)}[12](0)';
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void saveDataToCsv() async {
    List<List<dynamic>> rows = [
      [
        "Timestamp",
        "Temperatura",
      ]
    ];
    rows.addAll(recordedData);

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFileToWrite = '${directory.path}/temp_data.csv';
    File file = File(pathOfTheFileToWrite);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'CSV TEMPERATURA');
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
      Scaffold(
        backgroundColor: const Color(0xff190019),
        body: Center(
            child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  text: turnOn
                      ? trueStatus
                          ? 'Calentando'
                          : 'Encendido'
                      : 'Apagado',
                  style: TextStyle(
                      color: turnOn
                          ? trueStatus
                              ? Colors.amber[600]
                              : Colors.green
                          : Colors.red,
                      fontSize: 30),
                ),
              ),
              const SizedBox(height: 30),
              Transform.scale(
                scale: 3.0,
                child: Switch(
                  activeColor: const Color(0xfffbe4d8),
                  activeTrackColor: const Color(0xff854f6c),
                  inactiveThumbColor: const Color(0xff854f6c),
                  inactiveTrackColor: const Color(0xfffbe4d8),
                  value: turnOn,
                  onChanged: (value) {
                    turnDeviceOn(value);
                    setState(() {
                      turnOn = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 50),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Temperatura de corte: ',
                      style: TextStyle(
                        color: Color(0xfffbe4d8),
                        fontSize: 25,
                      ),
                    ),
                    TextSpan(
                      text: tempValue.round().toString(),
                      style: const TextStyle(
                        fontSize: 30,
                        color: Color(0xfffbe4d8),
                      ),
                    ),
                    const TextSpan(
                      text: '°C',
                      style: TextStyle(
                        fontSize: 30,
                        color: Color(0xfffbe4d8),
                      ),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    trackHeight: 50.0,
                    thumbColor: const Color(0xfffbe4d8),
                    thumbShape: IconThumbSlider(
                        iconData: trueStatus
                            ? DeviceManager.getProductCode(deviceName) ==
                                    '027000'
                                ? Icons.local_fire_department
                                : Icons.flash_on_rounded
                            : Icons.check,
                        thumbRadius: 25)),
                child: Slider(
                  value: tempValue,
                  onChanged: (value) {
                    setState(() {
                      tempValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    printLog(value);
                    sendTemperature(value.round());
                  },
                  min: 10,
                  max: 40,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                  width: 300,
                  child: !roomTempSended
                      ? TextField(
                          style: const TextStyle(color: Color(0xfffbe4d8)),
                          keyboardType: TextInputType.number,
                          controller: roomTempController,
                          decoration: const InputDecoration(
                            labelText:
                                'Introducir temperatura de la habitación',
                            labelStyle: TextStyle(color: Color(0xfffbe4d8)),
                          ),
                          onSubmitted: (value) {
                            registerActivity(
                                DeviceManager.getProductCode(deviceName),
                                DeviceManager.extractSerialNumber(deviceName),
                                'Se cambio la temperatura ambiente de $actualTemp°C a $value°C');
                            sendRoomTemperature(value);
                            registerTemp(
                                DeviceManager.getProductCode(deviceName),
                                DeviceManager.extractSerialNumber(deviceName));
                            showToast('Temperatura ambiente seteada');
                            setState(() {
                              roomTempSended = true;
                            });
                          },
                        )
                      : Text(
                          'La temperatura ambiente ya fue seteada\npor este legajo el dia \n$tempDate',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xfffbe4d8),
                            fontSize: 20,
                          ),
                        )),
              const SizedBox(height: 30),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Temperatura actual: ',
                      style: TextStyle(
                        color: Color(0xfffbe4d8),
                        fontSize: 20,
                      ),
                    ),
                    TextSpan(
                      text: actualTemp,
                      style: const TextStyle(
                        color: Color(0xFFdfb6b2),
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    const TextSpan(
                      text: '°C ',
                      style: TextStyle(
                        color: Color(0xFFdfb6b2),
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IconButton(
                onPressed: () {
                  setState(() {
                    recording = !recording;
                  });
                  if (!recording) {
                    recordTimer?.cancel();
                    saveDataToCsv();
                    recordedData.clear();
                  } else {
                    recordTimer = Timer.periodic(
                      const Duration(seconds: 1),
                      (Timer t) {
                        if (recording) {
                          recordedData.add([DateTime.now(), actualTemp]);
                        }
                      },
                    );
                  }
                },
                icon: recording
                    ? const Icon(
                        Icons.pause,
                        size: 35,
                        color: Color(0xffdfb6b2),
                      )
                    : const Icon(
                        Icons.play_arrow,
                        size: 35,
                        color: Color(0xffdfb6b2),
                      ),
              ),
              if (factoryMode) ...[
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Mapeo de temperatura:\n',
                        style: TextStyle(
                          color: Color(0xfffbe4d8),
                          fontSize: 20,
                        ),
                      ),
                      TextSpan(
                        text: tempMap ? 'REALIZADO' : 'NO REALIZADO',
                        style: TextStyle(
                          color: tempMap
                              ? const Color(0xff854f6c)
                              : const Color(0xffFF0000),
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    registerActivity(
                        DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName),
                        'Se inicio el mapeo de temperatura en el equipo');
                    startTempMap();
                    showToast('Iniciando mapeo de temperatura');
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                  ),
                  child: const Text('Iniciar mapeo temperatura'),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                    onPressed: () {
                      registerActivity(
                          DeviceManager.getProductCode(deviceName),
                          DeviceManager.extractSerialNumber(deviceName),
                          'Se mando el ciclado de la válvula de este equipo');
                      String data =
                          '${DeviceManager.getProductCode(deviceName)}[13](1000#5)';
                      myDevice.toolsUuid.write(data.codeUnits);
                    },
                    child: const Text('Ciclado fijo')),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final TextEditingController cicleController =
                            TextEditingController();
                        final TextEditingController timeController =
                            TextEditingController();
                        return AlertDialog(
                          title: const Center(
                            child: Text(
                              'Especificar parametros del ciclador:',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  style: const TextStyle(color: Colors.black),
                                  controller: cicleController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Ingrese cantidad de ciclos',
                                    hintText: 'Certificación: 1000',
                                    labelStyle: TextStyle(color: Colors.black),
                                    hintStyle: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  style: const TextStyle(color: Colors.black),
                                  controller: timeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Ingrese duración de los ciclos',
                                    hintText: 'Recomendado: 1000',
                                    suffixText: '(mS)',
                                    suffixStyle: TextStyle(
                                      color: Colors.black,
                                    ),
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                    ),
                                    hintStyle: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                navigatorKey.currentState!.pop();
                              },
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                int cicle = int.parse(cicleController.text) * 2;
                                registerActivity(
                                    DeviceManager.getProductCode(deviceName),
                                    DeviceManager.extractSerialNumber(
                                        deviceName),
                                    'Se mando el ciclado de la válvula de este equipo\nMilisegundos: ${timeController.text}\nIteraciones:$cicle');
                                String data =
                                    '${DeviceManager.getProductCode(deviceName)}[13](${timeController.text}#$cicle)';
                                myDevice.toolsUuid.write(data.codeUnits);
                                navigatorKey.currentState!.pop();
                              },
                              child: const Text('Iniciar proceso'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                  ),
                  child: const Text('Configurar ciclado'),
                ),
                if (DeviceManager.getProductCode(deviceName) == '027000') ...[
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final TextEditingController timeController =
                              TextEditingController();
                          return AlertDialog(
                            title: const Center(
                              child: Text(
                                'Especificar parametros de la apertura temporizada:',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: TextField(
                                    style: const TextStyle(color: Colors.black),
                                    controller: timeController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Ingrese cantidad de milisegundos',
                                      labelStyle:
                                          TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  navigatorKey.currentState!.pop();
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  registerActivity(
                                      DeviceManager.getProductCode(deviceName),
                                      DeviceManager.extractSerialNumber(
                                          deviceName),
                                      'Se mando el temporizado de apertura');
                                  String data =
                                      '${DeviceManager.getProductCode(deviceName)}[14](${timeController.text.trim()})';
                                  myDevice.toolsUuid.write(data.codeUnits);
                                  navigatorKey.currentState!.pop();
                                },
                                child: const Text('Iniciar proceso'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Configurar Apertura\nTemporizada',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onLongPressStart: (LongPressStartDetails a) async {
                      setState(() {
                        ignite = true;
                      });
                      while (ignite) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (!ignite) break;
                        String data = '027000_IOT[15](1)';
                        myDevice.toolsUuid.write(data.codeUnits);
                        printLog(data);
                      }
                    },
                    onLongPressEnd: (LongPressEndDetails a) {
                      setState(() {
                        ignite = false;
                      });
                      String data = '027000_IOT[15](0)';
                      myDevice.toolsUuid.write(data.codeUnits);
                      printLog(data);
                    },
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Chispero'),
                    ),
                  ),
                ],
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Distancias de control: ',
                  style: TextStyle(
                    color: Color(0xfffbe4d8),
                    fontSize: 20,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    style: const TextStyle(
                      color: Color(0xFFdfb6b2),
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.number,
                    controller: distanceOnController,
                    decoration: const InputDecoration(
                      labelText: 'Distancia de encendido:',
                      labelStyle: TextStyle(color: Color(0xfffbe4d8)),
                      suffixText: 'Metros',
                      suffixStyle: TextStyle(color: Color(0xfffbe4d8)),
                    ),
                    onSubmitted: (value) {
                      if (int.parse(value) <= 5000 &&
                          int.parse(value) >= 3000) {
                        registerActivity(
                            DeviceManager.getProductCode(deviceName),
                            DeviceManager.extractSerialNumber(deviceName),
                            'Se modifico la distancia de encendido');
                        putDistanceOn(
                            service,
                            DeviceManager.getProductCode(deviceName),
                            DeviceManager.extractSerialNumber(deviceName),
                            value);
                      } else {
                        showToast('Parametros no permitidos');
                      }
                    },
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    style: const TextStyle(
                      color: Color(0xFFdfb6b2),
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.number,
                    controller: distanceOffController,
                    decoration: const InputDecoration(
                      labelText: 'Distancia de apagado:',
                      labelStyle: TextStyle(color: Color(0xfffbe4d8)),
                      suffixText: 'Metros',
                      suffixStyle: TextStyle(color: Color(0xfffbe4d8)),
                    ),
                    onSubmitted: (value) {
                      if (int.parse(value) <= 300 && int.parse(value) >= 100) {
                        registerActivity(
                            DeviceManager.getProductCode(deviceName),
                            DeviceManager.extractSerialNumber(deviceName),
                            'Se modifico la distancia de apagado');
                        putDistanceOff(
                            service,
                            DeviceManager.getProductCode(deviceName),
                            DeviceManager.extractSerialNumber(deviceName),
                            value);
                      } else {
                        showToast('Parametros no permitidos');
                      }
                    },
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ],
          ),
        )),
      ),

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
