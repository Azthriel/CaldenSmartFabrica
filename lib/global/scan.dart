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
            continuousUpdates: false);
        FlutterBluePlus.scanResults.listen((results) {
          for (ScanResult result in results) {
            if (!devices
                .any((device) => device.remoteId == result.device.remoteId)) {
              setState(() {
                devices.add(result.device);
                devices
                    .sort((a, b) => a.platformName.compareTo(b.platformName));
                filteredDevices = devices;
              });
            }
          }
        });
      } catch (e, stackTrace) {
        printLog('Error al escanear $e $stackTrace');
        showToast('Error al escanear, intentelo nuevamente');
        // handleManualError(e, stackTrace);
      }
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 6));
      deviceName = device.platformName;
      myDeviceid = device.remoteId.toString();

      printLog('Teoricamente estoy conectado');

      MyDevice myDevice = MyDevice();
      device.connectionState.listen((BluetoothConnectionState state) {
        printLog('Estado de conexión: $state');

        switch (state) {
          case BluetoothConnectionState.disconnected:
            {
              showToast('Dispositivo desconectado');
              calibrationValues.clear();
              regulationValues.clear();
              toolsValues.clear();
              nameOfWifi = '';
              connectionFlag = false;
              alreadySubCal = false;
              alreadySubReg = false;
              alreadySubOta = false;
              alreadySubDebug = false;
              alreadySubWork = false;
              alreadySubIO = false;
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
                    navigatorKey.currentState?.pushReplacementNamed('/loading');
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
      });
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

//! Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
          backgroundColor: color1,
          foregroundColor: color4,
          title: AnimSearchBar(
            width: MediaQuery.of(context).size.width * 0.8,
            textController: searchController,
            onSuffixTap: () {
              setState(() {
                searchController.clear();
                filteredDevices = devices;
              });
            },
            onSubmitted: (value) {
              setState(() {
                filteredDevices = devices
                    .where((device) => device.platformName
                        .toLowerCase()
                        .contains(value.toLowerCase()))
                    .toList();
              });
            },
            rtl: false,
            autoFocus: true,
            helpText: "",
            suffixIcon: const Icon(
              Icons.clear,
              color: color3,
            ),
            prefixIcon: toggle == 1
                ? const Icon(
                    Icons.arrow_back_ios,
                    color: color3,
                  )
                : const Icon(
                    Icons.search,
                    color: color3,
                  ),
            animationDurationInMilli: 400,
            color: color0,
            textFieldColor: color0,
            searchIconColor: color3,
            textFieldIconColor: color3,
            style: const TextStyle(
              color: color3,
            ),
            onTap: () {
              setState(() {
                toggle = 1;
              });
            },
          )),
      body: EasyRefresh(
        controller: _controller,
        header: const ClassicHeader(
          dragText: 'Desliza para reescanear',
          readyText: 'Reescaneando dispositivos...',
          processedText: 'Reescaneo completo',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: ListTile(
                tileColor: color0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                leading: const Icon(Icons.bluetooth, color: color4, size: 30),
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
                  style: const TextStyle(color: color4, fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right, color: color4),
                onTap: () => connectToDevice(filteredDevices[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}
