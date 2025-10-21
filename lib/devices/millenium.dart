import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/loggerble.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/resmon.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../aws/dynamo/dynamo.dart';
import '../master.dart';

class MilleniumPage extends StatefulWidget {
  const MilleniumPage({super.key});

  @override
  MilleniumPageState createState() => MilleniumPageState();
}

class MilleniumPageState extends State<MilleniumPage> {
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

  final bool canControl = (accessLevel >= 3 || owner == '');

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
    printLog('Valor temp: $tempValue');
    printLog('¿Encendido? $turnOn');
    subscribeTrueStatus();
  }

  void subscribeTrueStatus() async {
    printLog('Me subscribo a vars', "rojo");
    await bluetoothManager.varsUuid.setNotifyValue(true);

    final trueStatusSub =
        bluetoothManager.varsUuid.onValueReceived.listen((List<int> status) {
      var parts = utf8.decode(status).split(':');
      setState(() {
        trueStatus = parts[0] == '1';
        actualTemp = parts[1];
      });
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

  void sendTemperature(int temp) {
    String data = '${DeviceManager.getProductCode(deviceName)}[7]($temp)';
    printLog(data);
    bluetoothManager.toolsUuid.write(data.codeUnits);
  }

  void turnDeviceOn(bool on) {
    int fun = on ? 1 : 0;
    String data = '${DeviceManager.getProductCode(deviceName)}[11]($fun)';
    bluetoothManager.toolsUuid.write(data.codeUnits);
  }

  void sendRoomTemperature(String temp) {
    String data = '${DeviceManager.getProductCode(deviceName)}[8]($temp)';
    bluetoothManager.toolsUuid.write(data.codeUnits);
  }

  void startTempMap() {
    String data = '${DeviceManager.getProductCode(deviceName)}[12](0)';
    bluetoothManager.toolsUuid.write(data.codeUnits);
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
              SizedBox(
                height: 200,
                child: Image.asset(
                  'assets/extras/millenium.png',
                ),
              ),
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
                    fontSize: 30,
                  ),
                ),
              ),
              if (canControl) ...[
                const SizedBox(
                  height: 30,
                ),
                Transform.scale(
                  scale: 3.0,
                  child: Switch(
                    activeThumbColor: color4,
                    activeTrackColor: color1,
                    inactiveThumbColor: color1,
                    inactiveTrackColor: color4,
                    value: turnOn,
                    onChanged: (value) {
                      turnDeviceOn(value);
                      setState(() {
                        turnOn = value;
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(
                height: 50,
              ),
              buildText(
                text:
                    'Temperatura de corte: ${tempValue.round().toString()} °C',
              ),
              if (canControl) ...[
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
                        iconData: trueStatus ? Icons.water_drop : Icons.check,
                        thumbRadius: 28,
                      ),
                    ),
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
                      min: 15,
                      max: 70,
                    ),
                  ),
                ),
              ],
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                width: 300,
                child: !roomTempSended
                    ? buildTextField(
                        controller: roomTempController,
                        label: 'Introducir temperatura de la habitación',
                        hint: '',
                        keyboard: TextInputType.number,
                        onSubmitted: (value) {
                          registerActivity(
                            DeviceManager.getProductCode(deviceName),
                            DeviceManager.extractSerialNumber(deviceName),
                            'Se cambió la temperatura ambiente de $actualTemp°C a $value°C',
                          );
                          sendRoomTemperature(value);
                          registerTemp(
                            DeviceManager.getProductCode(deviceName),
                            DeviceManager.extractSerialNumber(deviceName),
                          );
                          showToast('Temperatura ambiente seteada');
                          setState(() {
                            roomTempSended = true;
                          });
                        },
                      )
                    : buildText(
                        text: '',
                        textSpans: [
                          TextSpan(
                            text:
                                'La temperatura ambiente ya fue seteada\npor este legajo el dia \n$tempDate',
                            style: const TextStyle(
                              color: color4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        fontSize: 20.0,
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(
                height: 30,
              ),
              buildText(
                text: '',
                textSpans: [
                  TextSpan(
                    text: 'Temperatura actual: $actualTemp °C',
                    style: const TextStyle(
                      color: color4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                fontSize: 20.0,
                textAlign: TextAlign.center,
              ),
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
                          recordedData.add([DateTime.now(), actualTemp]);
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
              const SizedBox(
                height: 10,
              ),
              if (factoryMode) ...[
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'Mapeo de temperatura:\n',
                      style: TextStyle(
                        color: color4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: tempMap ? 'REALIZADO' : 'NO REALIZADO',
                      style: TextStyle(
                        color: tempMap ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                buildButton(
                  text: 'Iniciar mapeo temperatura',
                  onPressed: () {
                    registerActivity(
                      DeviceManager.getProductCode(deviceName),
                      DeviceManager.extractSerialNumber(deviceName),
                      'Se inicio el mapeo de temperatura en el equipo',
                    );
                    startTempMap();
                    showToast('Iniciando mapeo de temperatura');
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'Distancias de control: ',
                      style: TextStyle(
                        color: color4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                buildTextField(
                  controller: distanceOnController,
                  label: 'Distancia de encendido:',
                  hint: '',
                  keyboard: TextInputType.number,
                  onSubmitted: (value) {
                    if (int.parse(value) <= 5000 && int.parse(value) >= 3000) {
                      registerActivity(
                        DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName),
                        'Se modifico la distancia de encendido',
                      );
                      putDistanceOn(
                        DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName),
                        value,
                      );
                    } else {
                      showToast('Parametros no permitidos');
                    }
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                buildTextField(
                  controller: distanceOffController,
                  label: 'Distancia de apagado:',
                  hint: '',
                  keyboard: TextInputType.number,
                  onSubmitted: (value) {
                    if (int.parse(value) <= 300 && int.parse(value) >= 100) {
                      registerActivity(
                        DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName),
                        'Se modifico la distancia de apagado',
                      );
                      putDistanceOff(
                        DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName),
                        value,
                      );
                    } else {
                      showToast('Parametros no permitidos');
                    }
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: bottomBarHeight + 20,
                  ),
                ),
              ],
            ],
          ),
        )),
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
                    height: 100,
                  ),
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
                          height: 100,
                        ),
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
