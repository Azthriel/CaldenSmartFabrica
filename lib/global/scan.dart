import 'package:caldensmartfabrica/master.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  ScanPageState createState() => ScanPageState();
}

class ScanPageState extends State<ScanPage> {
  List<BluetoothDevice> devices = [];
  List<BluetoothDevice> filteredDevices = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  late EasyRefreshController _controller;
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    filteredDevices = devices;
    _controller = EasyRefreshController(
      controlFinishRefresh: true,
    );
    List<dynamic> lista = fbData['Keywords'] ?? [];
    keywords = lista.map((item) => item.toString()).toList();
    scan();
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void scan() async {
    if (bluetoothOn) {
      printLog('Entre a escanear');
      try {
        await FlutterBluePlus.startScan(
          withKeywords: keywords,
          timeout: const Duration(seconds: 30),
          androidUsesFineLocation: true,
          continuousUpdates: false,
        );
        FlutterBluePlus.scanResults.listen((results) {
          for (ScanResult result in results) {
            if (!devices
                .any((device) => device.remoteId == result.device.remoteId)) {
              setState(() {
                devices.add(result.device);
                // devices
                //     .sort((a, b) => a.platformName.compareTo(b.platformName));
                filteredDevices = devices;
              });
            }
          }
        });
      } catch (e, stackTrace) {
        printLog('Error al escanear $e $stackTrace');
        showToast('Error al escanear, intentelo nuevamente');
      }
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      // Reset connection flag before attempting connection
      connectionFlag = false;
      
      await device.connect(timeout: const Duration(seconds: 6));
      deviceName = device.platformName;
      myDeviceid = device.remoteId.toString();

      printLog('Teoricamente estoy conectado');

      MyDevice myDevice = MyDevice();
      var conenctionSub = device.connectionState.listen(
        (BluetoothConnectionState state) {
          printLog('Estado de conexión: $state');

          switch (state) {
            case BluetoothConnectionState.disconnected:
              {
                showToast('Dispositivo desconectado');
                calibrationValues = [];
                regulationValues = [];
                toolsValues = [];
                nameOfWifi = '';
                connectionFlag = false;
                alreadySubCal = false;
                alreadySubReg = false;
                alreadySubOta = false;
                alreadySubDebug = false;
                alreadySubWork = false;
                alreadySubIO = false;
                werror = false;
                printLog(
                    'Razon: ${myDevice.device.disconnectReason?.description}');
                registerActivity(
                    DeviceManager.getProductCode(device.platformName),
                    DeviceManager.extractSerialNumber(device.platformName),
                    'Se desconecto del equipo ${device.platformName}');
                navigatorKey.currentState?.pushReplacementNamed('/menu');
                break;
              }
            case BluetoothConnectionState.connected:
              {
                if (!connectionFlag) {
                  connectionFlag = true;
                  FlutterBluePlus.stopScan();
                  myDevice.setup(device).then((valor) {
                    printLog('RETORNASHE $valor');
                    if (valor) {
                      navigatorKey.currentState
                          ?.pushReplacementNamed('/loading');
                    } else {
                      connectionFlag = false;
                      printLog('Fallo en el setup');
                      showToast('Error en el dispositivo, intente nuevamente');
                      myDevice.device.disconnect();
                    }
                  });
                } else {
                  printLog('Las chistosadas se apoderan del mundo');
                }
                break;
              }
            default:
              break;
          }
        },
      );
      device.cancelWhenDisconnected(conenctionSub, delayed: true);
    } catch (e, stackTrace) {
      if (e is FlutterBluePlusException && e.code == 133) {
        printLog('Error específico de Android con código 133: $e');
        showToast('Error de conexión, intentelo nuevamente');
      } else {
        printLog('Error al conectar: $e $stackTrace');
        showToast('Error al conectar, intentelo nuevamente');
        // handleManualError(e, stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          backgroundColor: color4,
          foregroundColor: color4,
          elevation: 0,
          title: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: color0,
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(
                  color: color3,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  hintText: "Buscar...",
                  hintStyle: TextStyle(
                    color: color3.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: color3,
                    ),
                    onPressed: () {
                      setState(() {
                        searchController.clear();
                        filteredDevices = devices;
                      });
                    },
                  ),
                ),
                autofocus: false,
                onSubmitted: (value) {
                  setState(() {
                    filteredDevices = devices
                        .where(
                          (device) =>
                              device.platformName.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                        )
                        .toList();
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return EasyRefresh(
                      controller: _controller,
                      header: const ClassicHeader(
                        dragText: 'Desliza para escanear',
                        readyText: 'Escaneando dispositivos...',
                        armedText: 'Listo para escanear',
                        processedText: 'Escaneo completo',
                        processingText: 'Escaneando dispositivos...',
                        messageText: 'Último escaneo a las %T',
                        textStyle: TextStyle(color: color0),
                        iconTheme: IconThemeData(color: color0),
                      ),
                      onRefresh: () async {
                        await Future.delayed(const Duration(seconds: 2));
                        await FlutterBluePlus.stopScan();
                        setState(() {
                          devices.clear();
                          filteredDevices.clear();
                        });
                        scan();
                        _controller.finishRefresh();
                      },
                      child: ListView.builder(
                        itemCount: filteredDevices.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            child: ListTile(
                              tileColor: color0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              leading: const Icon(Icons.bluetooth,
                                  color: color4, size: 30),
                              title: Text(
                                filteredDevices[index].platformName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color4,
                                ),
                              ),
                              subtitle: Text(
                                '${filteredDevices[index].remoteId}',
                                style: const TextStyle(
                                    color: color4, fontSize: 14),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: color4),
                              onTap: () =>
                                  connectToDevice(filteredDevices[index]),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
