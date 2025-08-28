import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/loggerble.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/resmon.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:caldensmartfabrica/master.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TermometroPage extends StatefulWidget {
  const TermometroPage({super.key});

  @override
  TermometroPageState createState() => TermometroPageState();
}

class TermometroPageState extends State<TermometroPage> {
  final PageController _pageController = PageController(initialPage: 0);
  TextEditingController tempMaxController =
      TextEditingController(text: alertMaxTemp);
  TextEditingController tempMinController =
      TextEditingController(text: alertMinTemp);
  TextEditingController offsetController = TextEditingController();
  int _selectedIndex = 0;
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
  void initState() {
    super.initState();
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
    subscribeToVars();
  }

  void subscribeToVars() async {
    printLog('Me subscribo a vars');
    await bluetoothManager.varsUuid.setNotifyValue(true);

    final trueStatusSub =
        bluetoothManager.varsUuid.onValueReceived.listen((List<int> status) {
      var parts = utf8.decode(status).split(':');

      if (parts.length == 4) {
        setState(() {
          actualTemp = parts[0];
          offsetTemp = parts[1];
          alertMaxFlag = parts[2] == '1';
          alertMinFlag = parts[3] == '1';
        });
      }
    });

    bluetoothManager.device.cancelWhenDisconnected(trueStatusSub);
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

  void saveDataToCsv() async {
    List<List<dynamic>> rows = [
      [
        "Timestamp",
        "Temperatura",
        "Offset",
      ]
    ];
    rows.addAll(recordedData);

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFileToWrite = '${directory.path}/temp_data.csv';
    File file = File(pathOfTheFileToWrite);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)],
        text: 'CSV TEMPERATURA (Termómetro)');
  }

  @override
  void dispose() {
    _pageController.dispose();
    tempMaxController.dispose();
    tempMinController.dispose();
    offsetController.dispose();
    recordTimer?.cancel();
    super.dispose();
  }

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
                const SizedBox(height: 20),
                buildText(text: 'Temperatura Actual:\n$actualTemp °C'),
                const SizedBox(height: 20),
                buildText(text: 'Temperatura ambiente:\n$offsetTemp °C'),
                const SizedBox(height: 10),
                ElevatedButton(
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
                            recordedData
                                .add([DateTime.now(), actualTemp, offsetTemp]);
                          }
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: color0,
                  ),
                  child: Icon(
                    recording ? Icons.pause : Icons.play_arrow,
                    size: 35,
                    color: color4,
                  ),
                ),
                const SizedBox(height: 20),
                buildTextField(
                  label: 'Temperatura ambiente',
                  controller: offsetController,
                  keyboard: TextInputType.number,
                  suffixIcon: IconButton(
                    onPressed: () {
                      String p0 = offsetController.text.trim();
                      setState(() {
                        offsetTemp = p0;
                      });
                      String data =
                          '${DeviceManager.getProductCode(deviceName)}[9]($p0)';
                      printLog('Enviando: $data');
                      bluetoothManager.toolsUuid.write(data.codeUnits);
                      showToast(
                        'Temperatura ambiente enviada: $p0 °C',
                      );
                    },
                    icon: const Icon(
                      Icons.send,
                      color: color4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                buildText(
                    text:
                        'Alerta Temperatura Máxima:\n${alertMaxFlag ? 'SI' : 'NO'}'),
                const SizedBox(height: 10),
                buildTextField(
                  label: 'Temperatura Máxima de alerta',
                  controller: tempMaxController,
                  keyboard: TextInputType.number,
                  suffixIcon: IconButton(
                      onPressed: () {
                        String p0 = tempMaxController.text.trim();
                        String data =
                            '${DeviceManager.getProductCode(deviceName)}[7]($p0)';
                        printLog('Enviando: $data');
                        bluetoothManager.toolsUuid.write(data.codeUnits);
                        showToast(
                          'Temperatura máxima de alerta enviada: $p0 °C',
                        );
                      },
                      icon: const Icon(
                        Icons.send,
                        color: color4,
                      )),
                ),
                const SizedBox(height: 10),
                buildText(
                    text:
                        'Alerta Temperatura Mínima:\n${alertMinFlag ? 'SI' : 'NO'}'),
                const SizedBox(height: 10),
                buildTextField(
                  label: 'Temperatura Mínima de alerta',
                  controller: tempMinController,
                  keyboard: TextInputType.number,
                  suffixIcon: IconButton(
                      onPressed: () {
                        String p0 = tempMinController.text.trim();
                        String data =
                            '${DeviceManager.getProductCode(deviceName)}[8]($p0)';
                        printLog('Enviando: $data');
                        bluetoothManager.toolsUuid.write(data.codeUnits);
                        showToast(
                          'Temperatura mínima de alerta enviada: $p0 °C',
                        );
                      },
                      icon: const Icon(
                        Icons.send,
                        color: color4,
                      )),
                ),
                const SizedBox(height: 20),
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'Mapeo de temperatura:\n',
                      style:
                          TextStyle(color: color4, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: tempMap ? 'REALIZADO' : 'NO REALIZADO',
                      style: TextStyle(
                          color: tempMap ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                buildButton(
                  text: 'Iniciar mapeo temperatura',
                  onPressed: () {
                    String pc = DeviceManager.getProductCode(deviceName);
                    registerActivity(
                        pc,
                        DeviceManager.extractSerialNumber(deviceName),
                        'Se inicio el mapeo de temperatura en el equipo');
                    String data = '$pc[10](0)';
                    bluetoothManager.toolsUuid.write(data.codeUnits);
                    showToast('Iniciando mapeo de temperatura');
                  },
                ),
                const SizedBox(height: 5),
                buildButton(
                  text: 'Borrar mapeo temperatura',
                  onPressed: () {
                    String pc = DeviceManager.getProductCode(deviceName);
                    registerActivity(
                      pc,
                      DeviceManager.extractSerialNumber(deviceName),
                      'Se borro el mapeo de temperatura en el equipo',
                    );
                    String data = '$pc[10](1)';
                    bluetoothManager.toolsUuid.write(data.codeUnits);
                    showToast('Borrando mapeo de temperatura');
                  },
                ),
                const SizedBox(height: 20),
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

      if (hasLoggerBle) ...[
        //*- Página LOGGER -*\\
        const LoggerBlePage(),
      ],

      if (hasResourceMonitor) ...[
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
                style: const TextStyle(
                  color: color4,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
            ),
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
                            style: TextStyle(
                              color: color4,
                            ),
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
              icon: Icon(
                wifiIcon,
                color: color4,
              ),
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
                  ],
                  const Icon(Icons.thermostat, size: 30, color: color4),
                  if (accessLevel > 1) ...[
                    const Icon(Icons.person, size: 30, color: color4),
                  ],
                  if (hasLoggerBle) ...[
                    const Icon(Icons.receipt_long, size: 30, color: color4),
                  ],
                  if (hasResourceMonitor) ...[
                    const Icon(Icons.monitor, size: 30, color: color4),
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
