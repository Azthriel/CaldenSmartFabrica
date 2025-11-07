import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:caldensmartfabrica/secret.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:msgpack_dart/msgpack_dart.dart';

//! VARIABLES !\\

//!-------------------------VERSION NUMBER-------------------------!\\
String appVersionNumber = '1.0.45';
//!-------------------------VERSION NUMBER-------------------------!\\

//*-Colores-*\\
const Color color0 = Color(0xFF22222E);
const Color color1 = Color(0xFF393A5A);
const Color color2 = Color(0xFF706F8E);
const Color color3 = Color(0xFFADA9BA);
const Color color4 = Color(0xFFE9E9E9);
//*-Colores-*\\

//*-Estado de app-*\\
const bool xProfileMode = bool.fromEnvironment('dart.vm.profile');
const bool xReleaseMode = bool.fromEnvironment('dart.vm.product');
const bool xDebugMode = !xProfileMode && !xReleaseMode;
//*-Estado de app-*\\

//*-Key de la app (uso de navegación y contextos)-*\\
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//*-Key de la app (uso de navegación y contextos)-*\\

//*-Datos del dispositivo al que te conectaste-*\\
String deviceName = '';
String softwareVersion = '';
String hardwareVersion = '';
bool userConnected = false;
bool connectionFlag = false;
bool distanceControlActive = false;
bool awsInit = false;
String deviceResponseMqtt = '';
bool labProcessFinished = false;
//*-Datos del dispositivo al que te conectaste-*\\

//*-Usuario conectado-*\\
String legajoConectado = '';
int accessLevel = 0;
String completeName = '';
//*-Usuario conectado-*\\

//*-Relacionado al wifi-*\\
List<WiFiAccessPoint> _wifiNetworksList = [];
String? _currentlySelectedSSID;
Map<String, String?> _wifiPasswordsMap = {};
FocusNode wifiPassNode = FocusNode();
bool _scanInProgress = false;
int? _expandedIndex;
String errorMessage = '';
String errorSintax = '';
String nameOfWifi = '';
bool isWifiConnected = false;
bool wifilogoConnected = false;
bool atemp = false;
String textState = '';
bool werror = false;
IconData wifiIcon = Icons.wifi_off;
MaterialColor statusColor = Colors.grey;
bool isConnectedToAWS = false;
//*-Relacionado al wifi-*\\

//*-Relacionado al ble-*\\
BluetoothManager bluetoothManager = BluetoothManager();
late bool factoryMode;
List<int> calibrationValues = [];
List<int> regulationValues = [];
List<int> toolsValues = [];
List<int> debugValues = [];
List<int> workValues = [];
List<int> infoValues = [];
List<int> varsValues = [];
List<int> ioValues = [];
bool bluetoothOn = true;
bool alreadySubReg = false;
bool alreadySubCal = false;
bool alreadySubOta = false;
bool alreadySubDebug = false;
bool alreadySubWork = false;
bool alreadySubIO = false;
List<String> keywords = [];
bool alreadySubWifi = false;
Map<String, Map<String, dynamic>> wifiAvailableData = {};
//*-Relacionado al ble-*\\

//*-Monitoreo Localizacion y Bluetooth*-\\
Timer? locationTimer;
Timer? bluetoothTimer;
bool bleFlag = false;
//*-Monitoreo Localizacion y Bluetooth*-\\

//*-Sistema de owners-*\\
String owner = '';
String distanceOn = '';
String distanceOff = '';
String secAdmDate = '';
String atDate = '';
List<String> secondaryAdmins = [];

//*-Sistema de owners-*\\

//*-CurvedNavigationBar-*\\
typedef LetIndexPage = bool Function(int value);
//*-CurvedNavigationBar-*\\

//*-AnimSearchBar-*\\
int toggle = 0;
String textFieldValue = '';
//*-AnimSearchBar-*\\

//*-Calefactores-*\\
bool turnOn = false;
bool trueStatus = false;
bool nightMode = false;
double distOnValue = 0.0;
double distOffValue = 0.0;
bool tempMap = false;
double tempValue = 0.0;
String actualTemp = '';
bool hasSensor = false;
String offsetTemp = '';
bool manualControl = false;
bool hasSpark = false;
//*-Calefactores-*\\

//*- Roller -*\\
int actualPositionGrades = 0;
int actualPosition = 0;
bool rollerMoving = false;
int workingPosition = 0;
String rollerlength = '';
String rollerPolarity = '';
String contrapulseTime = '';
String rollerRPM = '';
String rollerMicroStep = '';
String rollerIMAX = '';
String rollerIRMSRUN = '';
String rollerIRMSHOLD = '';
bool rollerFreewheeling = false;
String rollerTPWMTHRS = '';
String rollerTCOOLTHRS = '';
String rollerSGTHRS = '';
//*- Roller -*\\

//*-Domótica-*\\
bool burneoDone = false;
List<String> tipo = [];
List<String> estado = [];
List<bool> alertIO = [];
List<String> common = [];
//*-Domótica-*\\

//*-Relé-*\\
String energyTimer = '';
bool hasEntry = false;
//*-Relé-*\\

//*-Fetch data from firestore-*\\
Map<String, dynamic> fbData = {};
//*-Fetch data from firestore-*\\

//*-Registro temperatura ambiente enviada-*\\
bool roomTempSended = false;
String tempDate = '';
//*-Registro temperatura ambiente enviada-*\\

//*- altura de la barra -*\\
double bottomBarHeight = kBottomNavigationBarHeight;
//*- altura de la barra -*\\

//*-Termómetro-*\\
bool alertMaxFlag = false;
bool alertMinFlag = false;
String alertMaxTemp = '';
String alertMinTemp = '';
Map<String, String> historicTemp = {};
bool historicTempPremium = false;
//*-Termómetro-*\\

//*-Fluttertoast-*\\
late FToast fToast;
//*-Fluttertoast-*\\

//*-WiFi Data Notifier Instance-*\\
WiFiDataNotifier wifiDataNotifier = WiFiDataNotifier();
WiFiStoredNotifier wifiStoredNotifier = WiFiStoredNotifier();
//*-WiFi Data Notifier Instance-*\\

//*-Riego-*\\
bool riegoActive = false;
String riegoMaster = '';
//*-Riego-*\\

// // -------------------------------------------------------------------------------------------------------------\\ \\

//! FUNCIONES !\\

///*-Permite hacer prints seguros, solo en modo debug-*\\\
///
///Colores permitidos para [color] son:
///rojo, verde, amarillo, azul, magenta y cyan.
///
///Si no colocas ningún color se pondra por defecto...
void printLog(var text, [String? color]) {
  if (color != null) {
    switch (color.toLowerCase()) {
      case 'rojo':
        color = '\x1B[31m';
        break;
      case 'verde':
        color = '\x1B[32m';
        break;
      case 'amarillo':
        color = '\x1B[33m';
        break;
      case 'azul':
        color = '\x1B[34m';
        break;
      case 'magenta':
        color = '\x1B[35m';
        break;
      case 'cyan':
        color = '\x1B[36m';
        break;
      case 'reset':
        color = '\x1B[0m';
        break;
      default:
        color = '\x1B[0m';
        break;
    }
  } else {
    color = '\x1B[0m';
  }
  if (xDebugMode) {
    if (Platform.isAndroid) {
      // ignore: avoid_print
      print('${color}PrintData: $text\x1B[0m');
    } else {
      // ignore: avoid_print
      print("PrintData: $text");
    }
  }
}
//*-Permite hacer prints seguros, solo en modo debug-*\\

//*-Funciones diversas-*\\
void showToast(String message) {
  printLog('Toast: $message');
  fToast.removeCustomToast();
  Widget toast = Container(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25.0),
      color: color3,
      border: Border.all(
        color: color2,
        width: 1.0,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/Dragon.png',
          width: 24,
          height: 24,
        ),
        const SizedBox(
          width: 12.0,
        ),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: color0,
            ),
            softWrap: true,
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  fToast.showToast(
    child: toast,
    gravity: ToastGravity.BOTTOM,
    toastDuration: const Duration(seconds: 2),
  );
}

String generateRandomNumbers(int length) {
  Random random = Random();
  String result = '';

  for (int i = 0; i < length; i++) {
    result += random.nextInt(10).toString();
  }

  return result;
}

Future<void> sendWhatsAppMessage(String phoneNumber, String message) async {
  var whatsappUrl =
      "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeFull(message)}";
  Uri uri = Uri.parse(whatsappUrl);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    showToast('No se pudo abrir WhatsApp');
  }
}

void launchEmail(String mail, String asunto, String cuerpo) async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: mail,
    query: encodeQueryParameters(
        <String, String>{'subject': asunto, 'body': cuerpo}),
  );

  if (await canLaunchUrl(emailLaunchUri)) {
    await launchUrl(emailLaunchUri);
  } else {
    showToast('No se pudo abrir el correo electrónico');
  }
}

String encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

void launchWebURL(String url) async {
  var uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    printLog('No se pudo abrir $url');
  }
}

//*-Funciones diversas-*\\

//*-Gestión de errores en app-*\\
String generateErrorReport(FlutterErrorDetails details) {
  String error =
      'Error: ${details.exception}\nStacktrace: ${details.stack}\nContexto: ${details.context}';
  printLog(error, "amarillo");
  return error;
}

void sendReportOnWhatsApp(String filePath) async {
  const text = 'Attached is the error report';
  final file = File(filePath);
  await Share.shareXFiles([XFile(file.path)], text: text);
}
//*-Gestión de errores en app-*\\

//*-Wifi, menú y scanner-*\\
List<Map<String, dynamic>> _buildWifiListFromBLE() {
  List<Map<String, dynamic>> wifiList = [];

  printLog(
      "Construyendo lista WiFi desde datos BLE. Total redes: ${wifiAvailableData.length}");

  wifiAvailableData.forEach((ssid, data) {
    // printLog("Procesando red: $ssid con datos: $data");
    if (data.containsKey('rssi')) {
      int rssi = data['rssi'] as int;
      // Si no tiene 'enc', asumir que tiene contraseña (enc = 3 por defecto)
      int encryption = data.containsKey('enc') ? data['enc'] as int : 3;

      // Solo agregar redes con señal decente (>= -90 dBm para ver más redes)
      if (rssi >= -90) {
        wifiList.add({
          'ssid': ssid,
          'rssi': rssi,
          'encryption': encryption,
          'hasPassword': encryption > 0,
        });
        // printLog("Red agregada: $ssid, RSSI: $rssi, Enc: $encryption");
      } else {
        // printLog("Red descartada por señal débil: $ssid, RSSI: $rssi");
      }
    } else {
      // printLog("Red descartada por falta de RSSI: $ssid");
    }
  });

  // Ordenar por señal (rssi más alto primero)
  wifiList.sort((a, b) => (b['rssi'] as int).compareTo(a['rssi'] as int));

  printLog("Lista final construida con ${wifiList.length} redes");

  return wifiList;
}

Future<void> sendWifitoBle(String ssid, String pass) async {
  if (bluetoothManager.newGeneration) {
    var data = {
      "connect": {"ssid": ssid, "pass": pass}
    };

    List<int> messagePackData = serialize(data);
    printLog("Enviando datos WiFi via BLE: $data");
    await bluetoothManager.wifiDataUuid.write(messagePackData);
  } else {
    String value = '$ssid#$pass';
    String deviceCommand = DeviceManager.getProductCode(deviceName);
    printLog(deviceCommand);
    String dataToSend = '$deviceCommand[1]($value)';
    printLog(dataToSend);
    try {
      await bluetoothManager.toolsUuid.write(dataToSend.codeUnits);
      printLog('Se mando el wifi ANASHE');
    } catch (e) {
      printLog('Error al conectarse a Wifi $e');
    }
  }
  ssid != 'DSC' ? atemp = true : null;
}

Future<List<WiFiAccessPoint>> _fetchWiFiNetworks() async {
  if (_scanInProgress) return _wifiNetworksList;

  _scanInProgress = true;

  try {
    if (await Permission.locationWhenInUse.request().isGranted) {
      final canScan =
          await WiFiScan.instance.canStartScan(askPermissions: true);
      if (canScan == CanStartScan.yes) {
        final results = await WiFiScan.instance.startScan();
        if (results == true) {
          final networks = await WiFiScan.instance.getScannedResults();

          if (networks.isNotEmpty) {
            final uniqueResults = <String, WiFiAccessPoint>{};
            for (var network in networks) {
              if (network.ssid.isNotEmpty) {
                uniqueResults[network.ssid] = network;
              }
            }

            _wifiNetworksList = uniqueResults.values.toList()
              ..sort((a, b) => b.level.compareTo(a.level));
          }
        }
      } else {
        printLog('No se puede iniciar el escaneo.');
      }
    } else {
      printLog('Permiso de ubicación denegado.');
    }
  } catch (e) {
    printLog('Error durante el escaneo de WiFi: $e');
  } finally {
    _scanInProgress = false;
  }

  return _wifiNetworksList;
}

void wifiText(BuildContext context) {
  bool isAddingNetwork = false;
  String manualSSID = '';
  String manualPassword = '';
  bool obscureText = true;

  // Si tiene variables WiFi, leer datos iniciales y luego suscribirse
  if (bluetoothManager.hasWifiService) {
    readInitialWifiData();
    if (!alreadySubWifi) {
      subscribeToWifiData();
    }
    // Leer también las redes guardadas
    readStoredWifiNetworks();
  }

  showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          // Widget para construir la pestaña de redes disponibles
          Widget buildAvailableNetworksTab() {
            // Si tiene variables WiFi, usar datos BLE en cualquier plataforma
            if (bluetoothManager.hasWifiService) {
              return ListenableBuilder(
                listenable: wifiDataNotifier,
                builder: (context, child) {
                  final wifiListFromBLE = _buildWifiListFromBLE();
                  final hasData = wifiDataNotifier.hasData();

                  if (!hasData) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: color4),
                            SizedBox(height: 10),
                            Text(
                              'Cargando redes WiFi...',
                              style: TextStyle(color: color4, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (wifiListFromBLE.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'No se encontraron redes WiFi',
                          style: TextStyle(color: color4, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.maxFinite,
                    height: 200.0,
                    child: ListView.builder(
                      itemCount: wifiListFromBLE.length,
                      itemBuilder: (context, index) {
                        final networkData = wifiListFromBLE[index];
                        String ssid = networkData['ssid'];
                        int rssi = networkData['rssi'];
                        bool hasPassword = networkData['hasPassword'];

                        return ExpansionTile(
                          initiallyExpanded: _expandedIndex == index,
                          onExpansionChanged: (bool open) {
                            if (open) {
                              wifiPassNode.requestFocus();
                              setState(() {
                                _expandedIndex = index;
                              });
                            } else {
                              setState(() {
                                _expandedIndex = null;
                              });
                            }
                          },
                          leading: Icon(
                            rssi >= -30
                                ? Icons.signal_wifi_4_bar
                                : rssi >= -67
                                    ? Icons.signal_wifi_4_bar
                                    : rssi >= -70
                                        ? Icons.network_wifi_3_bar
                                        : rssi >= -80
                                            ? Icons.network_wifi_2_bar
                                            : Icons.signal_wifi_0_bar,
                            color: color4,
                          ),
                          title: Text(
                            ssid,
                            style: const TextStyle(color: color4),
                          ),
                          backgroundColor: color1,
                          collapsedBackgroundColor: color1,
                          textColor: color4,
                          iconColor: color4,
                          collapsedIconColor: color4,
                          children: hasPassword
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.lock,
                                          color: color4,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8.0),
                                        Expanded(
                                          child: TextField(
                                            focusNode: wifiPassNode,
                                            style:
                                                const TextStyle(color: color4),
                                            decoration: InputDecoration(
                                              hintText: 'Escribir contraseña',
                                              hintStyle: const TextStyle(
                                                  color: color3),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide:
                                                    BorderSide(color: color4),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide:
                                                    BorderSide(color: color4),
                                              ),
                                              border:
                                                  const UnderlineInputBorder(
                                                borderSide:
                                                    BorderSide(color: color4),
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  obscureText
                                                      ? Icons.visibility
                                                      : Icons.visibility_off,
                                                  color: color4,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    obscureText = !obscureText;
                                                  });
                                                },
                                              ),
                                            ),
                                            obscureText: obscureText,
                                            onChanged: (value) {
                                              setState(() {
                                                _currentlySelectedSSID = ssid;
                                                _wifiPasswordsMap[ssid] = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                              : [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _currentlySelectedSSID = ssid;
                                          _wifiPasswordsMap[ssid] = '';
                                        });
                                        sendWifitoBle(ssid, '');
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        'Conectar (Red abierta)',
                                        style: TextStyle(color: color4),
                                      ),
                                    ),
                                  ),
                                ],
                        );
                      },
                    ),
                  );
                },
              );
            }

            // Si NO tiene variables WiFi
            if (Platform.isAndroid) {
              // Android: usar la librería de escaneo WiFi
              if (!_scanInProgress && _wifiNetworksList.isEmpty) {
                _fetchWiFiNetworks().then((wifiNetworks) {
                  setState(() {
                    _wifiNetworksList = wifiNetworks;
                  });
                });
              }

              return _wifiNetworksList.isEmpty && _scanInProgress
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(color: color4),
                      ),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      height: 200.0,
                      child: ListView.builder(
                        itemCount: _wifiNetworksList.length,
                        itemBuilder: (context, index) {
                          final network = _wifiNetworksList[index];
                          int nivel = network.level;
                          return nivel >= -80
                              ? ExpansionTile(
                                  initiallyExpanded: _expandedIndex == index,
                                  onExpansionChanged: (bool open) {
                                    if (open) {
                                      wifiPassNode.requestFocus();
                                      setState(() {
                                        _expandedIndex = index;
                                      });
                                    } else {
                                      setState(() {
                                        _expandedIndex = null;
                                      });
                                    }
                                  },
                                  leading: Icon(
                                    nivel >= -30
                                        ? Icons.signal_wifi_4_bar
                                        : nivel >= -67
                                            ? Icons.signal_wifi_4_bar
                                            : nivel >= -70
                                                ? Icons.network_wifi_3_bar
                                                : nivel >= -80
                                                    ? Icons.network_wifi_2_bar
                                                    : Icons.signal_wifi_0_bar,
                                    color: color4,
                                  ),
                                  title: Text(
                                    network.ssid,
                                    style: const TextStyle(color: color4),
                                  ),
                                  backgroundColor: color1,
                                  collapsedBackgroundColor: color1,
                                  textColor: color4,
                                  iconColor: color4,
                                  collapsedIconColor: color4,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.lock,
                                            color: color4,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8.0),
                                          Expanded(
                                            child: TextField(
                                              focusNode: wifiPassNode,
                                              style: const TextStyle(
                                                  color: color4),
                                              decoration: InputDecoration(
                                                hintText: 'Escribir contraseña',
                                                hintStyle: const TextStyle(
                                                    color: color3),
                                                enabledBorder:
                                                    const UnderlineInputBorder(
                                                  borderSide:
                                                      BorderSide(color: color4),
                                                ),
                                                focusedBorder:
                                                    const UnderlineInputBorder(
                                                  borderSide:
                                                      BorderSide(color: color4),
                                                ),
                                                border:
                                                    const UnderlineInputBorder(
                                                  borderSide:
                                                      BorderSide(color: color4),
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    obscureText
                                                        ? Icons.visibility
                                                        : Icons.visibility_off,
                                                    color: color4,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      obscureText =
                                                          !obscureText;
                                                    });
                                                  },
                                                ),
                                              ),
                                              obscureText: obscureText,
                                              onChanged: (value) {
                                                setState(() {
                                                  _currentlySelectedSSID =
                                                      network.ssid;
                                                  _wifiPasswordsMap[
                                                      network.ssid] = value;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    );
            } else {
              // iOS sin variables WiFi: solo mostrar mensaje para agregar manualmente
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        color: color3,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Escaneo WiFi no disponible en iOS',
                        style: TextStyle(
                            color: color4,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Usa "Agregar Red" para conectar manualmente',
                        style: TextStyle(color: color3, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          // Widget para construir la pestaña de redes guardadas
          Widget buildStoredNetworksTab() {
            return ListenableBuilder(
              listenable: wifiStoredNotifier,
              builder: (context, child) {
                final storedNetworks = wifiStoredNotifier.getStoredNetworks();

                if (storedNetworks.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'No hay redes guardadas',
                        style: TextStyle(color: color3, fontSize: 12),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: storedNetworks.length,
                    itemBuilder: (context, index) {
                      String ssid = storedNetworks.keys.elementAt(index);
                      String password = storedNetworks[ssid]!;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: color1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color2,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color0.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Información de la red
                              Row(
                                children: [
                                  const Icon(
                                    Icons.wifi_lock,
                                    color: color4,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ssid,
                                          style: const TextStyle(
                                            color: color4,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Contraseña guardada',
                                          style: TextStyle(
                                            color: color3,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Botones en la parte inferior
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.green.withValues(alpha: 0.2),
                                        foregroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: const BorderSide(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(
                                        Icons.wifi,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Conectar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () {
                                        sendWifitoBle(ssid, password);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.red.withValues(alpha: 0.2),
                                        foregroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: const BorderSide(
                                            color: Colors.red,
                                            width: 1,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Eliminar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () {
                                        showAlertDialog(
                                          context,
                                          false,
                                          const Text(
                                            'Confirmar eliminación',
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                          Text(
                                            '¿Estás seguro de que quieres eliminar la red "$ssid"?',
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                          [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                'Cancelar',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                deleteStoredWifiNetwork(ssid);
                                                Navigator.of(context).pop();
                                                showToast(
                                                    'Red eliminada: $ssid');
                                              },
                                              child: const Text(
                                                'Eliminar',
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }

          // Función para construir la vista principal con TabBar
          Widget buildMainView() {
            // Determinar el número de tabs basado en bluetoothManager.hasWifiService
            final int tabCount = bluetoothManager.hasWifiService ? 2 : 1;
            final List<Tab> tabs = [
              const Tab(
                icon: Icon(Icons.wifi_find),
                text: 'Disponibles',
              ),
              if (bluetoothManager.hasWifiService)
                const Tab(
                  icon: Icon(Icons.wifi_lock),
                  text: 'Guardadas',
                ),
            ];
            final List<Widget> tabViews = [
              buildAvailableNetworksTab(),
              if (bluetoothManager.hasWifiService) buildStoredNetworksTab(),
            ];

            return DefaultTabController(
              length: tabCount,
              child: AlertDialog(
                backgroundColor: color1,
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Estado: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: color4,
                                ),
                              ),
                              Text(
                                isWifiConnected ? 'Conectado' : 'Desconectado',
                                style: TextStyle(
                                  color: isWifiConnected
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (werror) ...[
                      const SizedBox(height: 10),
                      Text.rich(
                        TextSpan(
                          text: 'Error: $errorMessage',
                          style: const TextStyle(
                            fontSize: 10,
                            color: color4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text.rich(
                        TextSpan(
                          text: 'Sintax: $errorSintax',
                          style: const TextStyle(
                            fontSize: 10,
                            color: color4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        const Text.rich(
                          TextSpan(
                            text: 'Red actual: ',
                            style: TextStyle(
                              fontSize: 20,
                              color: color4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          nameOfWifi,
                          style: const TextStyle(
                            fontSize: 20,
                            color: color4,
                          ),
                        ),
                      ]),
                    ),
                    if (isWifiConnected) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          sendWifitoBle('DSC', 'DSC');
                          Navigator.of(context).pop();
                        },
                        style: const ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(color4),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(
                              Icons.signal_wifi_off,
                              color: color4,
                            ),
                            Text('Desconectar Red Actual')
                          ],
                        ),
                      ),
                    ],
                    // TabBar - Solo mostrar si hay más de una tab
                    if (tabCount > 1) ...[
                      const SizedBox(height: 15),
                      TabBar(
                        labelColor: color4,
                        unselectedLabelColor: color3,
                        indicatorColor: color4,
                        indicatorWeight: 2,
                        tabs: tabs,
                      ),
                    ],
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 250,
                  child: tabCount > 1
                      ? TabBarView(children: tabViews)
                      : tabViews.first,
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.qr_code,
                          color: color4,
                        ),
                        iconSize: 30,
                        onPressed: () async {
                          PermissionStatus permissionStatusC =
                              await Permission.camera.request();
                          if (!permissionStatusC.isGranted) {
                            await Permission.camera.request();
                          }
                          permissionStatusC = await Permission.camera.status;
                          if (permissionStatusC.isGranted) {
                            openQRScanner(
                                navigatorKey.currentContext ?? context);
                          }
                        },
                      ),
                      TextButton(
                        style: const ButtonStyle(),
                        child: const Text(
                          'Agregar Red',
                          style: TextStyle(color: color4),
                        ),
                        onPressed: () {
                          setState(() {
                            isAddingNetwork = true;
                          });
                        },
                      ),
                      TextButton(
                        style: const ButtonStyle(),
                        child: const Text(
                          'Conectar',
                          style: TextStyle(color: color4),
                        ),
                        onPressed: () {
                          if (_currentlySelectedSSID != null &&
                              _wifiPasswordsMap[_currentlySelectedSSID] !=
                                  null) {
                            printLog(
                                '$_currentlySelectedSSID#${_wifiPasswordsMap[_currentlySelectedSSID]}');
                            sendWifitoBle(_currentlySelectedSSID!,
                                _wifiPasswordsMap[_currentlySelectedSSID]!);
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          Widget buildAddNetworkView() {
            return AlertDialog(
              backgroundColor: color1,
              title: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: color4,
                    ),
                    onPressed: () {
                      setState(() {
                        isAddingNetwork = false;
                      });
                    },
                  ),
                  const Text(
                    'Agregar red\nmanualmente',
                    style: TextStyle(
                      color: color4,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo para SSID
                    Row(
                      children: [
                        const Icon(
                          Icons.wifi,
                          color: color4,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            cursorColor: color4,
                            style: const TextStyle(color: color4),
                            decoration: const InputDecoration(
                              hintText: 'Agregar WiFi',
                              hintStyle: TextStyle(color: color3),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: color4),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: color4),
                              ),
                            ),
                            onChanged: (value) {
                              manualSSID = value;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock,
                          color: color4,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            cursorColor: color4,
                            style: const TextStyle(color: color4),
                            decoration: InputDecoration(
                              hintText: 'Contraseña',
                              hintStyle: const TextStyle(color: color3),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: color4),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: color4),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureText
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: color4,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureText = !obscureText;
                                  });
                                },
                              ),
                            ),
                            obscureText: obscureText,
                            onChanged: (value) {
                              manualPassword = value;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (manualSSID.isNotEmpty && manualPassword.isNotEmpty) {
                      printLog('$manualSSID#$manualPassword');
                      sendWifitoBle(manualSSID, manualPassword);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(color1),
                  ),
                  child: const Text(
                    'Agregar',
                    style: TextStyle(color: color4),
                  ),
                ),
              ],
            );
          }

          return isAddingNetwork ? buildAddNetworkView() : buildMainView();
        },
      );
    },
  ).then((_) {
    _scanInProgress = false;
    _expandedIndex = null;
    // NO desuscribirse al cerrar el diálogo para mantener los datos
    // La desuscripción se hace solo al desconectarse del dispositivo
  });
}

String getWifiErrorSintax(int errorCode) {
  switch (errorCode) {
    case 1:
      return "WIFI_REASON_UNSPECIFIED";
    case 2:
      return "WIFI_REASON_AUTH_EXPIRE";
    case 3:
      return "WIFI_REASON_AUTH_LEAVE";
    case 4:
      return "WIFI_REASON_ASSOC_EXPIRE";
    case 5:
      return "WIFI_REASON_ASSOC_TOOMANY";
    case 6:
      return "WIFI_REASON_NOT_AUTHED";
    case 7:
      return "WIFI_REASON_NOT_ASSOCED";
    case 8:
      return "WIFI_REASON_ASSOC_LEAVE";
    case 9:
      return "WIFI_REASON_ASSOC_NOT_AUTHED";
    case 10:
      return "WIFI_REASON_DISASSOC_PWRCAP_BAD";
    case 11:
      return "WIFI_REASON_DISASSOC_SUPCHAN_BAD";
    case 12:
      return "WIFI_REASON_BSS_TRANSITION_DISASSOC";
    case 13:
      return "WIFI_REASON_IE_INVALID";
    case 14:
      return "WIFI_REASON_MIC_FAILURE";
    case 15:
      return "WIFI_REASON_4WAY_HANDSHAKE_TIMEOUT";
    case 16:
      return "WIFI_REASON_GROUP_KEY_UPDATE_TIMEOUT";
    case 17:
      return "WIFI_REASON_IE_IN_4WAY_DIFFERS";
    case 18:
      return "WIFI_REASON_GROUP_CIPHER_INVALID";
    case 19:
      return "WIFI_REASON_PAIRWISE_CIPHER_INVALID";
    case 20:
      return "WIFI_REASON_AKMP_INVALID";
    case 21:
      return "WIFI_REASON_UNSUPP_RSN_IE_VERSION";
    case 22:
      return "WIFI_REASON_INVALID_RSN_IE_CAP";
    case 23:
      return "WIFI_REASON_802_1X_AUTH_FAILED";
    case 24:
      return "WIFI_REASON_CIPHER_SUITE_REJECTED";
    case 25:
      return "WIFI_REASON_TDLS_PEER_UNREACHABLE";
    case 26:
      return "WIFI_REASON_TDLS_UNSPECIFIED";
    case 27:
      return "WIFI_REASON_SSP_REQUESTED_DISASSOC";
    case 28:
      return "WIFI_REASON_NO_SSP_ROAMING_AGREEMENT";
    case 29:
      return "WIFI_REASON_BAD_CIPHER_OR_AKM";
    case 30:
      return "WIFI_REASON_NOT_AUTHORIZED_THIS_LOCATION";
    case 31:
      return "WIFI_REASON_SERVICE_CHANGE_PERCLUDES_TS";
    case 32:
      return "WIFI_REASON_UNSPECIFIED_QOS";
    case 33:
      return "WIFI_REASON_NOT_ENOUGH_BANDWIDTH";
    case 34:
      return "WIFI_REASON_MISSING_ACKS";
    case 35:
      return "WIFI_REASON_EXCEEDED_TXOP";
    case 36:
      return "WIFI_REASON_STA_LEAVING";
    case 37:
      return "WIFI_REASON_END_BA";
    case 38:
      return "WIFI_REASON_UNKNOWN_BA";
    case 39:
      return "WIFI_REASON_TIMEOUT";
    case 46:
      return "WIFI_REASON_PEER_INITIATED";
    case 47:
      return "WIFI_REASON_AP_INITIATED";
    case 48:
      return "WIFI_REASON_INVALID_FT_ACTION_FRAME_COUNT";
    case 49:
      return "WIFI_REASON_INVALID_PMKID";
    case 50:
      return "WIFI_REASON_INVALID_MDE";
    case 51:
      return "WIFI_REASON_INVALID_FTE";
    case 67:
      return "WIFI_REASON_TRANSMISSION_LINK_ESTABLISH_FAILED";
    case 68:
      return "WIFI_REASON_ALTERATIVE_CHANNEL_OCCUPIED";
    case 200:
      return "WIFI_REASON_BEACON_TIMEOUT";
    case 201:
      return "WIFI_REASON_NO_AP_FOUND";
    case 202:
      return "WIFI_REASON_AUTH_FAIL";
    case 203:
      return "WIFI_REASON_ASSOC_FAIL";
    case 204:
      return "WIFI_REASON_HANDSHAKE_TIMEOUT";
    case 205:
      return "WIFI_REASON_CONNECTION_FAIL";
    case 206:
      return "WIFI_REASON_AP_TSF_RESET";
    case 207:
      return "WIFI_REASON_ROAMING";
    default:
      return "Error Desconocido";
  }
}
//*-Wifi, menú y scanner-*\\

//*-Suscripción a datos WiFi desde BLE-*\\
Future<void> readInitialWifiData() async {
  if (bluetoothManager.hasWifiService) {
    try {
      // Leer la característica una vez para obtener datos iniciales
      List<int> initialData = await bluetoothManager.wifiAvailableUuid.read();
      // printLog("Datos WiFi iniciales leídos: $initialData");
      // printLog(
      //     "Datos en hex Available: ${initialData.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}");
      wifiDataNotifier.updateWifiData(initialData);
    } catch (e) {
      printLog("Error al leer datos WiFi iniciales: $e", "rojo");
    }
  }
}

void subscribeToWifiData() async {
  if (bluetoothManager.hasWifiService && !alreadySubWifi) {
    try {
      // IMPORTANTE: Configurar el listener ANTES de suscribirse
      // porque el dispositivo envía datos inmediatamente
      bluetoothManager.wifiAvailableUuid.onValueReceived
          .listen((List<int> data) {
        // printLog("Nuevos datos WiFi recibidos: $data");
        // Agregar nuevos datos al final de la lista existente
        wifiDataNotifier.appendWifiData(data);
      });
      printLog("Listener WiFi configurado");

      // Ahora sí, suscribirse a las notificaciones
      await bluetoothManager.wifiAvailableUuid.setNotifyValue(true);
      alreadySubWifi = true;
      printLog("Suscrito a datos WiFi BLE");
    } catch (e) {
      printLog("Error al suscribirse a datos WiFi: $e", "rojo");
    }
  }
}

void unsubscribeFromWifiData() async {
  if (bluetoothManager.hasWifiService && alreadySubWifi) {
    try {
      await bluetoothManager.wifiAvailableUuid.setNotifyValue(false);
      alreadySubWifi = false;
      wifiDataNotifier.clearWifiData();
      printLog("Desuscrito de datos WiFi BLE");
    } catch (e) {
      printLog("Error al desuscribirse de datos WiFi: $e", "rojo");
    }
  }
}

//*-Gestión de redes WiFi guardadas-*\\
Future<void> readStoredWifiNetworks() async {
  if (bluetoothManager.hasWifiService) {
    try {
      printLog("Intentando leer redes guardadas...");
      // Leer la característica de redes guardadas
      List<int> storedData = await bluetoothManager.wifiStoredUuid.read();
      printLog("Redes guardadas leídas: $storedData");
      printLog(
          "Datos en hex Stored: ${storedData.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}");
      wifiStoredNotifier.updateStoredNetworks(storedData);
    } catch (e) {
      printLog("Error al leer redes guardadas: $e", "rojo");
    }
  } else {
    printLog(
        "No se puede leer redes guardadas. bluetoothManager.hasWifiService: $bluetoothManager.hasWifiService");
  }
}

Future<void> deleteStoredWifiNetwork(String ssid) async {
  if (bluetoothManager.hasWifiService) {
    try {
      // Crear comando para borrar red
      Map<String, dynamic> deleteCommand = {"cmd": 0, "content": ssid};

      // Serializar a MessagePack
      List<int> messagePackData = serialize(deleteCommand);

      // Enviar comando
      await bluetoothManager.wifiStoredUuid.write(messagePackData);
      printLog("Comando de borrar red enviado para: $ssid");

      // Actualizar la lista después de un pequeño delay
      Future.delayed(const Duration(milliseconds: 500), () {
        readStoredWifiNetworks();
      });
    } catch (e) {
      printLog("Error al borrar red guardada: $e", "rojo");
    }
  }
}
//*-Gestión de redes WiFi guardadas-*\\

//*-Suscripción a datos WiFi desde BLE-*\\

//*-Qr scanner-*\\
Future<void> openQRScanner(BuildContext context) async {
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var qrResult = await navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const QRScanPage(),
        ),
      );
      if (qrResult != null) {
        var wifiData = parseWifiQR(qrResult);
        sendWifitoBle(wifiData['SSID']!, wifiData['password']!);
      }
    });
  } catch (e) {
    printLog("Error during navigation: $e");
  }
}

Map<String, String> parseWifiQR(String qrContent) {
  printLog(qrContent);
  final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(qrContent);
  final passwordMatch = RegExp(r'P:([^;]+)').firstMatch(qrContent);

  final ssid = ssidMatch?.group(1) ?? '';
  final password = passwordMatch?.group(1) ?? '';
  return {"SSID": ssid, "password": password};
}
//*-Qr scanner-*\\

//*-Monitoreo Localizacion y Bluetooth*-\\
void startLocationMonitoring() {
  locationTimer = Timer.periodic(
      const Duration(seconds: 10), (Timer t) => locationStatus());
}

void locationStatus() async {
  await NativeService.isLocationServiceEnabled();
}

void startBluetoothMonitoring() {
  bluetoothTimer = Timer.periodic(
      const Duration(seconds: 10), (Timer t) => bluetoothStatus());
}

void bluetoothStatus() async {
  await NativeService.isBluetoothServiceEnabled();
}
//*-Monitoreo Localizacion y Bluetooth*-\\

//*-Elementos genericos-*\\
///Genera un cuadro de dialogo con los parametros que le pases
void showAlertDialog(BuildContext context, bool dismissible, Widget? title,
    Widget? content, List<Widget>? actions) {
  showGeneralDialog(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      double screenWidth = MediaQuery.of(context).size.width;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter changeState) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 300.0,
                maxWidth: screenWidth - 20,
              ),
              child: IntrinsicWidth(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        spreadRadius: 1,
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Card(
                    color: color3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 24,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: DefaultTextStyle(
                                  style: const TextStyle(
                                    color: color0,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  child: title ?? const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: DefaultTextStyle(
                                  style: const TextStyle(
                                    color: color0,
                                    fontSize: 16,
                                  ),
                                  child: content ?? const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 30),
                              if (actions != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: actions.map(
                                    (widget) {
                                      if (widget is TextButton) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5.0),
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: color0,
                                              backgroundColor: color3,
                                            ),
                                            onPressed: widget.onPressed,
                                            child: widget.child!,
                                          ),
                                        );
                                      } else {
                                        return widget;
                                      }
                                    },
                                  ).toList(),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -50,
                          child: Material(
                            elevation: 10,
                            shape: const CircleBorder(),
                            shadowColor: Colors.black.withValues(alpha: 0.4),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: color3,
                              child: Image.asset(
                                'assets/Dragon.png',
                                width: 60,
                                height: 60,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        ),
      );
    },
  );
}

///Genera un botón generico con los parametros que le pases
Widget buildButton({
  required String text,
  required void Function()? onPressed,
}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: color1,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      shadowColor: color3.withValues(alpha: 0.4),
    ),
    onPressed: onPressed,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color4,
      ),
    ),
  );
}

///Genera un cuadro de texto generico con los parametros que le pases
Widget buildTextField({
  TextEditingController? controller,
  String? label,
  String? hint,
  void Function(String)? onSubmitted,
  double widthFactor = 0.8,
  TextInputType? keyboard,
  void Function(String)? onChanged,
  int? maxLines,
  IconButton? suffixIcon,
}) {
  return FractionallySizedBox(
    alignment: Alignment.center,
    widthFactor: widthFactor,
    child: Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      decoration: BoxDecoration(
        color: color0,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color3.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        maxLines: maxLines,
        style: const TextStyle(
          color: color4,
        ),
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: color4,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: const TextStyle(
            color: color4,
          ),
          border: InputBorder.none,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: color4,
              width: 1.0,
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: color4,
              width: 2.0,
            ),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    ),
  );
}

///Genera un texto generico con los parametros que le pases
Widget buildText({
  required String text,
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.normal,
  Color color = color4,
  TextAlign textAlign = TextAlign.center,
  double widthFactor = 0.9,
  List<TextSpan>? textSpans,
}) {
  return FractionallySizedBox(
    alignment: Alignment.center,
    widthFactor: widthFactor,
    child: Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
          children: textSpans ?? [TextSpan(text: text)],
        ),
        textAlign: textAlign,
      ),
    ),
  );
}
//*-Elementos genericos-*\\

//*-Registro de actividad-*\\
void registerActivity(
    String productCode, String serialNumber, String accion) async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;

    String diaDeLaFecha =
        DateTime.now().toString().split(' ')[0].replaceAll('-', '');

    String documentPath = '$productCode:$serialNumber';

    String actionListName = '$diaDeLaFecha:$legajoConectado';

    DocumentReference docRef = db.collection('Registro').doc(documentPath);

    DocumentSnapshot doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        actionListName: FieldValue.arrayUnion([accion])
      }).then((_) {
        printLog("Documento creado exitosamente!");
      }).catchError((error) {
        printLog("Error creando el documento: $error");
      });
    } else {
      printLog("Documento ya existe.");
      await docRef.update({
        actionListName: FieldValue.arrayUnion([accion])
      }).catchError(
          (error) => printLog("Error al añadir item al array: $error"));
    }
  } catch (e, s) {
    printLog('Error al registrar actividad: $e');
    printLog(s);
  }
}
//*-Registro de actividad-*\\

//*-Fetch data from firestore-*\\
Future<Map<String, dynamic>> fetchDocumentData() async {
  try {
    DocumentReference document =
        FirebaseFirestore.instance.collection('CSFABRICA').doc('Data');

    DocumentSnapshot snapshot = await document.get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      return data;
    } else {
      throw Exception("El documento no existe");
    }
  } catch (e) {
    printLog("Error al leer Firestore: $e");
    return {};
  }
}
//*-Fetch data from firestore-*\\

//*-Registro temperatura ambiente enviada-*\\
Future<bool> tempWasSended(String productCode, String serialNumber) async {
  printLog('Ta bacano');
  try {
    String docPath = '$legajoConectado:$productCode:$serialNumber';
    DocumentSnapshot documentSnapshot =
        await FirebaseFirestore.instance.collection('Data').doc(docPath).get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;

      printLog('TempSend: ${data['temp']}');
      data['temp'] == true
          ? tempDate = data['tempDate']
          : tempDate =
              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
      return data['temp'] ?? false;
    } else {
      printLog('No existe');
      return false;
    }
  } catch (error) {
    printLog('Error al realizar la consulta: $error');
    return false;
  }
}

void registerTemp(String productCode, String serialNumber) async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;

    String date =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    String documentPath = '$legajoConectado:$productCode:$serialNumber';

    DocumentReference docRef = db.collection('Data').doc(documentPath);

    docRef.set({'temp': true, 'tempDate': date});
  } catch (e, s) {
    printLog('Error al registrar actividad: $e');
    printLog(s);
  }
}
//*-Registro temperatura ambiente enviada-*\\

//*- Revisa si el equipo tiene sensor dallas -*\\
bool hasDallasSensor(String productCode, String hwVersion) {
  String versionWithDallas = '';
  switch (productCode) {
    case '022000_IOT':
      versionWithDallas = '240924A';
    case '027000_IOT':
      versionWithDallas = '241003A';
    case '028000_IOT':
      versionWithDallas = '241004B';
    case '041220_IOT':
      versionWithDallas = '241003A';
    case '051217_IOT':
      versionWithDallas = '241004B';
    default:
      versionWithDallas = '991231A';
  }

  bool hasIt = Versioner.isPosterior(hwVersion, versionWithDallas);

  return hasIt;
}
//*- Revisa si el equipo tiene sensor dallas -*\\

// // -------------------------------------------------------------------------------------------------------------\\ \\

//! CLASES !\\

//*- Funciones relacionadas a los equipos*-\\
class DeviceManager {
  final List<String> productos = [
    '015773_IOT',
    '020010_IOT',
    '022000_IOT',
    '024011_IOT',
    '027000_IOT',
    '027170_IOT',
    '027313_IOT',
    '041220_IOT'
  ];

  ///Extrae el número de serie desde el deviceName
  static String extractSerialNumber(String productName) {
    RegExp regExp = RegExp(r'(\d{8})');

    Match? match = regExp.firstMatch(productName);

    return match?.group(0) ?? '';
  }

  ///Conseguir el código de producto en base al deviceName
  static String getProductCode(String device) {
    Map<String, String> data = (fbData['PC'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        value.toString(),
      ),
    );
    String cmd = '';
    for (String key in data.keys) {
      if (device.contains(key)) {
        cmd = data[key].toString();
      }
    }
    return cmd;
  }

  ///Recupera el deviceName en base al productCode y al SerialNumber
  static String recoverDeviceName(String pc, String sn) {
    String code = '';
    switch (pc) {
      case '015773_IOT':
        code = 'Detector';
        break;
      case '022000_IOT':
        code = 'Electrico';
        break;
      case '027000_IOT':
        code = 'Gas';
        break;
      case '020010_IOT':
        code = 'Domotica';
        break;
      case '027313_IOT':
        code = 'Rele';
        break;
      case '024011_IOT':
        code = 'Roll';
        break;
      case '027170_IOT':
        code = 'Patito';
        break;
    }

    return '$code$sn';
  }
}
//*- Funciones relacionadas a los equipos*-\\

//*-BLE, configuraciones del equipo-*\\
class BluetoothManager {
  static final BluetoothManager _singleton = BluetoothManager._internal();

  factory BluetoothManager() {
    return _singleton;
  }

  BluetoothManager._internal();

  // Variables de manejo global
  late BluetoothDevice device;
  bool newGeneration = false;
  Map<String, dynamic> data = {};

  // Variables de nueva generación
  bool hasLoggerBle = false;
  bool hasResourceMonitor = false;
  bool hasWifiService = false;
  bool hasAppService = false;
  bool hasTemperatureService = false;
  bool hasOtaService = false;
  bool hasAwsService = false;
  bool hasBluetoothService = false;
  bool hasBatteryService = false;

  // Variables de antigua generación
  bool hasVars = false;

  // Características generación nueva
  late BluetoothCharacteristic wifiAvailableUuid;
  late BluetoothCharacteristic wifiStoredUuid;
  late BluetoothCharacteristic wifiDataUuid;
  late BluetoothCharacteristic liveLoggerUuid;
  late BluetoothCharacteristic registerLoggerUuid;
  late BluetoothCharacteristic resourceMonitorUuid;
  late BluetoothCharacteristic appDataUuid;
  late BluetoothCharacteristic temperatureUuid;
  late BluetoothCharacteristic awsUuid;
  late BluetoothCharacteristic bleDataUuid;
  late BluetoothCharacteristic otaBleUuid;
  late BluetoothCharacteristic otaWifiUuid;
  late BluetoothCharacteristic batteryUuid;

  // Características generación antigua
  late BluetoothCharacteristic infoUuid;
  late BluetoothCharacteristic toolsUuid;
  late BluetoothCharacteristic varsUuid;
  late BluetoothCharacteristic workUuid;
  late BluetoothCharacteristic lightUuid;
  late BluetoothCharacteristic calibrationUuid;
  late BluetoothCharacteristic regulationUuid;
  late BluetoothCharacteristic otaUuid;
  late BluetoothCharacteristic debugUuid;
  late BluetoothCharacteristic ioUuid;
  late BluetoothCharacteristic patitoUuid;

  Future<bool> setup(BluetoothDevice connectedDevice) async {
    try {
      device = connectedDevice;
      deviceName = connectedDevice.platformName;

      List<BluetoothService> services =
          await device.discoverServices(timeout: 3);

      services.any((s) => s.uuid == Guid('180A'))
          ? newGeneration = true
          : newGeneration = false;

      printLog("Generación nueva: $newGeneration");

      try {
        BluetoothService loggerService = services.firstWhere(
            (s) => s.uuid == Guid('ad04c0c7-6a98-4ab7-a29c-4c59ef1d0077'));
        liveLoggerUuid = loggerService.characteristics.firstWhere(
            (c) => c.uuid == Guid('e3375cd1-c0d2-4d8b-823d-2a7536cad48d'));
        registerLoggerUuid = loggerService.characteristics.firstWhere(
            (c) => c.uuid == Guid('b6abd12d-9b1c-452e-875d-28f99421e17a'));
        hasLoggerBle = true;
      } catch (e) {
        printLog("Error al configurar los loggers: $e");
        hasLoggerBle = false;
      }

      try {
        BluetoothService resourceService = services.firstWhere(
            (s) => s.uuid == Guid('a7bda260-17f0-4fea-923a-d7e98555b592'));
        resourceMonitorUuid = resourceService.characteristics.firstWhere(
            (c) => c.uuid == Guid('86728aa9-624b-4346-8c34-9eda0408bc1f'));
        hasResourceMonitor = true;
      } catch (e) {
        printLog("Error al configurar el monitor de recursos: $e");
        hasResourceMonitor = false;
      }

      //!División de setups

      if (newGeneration) {
        BluetoothService deviceInfoService =
            services.firstWhere((s) => s.uuid == Guid('180A'));

        // deviceName = utf8.decode(await deviceInfoService.characteristics
        //     .firstWhere((c) => c.uuid == Guid('2A00'))
        //     .read());
        softwareVersion = utf8.decode(await deviceInfoService.characteristics
            .firstWhere((c) => c.uuid == Guid('2A28'))
            .read());
        hardwareVersion = utf8.decode(await deviceInfoService.characteristics
            .firstWhere((c) => c.uuid == Guid('2A27'))
            .read());
        factoryMode = softwareVersion.contains('_F');

        printLog("Device Name: $deviceName");
        printLog("Hardware Version: $hardwareVersion");
        printLog("Software Version: $softwareVersion");
        printLog("Factory Mode: $factoryMode");

        try {
          BluetoothService wifiService = services.firstWhere(
              (s) => s.uuid == Guid('312ccb9a-72aa-4b30-bfbd-2157050e2e43'));
          wifiAvailableUuid = wifiService.characteristics.firstWhere(
              (c) => c.uuid == Guid('238297b6-1ca1-423d-a2c0-739871488c4a'));
          wifiStoredUuid = wifiService.characteristics.firstWhere(
              (c) => c.uuid == Guid('bcbb4443-78a8-47cc-bb75-b9728847d5c4'));
          wifiDataUuid = wifiService.characteristics.firstWhere(
              (c) => c.uuid == Guid('2470f494-f405-44ce-8e31-266090b79bd4'));
          hasWifiService = true;
        } catch (e) {
          printLog("Error al configurar las variables de wifi: $e");
          hasWifiService = false;
        }

        try {
          BluetoothService appService = services.firstWhere(
              (s) => s.uuid == Guid('c3e7737a-46c0-434a-9d80-9acbff52cfc9'));
          appDataUuid = appService.characteristics.firstWhere(
              (c) => c.uuid == Guid('1726c56f-8f91-4020-a54a-fc04d233edee'));
          hasAppService = true;
        } catch (e) {
          printLog("Error al configurar el servicio de app: $e");
          hasAppService = false;
        }

        try {
          BluetoothService tempService = services.firstWhere(
              (s) => s.uuid == Guid('f0eff885-8e19-4e39-af05-8bf44570dd25'));
          temperatureUuid = tempService.characteristics.firstWhere(
              (c) => c.uuid == Guid('e6793e60-7326-4894-9bed-0984174778c0'));
          hasTemperatureService = true;
        } catch (e) {
          printLog("Error al configurar el servicio de temperatura: $e");
          hasTemperatureService = false;
        }

        try {
          BluetoothService otaService = services.firstWhere(
              (s) => s.uuid == Guid('1d16c562-f0e3-484f-ac35-02294691dcd7'));
          otaBleUuid = otaService.characteristics.firstWhere(
              (c) => c.uuid == Guid('6af793f0-efc2-42f7-ad70-1b9ad5df5d98'));
          otaWifiUuid = otaService.characteristics.firstWhere(
              (c) => c.uuid == Guid('8562865a-deff-49aa-ab96-010ea2d20b0b'));
          hasOtaService = true;
        } catch (e) {
          printLog("Error al configurar el servicio OTA: $e");
          hasOtaService = false;
        }

        try {
          BluetoothService awsService = services.firstWhere(
              (s) => s.uuid == Guid('7148ba3e-9d37-4f16-9f86-2be696350a97'));
          awsUuid = awsService.characteristics.firstWhere(
              (c) => c.uuid == Guid('1387ef2f-ce09-4cfc-bb0e-80dd82d391de'));
          hasAwsService = true;
        } catch (e) {
          printLog("Error al configurar el servicio AWS: $e");
          hasAwsService = false;
        }

        try {
          BluetoothService bluetoothService = services.firstWhere(
              (s) => s.uuid == Guid('57a3a83d-0771-4bc6-801a-82516517f088'));
          bleDataUuid = bluetoothService.characteristics.firstWhere(
              (c) => c.uuid == Guid('6d698617-4d87-4400-8ff7-eb256ed17cef'));
          hasBluetoothService = true;
        } catch (e) {
          printLog("Error al configurar el servicio Bluetooth: $e");
          hasBluetoothService = false;
        }

        printLog("¿Tiene logger ble? $hasLoggerBle");
        printLog("¿Tiene monitor de recursos? $hasResourceMonitor");
        printLog("¿Tiene variables de wifi? $hasWifiService");
        printLog("¿Tiene servicio de app? $hasAppService");
        printLog("¿Tiene servicio de temperatura? $hasTemperatureService");
        printLog("¿Tiene servicio OTA? $hasOtaService");
        printLog("¿Tiene servicio AWS? $hasAwsService");
        printLog("¿Tiene servicio Bluetooth? $hasBluetoothService");
      } else {
        BluetoothService infoService = services.firstWhere(
            (s) => s.uuid == Guid('6a3253b4-48bc-4e97-bacd-325a1d142038'));
        infoUuid = infoService.characteristics.firstWhere((c) =>
            c.uuid ==
            Guid(
                'fc5c01f9-18de-4a75-848b-d99a198da9be')); //ProductType:SerialNumber:SoftVer:HardVer:Owner
        toolsUuid = infoService.characteristics.firstWhere((c) =>
            c.uuid ==
            Guid(
                '89925840-3d11-4676-bf9b-62961456b570')); //WifiStatus:WifiSSID/WifiError:BleStatus(users)

        infoValues = await infoUuid.read();
        String str = utf8.decode(infoValues);
        var partes = str.split(':');
        softwareVersion = partes[2];
        hardwareVersion = partes[3];
        factoryMode = softwareVersion.contains('_F');
        String pc = partes[0];
        printLog(
            'Product code: ${DeviceManager.getProductCode(device.platformName)}');
        printLog(
            'Serial number: ${DeviceManager.extractSerialNumber(device.platformName)}');

        printLog("Hardware Version: $hardwareVersion");

        printLog("Software Version: $softwareVersion");

        switch (pc) {
          case '022000_IOT' ||
                '027000_IOT' ||
                '041220_IOT' ||
                '050217_IOT' ||
                '028000_IOT' ||
                '023430_IOT' ||
                '027345_IOT':
            BluetoothService espService = services.firstWhere(
                (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

            varsUuid = espService.characteristics.firstWhere((c) =>
                c.uuid ==
                Guid(
                    '52a2f121-a8e3-468c-a5de-45dca9a2a207')); //WorkingTemp:WorkingStatus:EnergyTimer:HeaterOn:NightMode
            otaUuid = espService.characteristics.firstWhere((c) =>
                c.uuid ==
                Guid(
                    'ae995fcd-2c7a-4675-84f8-332caf784e9f')); //Ota comandos (Solo notify)

            break;

          case '015773_IOT':
            BluetoothService service = services.firstWhere(
                (s) => s.uuid == Guid('dd249079-0ce8-4d11-8aa9-53de4040aec6'));

            if (factoryMode) {
              calibrationUuid = service.characteristics.firstWhere((c) =>
                  c.uuid == Guid('0147ab2a-3987-4bb8-802b-315a664eadd6'));
              regulationUuid = service.characteristics.firstWhere((c) =>
                  c.uuid == Guid('961d1cdd-028f-47d0-aa2a-e0095e387f55'));
              debugUuid = service.characteristics.firstWhere((c) =>
                  c.uuid == Guid('838335a1-ff5a-4344-bfdf-38bf6730de26'));
              BluetoothService otaService = services.firstWhere((s) =>
                  s.uuid == Guid('33e3a05a-c397-4bed-81b0-30deb11495c7'));
              otaUuid = otaService.characteristics.firstWhere((c) =>
                  c.uuid ==
                  Guid(
                      'ae995fcd-2c7a-4675-84f8-332caf784e9f')); //Ota comandos (Solo notify)
            }

            workUuid = service.characteristics.firstWhere((c) =>
                c.uuid ==
                Guid(
                    '6869fe94-c4a2-422a-ac41-b2a7a82803e9')); //Array de datos (ppm,etc)
            lightUuid = service.characteristics.firstWhere((c) =>
                c.uuid ==
                Guid('12d3c6a1-f86e-4d5b-89b5-22dc3f5c831f')); //No leo

            try {
              varsUuid = service.characteristics.firstWhere((c) =>
                  c.uuid == Guid('52a2f121-a8e3-468c-a5de-45dca9a2a207'));
              bluetoothManager.hasVars = true;
            } catch (e) {
              printLog("No tiene vars ble: $e");
              bluetoothManager.hasVars = false;
            }

            break;
          case '020010_IOT' || '020020_IOT':
            BluetoothService service = services.firstWhere(
                (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));
            ioUuid = service.characteristics.firstWhere(
                (c) => c.uuid == Guid('03b1c5d9-534a-4980-aed3-f59615205216'));
            otaUuid = service.characteristics.firstWhere((c) =>
                c.uuid ==
                Guid(
                    'ae995fcd-2c7a-4675-84f8-332caf784e9f')); //Ota comandos (Solo notify)
            varsUuid = service.characteristics.firstWhere(
                (c) => c.uuid == Guid('52a2f121-a8e3-468c-a5de-45dca9a2a207'));
            break;
          case '027313_IOT':
            if (Versioner.isPosterior(hardwareVersion, '241220A')) {
              printLog("Soy nuevito aña");
              BluetoothService service = services.firstWhere((s) =>
                  s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));
              ioUuid = service.characteristics.firstWhere((c) =>
                  c.uuid == Guid('03b1c5d9-534a-4980-aed3-f59615205216'));
              otaUuid = service.characteristics.firstWhere((c) =>
                  c.uuid ==
                  Guid(
                      'ae995fcd-2c7a-4675-84f8-332caf784e9f')); //Ota comandos (Solo notify)
              varsUuid = service.characteristics.firstWhere((c) =>
                  c.uuid == Guid('52a2f121-a8e3-468c-a5de-45dca9a2a207'));
            } else {
              BluetoothService espService = services.firstWhere((s) =>
                  s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

              varsUuid = espService.characteristics.firstWhere((c) =>
                  c.uuid ==
                  Guid(
                      '52a2f121-a8e3-468c-a5de-45dca9a2a207')); //DistanceControl:W_Status:EnergyTimer:AwsINIT
              otaUuid = espService.characteristics.firstWhere((c) =>
                  c.uuid ==
                  Guid(
                      'ae995fcd-2c7a-4675-84f8-332caf784e9f')); //Ota comandos (Solo notify)
            }

            break;
          case '024011_IOT':
            BluetoothService espService = services.firstWhere(
                (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

            varsUuid = espService.characteristics.firstWhere((c) =>
                c.uuid ==
                Guid(
                    '52a2f121-a8e3-468c-a5de-45dca9a2a207')); //DstCtrl:LargoRoller:InversionGiro:VelocidadMotor:PosicionActual:PosicionTrabajo:RollerMoving:AWSinit
            otaUuid = espService.characteristics.firstWhere((c) =>
                c.uuid ==
                Guid(
                    'ae995fcd-2c7a-4675-84f8-332caf784e9f')); //Ota comandos (Solo notify)
            break;
          case '027170_IOT':
            BluetoothService service = services.firstWhere(
                (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));
            patitoUuid = service.characteristics.firstWhere(
                (c) => c.uuid == Guid('03b1c5d9-534a-4980-aed3-f59615205216'));
            otaUuid = service.characteristics.firstWhere((c) =>
                c.uuid ==
                Guid(
                    'ae995fcd-2c7a-4675-84f8-332caf784e9f')); //Ota comandos (Solo notify)

            try {
              BluetoothService batteryService = services.firstWhere((s) =>
                  s.uuid == Guid('92bcf3ed-c983-4c77-b07f-56d9e0f34540'));
              batteryUuid = batteryService.characteristics.firstWhere((c) =>
                  c.uuid == Guid('bf9a2a2d-fab2-45df-a0a9-c7bed6bcb0b8'));
              hasBatteryService = true;
            } catch (e) {
              printLog("Error al configurar el monitor de batería: $e");
              hasBatteryService = false;
            }
            break;
        }
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      printLog('Lcdtmbe $e', 'rojo');
      printLog('Stacktrace: $stackTrace', 'rojo');

      return Future.value(false);
    }
  }

  void restoreData() {
    hasLoggerBle = false;
    hasResourceMonitor = false;
    hasVars = false;
    hasWifiService = false;
    newGeneration = false;
    hasAppService = false;
    hasTemperatureService = false;
    hasOtaService = false;
    hasAwsService = false;
    hasBluetoothService = false;
    data = {};
  }
}
//*-BLE, configuraciones del equipo-*\\

//*-Metodos, interacción con código Nativo-*\\
class NativeService {
  static const platform = MethodChannel('com.caldensmart.fabrica/native');

  static Future<bool> isLocationServiceEnabled() async {
    try {
      final bool isEnabled =
          await platform.invokeMethod("isLocationServiceEnabled");
      return isEnabled;
    } on PlatformException catch (e) {
      printLog('Error verificando ubicación: $e');
      return false;
    }
  }

  static Future<void> isBluetoothServiceEnabled() async {
    try {
      final bool isBluetoothOn = await platform.invokeMethod('isBluetoothOn');

      if (!isBluetoothOn && !bleFlag) {
        bleFlag = true;
        final bool turnedOn = await platform.invokeMethod('turnOnBluetooth');

        if (turnedOn) {
          bleFlag = false;
        } else {
          printLog("El usuario rechazó encender Bluetooth");
        }
      }
    } on PlatformException catch (e) {
      printLog("Error al verificar o encender Bluetooth: ${e.message}");
      bleFlag = false;
    }
  }

  static Future<void> openLocationOptions() async {
    try {
      await platform.invokeMethod("openLocationSettings");
    } on PlatformException catch (e) {
      printLog('Error abriendo la configuración de ubicación: $e');
    }
  }
}
//*-Metodos, interacción con código Nativo-*\\

//*-Versionador, comparador de versiones-*\\
class Versioner {
  // ---------------------- CONFIGURACIÓN ----------------------
  static const String _owner = 'barberop';
  static const String _repo = 'sime-domotica';
  static const String _branch = 'main';

  // ---------------------- COMPARADORES ----------------------
  /// Compara si la primera versión (AAMMDDL) salió después o es igual a la segunda.
  static bool isPosterior(String myVersion, String versionToCompare) {
    final v1 = _parseVersion(myVersion);
    final v2 = _parseVersion(versionToCompare);
    if (v1.date.isAtSameMomentAs(v2.date)) {
      return v1.letter.compareTo(v2.letter) >= 0;
    }
    return v1.date.isAfter(v2.date);
  }

  /// Compara si la primera versión salió antes que la segunda.
  static bool isPrevious(String myVersion, String versionToCompare) {
    final v1 = _parseVersion(myVersion);
    final v2 = _parseVersion(versionToCompare);
    if (v1.date.isAtSameMomentAs(v2.date)) {
      return v1.letter.compareTo(v2.letter) < 0;
    }
    return v1.date.isBefore(v2.date);
  }

  // ---------------------- PARSEADO ----------------------
  /// Auxiliar para parsear AAMMDD(Letra) en DateTime y letra.
  static _VersionData _parseVersion(String version) {
    final yy = int.parse('20${version.substring(0, 2)}');
    final mm = int.parse(version.substring(2, 4));
    final dd = int.parse(version.substring(4, 6));
    final letter = version.substring(6, 7);
    return _VersionData(DateTime(yy, mm, dd), letter);
  }

  // ---------------------- LISTADO Y OBTENCIÓN ----------------------

  /// Lista los archivos .bin en GitHub bajo OTA_FW/W y devuelve
  /// el nombre del archivo con la última subversión cuyo prefijo
  /// coincida EXACTAMENTE con la versión de hardware (hwVersion) recibida.
  ///
  /// [productCode]: Carpeta del producto (ej. '015773_IOT').
  /// [hwVersion]: Fecha+letra de hardware (ej. '240214A').
  static Future<String> fetchLatestFirmwareFile(
      String productCode, String hwVersion, bool factory) async {
    // Nos aseguramos de quitar espacios extras y mantener el case original.
    final sanitizedHw = hwVersion.trim();
    final prefix = 'hv${sanitizedHw}sv';
    printLog('Prefix hardware: $prefix');

    final path = '$productCode/OTA_FW/${factory ? 'F' : 'W'}';
    final uri = Uri.https(
      'api.github.com',
      '/repos/$_owner/$_repo/contents/$path',
      {'ref': _branch},
    );
    printLog('Fetching OTA_FW/${factory ? 'F' : 'W'} from: $uri');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $githubToken',
      'Accept': 'application/vnd.github.v3+json',
    });
    printLog('GitHub API status: ${response.statusCode}');
    if (response.statusCode != 200) {
      printLog('Error listing OTA_FW/${factory ? 'F' : 'W'}: ${response.body}');
      showToast('Error al listar firmware: ${response.statusCode}');
      throw Exception(
          'Error al listar OTA_FW/${factory ? 'F' : 'W'}: ${response.statusCode}');
    }

    final List<dynamic> items = jsonDecode(response.body);
    final firmwareFiles = <String>[];

    for (final item in items) {
      if (item['type'] == 'file') {
        final name = item['name'] as String;
        // Comprobamos que el nombre empiece exactamente con el prefijo y termine en ".bin"
        final matchesPrefix = name.startsWith(prefix);
        final isBin = name.endsWith('.bin');
        printLog(
            'Found item: $name (startsWith prefix? $matchesPrefix, endsWith .bin? $isBin)');
        if (matchesPrefix && isBin) {
          firmwareFiles.add(name);
        }
      }
    }

    if (firmwareFiles.isEmpty) {
      printLog(
          'No matching firmware found for HW $sanitizedHw with prefix $prefix');
      throw Exception('No se encontró firmware para HW $sanitizedHw');
    }

    // Ordenamos alfabéticamente para que el último tenga la subversión más alta.
    firmwareFiles.sort();
    final latest = firmwareFiles.last;
    printLog('Latest firmware file: $latest');
    return latest;
  }

  /// A partir del nombre de archivo devuelto por fetchLatestFirmwareFile,
  /// extrae y retorna solo la subversión (SV) sin prefijos ni extensión.
  /// Ejemplo: de 'hv240214Asv240528H.bin' devuelve '240528H'.
  static String extractSV(String firmwareFileName, String hwVersion) {
    printLog('Extracting SV from $firmwareFileName for HW version $hwVersion');
    final prefix = 'hv${hwVersion}sv';
    return firmwareFileName.replaceFirst(prefix, '').replaceFirst('.bin', '');
  }

  /// Construye la URL raw de GitHub para la última versión de firmware.
  static String buildFirmwareUrl(
      String productCode, String firmwareFileName, bool factory) {
    return 'https://raw.githubusercontent.com/$_owner/$_repo/$_branch/'
        '$productCode/OTA_FW/${factory ? 'F' : 'W'}/$firmwareFileName';
  }
}

/// Datos internos de versión.
class _VersionData {
  final DateTime date;
  final String letter;
  _VersionData(this.date, this.letter);
}
//*-Versionador, comparador de versiones-*\\

//*-Provider, actualización de data en un widget-*\\
class GlobalDataNotifier extends ChangeNotifier {
  String? _data;

  // Obtener datos por topic específico
  String getData() {
    return _data ?? 'Esperando respuesta del esp...';
  }

  // Actualizar datos para un topic específico y notificar a los oyentes
  void updateData(String newData) {
    if (_data != newData) {
      _data = newData;
      notifyListeners(); // Esto notifica a todos los oyentes que algo cambió
    }
  }
}

//*-WiFi Data Notifier, actualización de datos WiFi desde BLE-*\\
class WiFiDataNotifier extends ChangeNotifier {
  Map<String, Map<String, dynamic>> _wifiData = {};

  // Obtener datos WiFi
  Map<String, Map<String, dynamic>> getWifiData() {
    return _wifiData;
  }

  // Verificar si tiene datos
  bool hasData() {
    return _wifiData.isNotEmpty;
  }

  // Actualizar datos WiFi desde MessagePack y notificar a los oyentes
  void updateWifiData(List<int> messagePack) {
    try {
      // Decodificar MessagePack
      final decoded = deserialize(Uint8List.fromList(messagePack));

      if (decoded is Map) {
        Map<String, Map<String, dynamic>> newWifiData = {};

        decoded.forEach((key, value) {
          if (value is Map) {
            newWifiData[key.toString()] = Map<String, dynamic>.from(value);
          }
        });

        if (_wifiData.toString() != newWifiData.toString()) {
          _wifiData = newWifiData;
          // Actualizar también la variable global
          wifiAvailableData = newWifiData;
          printLog("WiFi data actualizada: $_wifiData");
          notifyListeners();
        }
      }
    } catch (e) {
      printLog("Error decodificando MessagePack WiFi: $e", "rojo");
    }
  }

  // Agregar nuevos datos WiFi sin reemplazar los existentes
  void appendWifiData(List<int> messagePack) {
    try {
      // Decodificar MessagePack
      final decoded = deserialize(Uint8List.fromList(messagePack));

      if (decoded is Map) {
        bool hasNewData = false;

        decoded.forEach((key, value) {
          if (value is Map) {
            String ssid = key.toString();
            Map<String, dynamic> networkData = Map<String, dynamic>.from(value);

            // Solo agregar si no existe o si cambió
            if (!_wifiData.containsKey(ssid) ||
                _wifiData[ssid].toString() != networkData.toString()) {
              _wifiData[ssid] = networkData;
              hasNewData = true;
            }
          }
        });

        if (hasNewData) {
          // Actualizar también la variable global
          wifiAvailableData = _wifiData;
          printLog("Nuevos datos WiFi agregados: $_wifiData");
          notifyListeners();
        }
      }
    } catch (e) {
      printLog("Error decodificando MessagePack WiFi: $e", "rojo");
    }
  }

  // Limpiar datos
  void clearWifiData() {
    _wifiData.clear();
    wifiAvailableData.clear();
    notifyListeners();
  }
}

//*-WiFi Stored Networks Notifier, redes guardadas desde BLE-*\\
class WiFiStoredNotifier extends ChangeNotifier {
  Map<String, String> _storedNetworks = {};

  // Obtener redes guardadas
  Map<String, String> getStoredNetworks() {
    return _storedNetworks;
  }

  // Verificar si tiene redes guardadas
  bool hasStoredNetworks() {
    return _storedNetworks.isNotEmpty;
  }

  // Actualizar redes guardadas desde MessagePack
  void updateStoredNetworks(List<int> messagePack) {
    try {
      printLog("Intentando decodificar MessagePack...");
      printLog("Datos recibidos length: ${messagePack.length}");
      printLog("A deserializar: ${Uint8List.fromList(messagePack)}");

      // Decodificar MessagePack
      final decoded = deserialize(Uint8List.fromList(messagePack));
      printLog("MessagePack decodificado exitosamente");
      printLog("Tipo de dato decodificado: ${decoded.runtimeType}");
      printLog("Contenido decodificado: $decoded");

      if (decoded is Map) {
        Map<String, String> newStoredNetworks = {};

        decoded.forEach((key, value) {
          newStoredNetworks[key.toString()] = value.toString();
        });

        if (_storedNetworks.toString() != newStoredNetworks.toString()) {
          _storedNetworks = newStoredNetworks;
          printLog("Redes guardadas actualizadas: $_storedNetworks");
          notifyListeners();
        } else {
          printLog("No hay cambios en las redes guardadas");
        }
      } else {
        printLog("El dato decodificado no es un Map: ${decoded.runtimeType}");
      }
    } catch (e) {
      printLog("Error decodificando MessagePack redes guardadas: $e", "rojo");
      printLog("Stack trace: ${StackTrace.current}");

      // Intentar decodificar como texto plano para debug
      try {
        String textData = String.fromCharCodes(messagePack);
        printLog("Datos como texto: '$textData'");
      } catch (textError) {
        printLog("Tampoco se puede decodificar como texto: $textError");
      }
    }
  }

  // Limpiar redes guardadas
  void clearStoredNetworks() {
    _storedNetworks.clear();
    notifyListeners();
  }
}
//*-WiFi Stored Networks Notifier-*\\
//*-Provider, actualización de data en un widget-*\\

//*-QR Scan, lee datos de qr wifi-*\\
class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});
  @override
  QRScanPageState createState() => QRScanPageState();
}

class QRScanPageState extends State<QRScanPage>
    with SingleTickerProviderStateMixin {
  Barcode? result;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController controller = MobileScannerController();
  AnimationController? animationController;
  bool flashOn = false;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    animation = Tween<double>(begin: 10, end: 350).animate(animationController!)
      ..addListener(() {
        setState(() {});
      });

    animationController!.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        MobileScanner(
          controller: controller,
          onDetect: (
            barcode,
          ) {
            setState(() {
              result = barcode.barcodes.first;
            });
            if (result != null) {
              Navigator.pop(context, result!.rawValue);
            }
          },
        ),
        // Arriba
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
              color: color1.withValues(alpha: 0.88),
              child: const Center(
                child: Text(
                  'Escanea el QR',
                  style: TextStyle(
                    color: color4,
                  ),
                ),
              )),
        ),
        // Abajo
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
            color: color1.withValues(alpha: 0.88),
          ),
        ),
        // Izquierda
        Positioned(
          top: 250,
          bottom: 250,
          left: 0,
          width: 50,
          child: Container(
            color: color1.withValues(alpha: 0.88),
          ),
        ),
        // Derecha
        Positioned(
          top: 250,
          bottom: 250,
          right: 0,
          width: 50,
          child: Container(
            color: color1.withValues(alpha: 0.88),
          ),
        ),
        // Área transparente con bordes redondeados
        Positioned(
          top: 250,
          left: 50,
          right: 50,
          bottom: 250,
          child: Stack(
            children: [
              Positioned(
                top: animation.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  color: color1,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: color4,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: color4,
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Container(
                  width: 3,
                  color: color4,
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Container(
                  width: 3,
                  color: color4,
                ),
              ),
            ],
          ),
        ),
        // Botón de Flash
        Positioned(
          bottom: 20,
          right: 20,
          child: IconButton(
            icon: Icon(
              controller.value.torchState.rawValue == 0
                  ? Icons.flash_on
                  : Icons.flash_off,
              color: color4,
            ),
            onPressed: () => controller.toggleTorch(),
          ),
        ),
      ]),
    );
  }
}
//*-QR Scan, lee datos de qr wifi-*\\

//*-CurvedNativationAppBar*-\\
class CurvedNavigationBar extends StatefulWidget {
  final List<Widget> items;
  final int index;
  final Color color;
  final Color? buttonBackgroundColor;
  final Color backgroundColor;
  final ValueChanged<int>? onTap;
  final LetIndexPage letIndexChange;
  final Curve animationCurve;
  final Duration animationDuration;
  final double height;
  final double? maxWidth;

  CurvedNavigationBar({
    super.key,
    required this.items,
    this.index = 0,
    this.color = Colors.white,
    this.buttonBackgroundColor,
    this.backgroundColor = Colors.blueAccent,
    this.onTap,
    LetIndexPage? letIndexChange,
    this.animationCurve = Curves.easeOut,
    this.animationDuration = const Duration(milliseconds: 600),
    this.height = 75.0,
    this.maxWidth,
  })  : letIndexChange = letIndexChange ?? ((_) => true),
        assert(items.isNotEmpty),
        assert(0 <= index && index < items.length),
        assert(0 <= height && height <= 75.0),
        assert(maxWidth == null || 0 <= maxWidth);

  @override
  CurvedNavigationBarState createState() => CurvedNavigationBarState();
}

class CurvedNavigationBarState extends State<CurvedNavigationBar>
    with SingleTickerProviderStateMixin {
  late double _startingPos;
  late int _endingIndex;
  late double _pos;
  double _buttonHide = 0;
  late Widget _icon;
  late AnimationController _animationController;
  late int _length;

  @override
  void initState() {
    super.initState();
    _icon = widget.items[widget.index];
    _length = widget.items.length;
    _pos = widget.index / _length;
    _startingPos = widget.index / _length;
    _endingIndex = widget.index;
    _animationController = AnimationController(vsync: this, value: _pos);
    _animationController.addListener(() {
      setState(() {
        _pos = _animationController.value;
        final endingPos = _endingIndex / widget.items.length;
        final middle = (endingPos + _startingPos) / 2;
        if ((endingPos - _pos).abs() < (_startingPos - _pos).abs()) {
          _icon = widget.items[_endingIndex];
        }
        _buttonHide =
            (1 - ((middle - _pos) / (_startingPos - middle)).abs()).abs();
      });
    });
  }

  @override
  void didUpdateWidget(CurvedNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      final newPosition = widget.index / _length;
      _startingPos = _pos;
      _endingIndex = widget.index;
      _animationController.animateTo(newPosition,
          duration: widget.animationDuration, curve: widget.animationCurve);
    }
    if (!_animationController.isAnimating) {
      _icon = widget.items[_endingIndex];
    }
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = min(
              constraints.maxWidth, widget.maxWidth ?? constraints.maxWidth);
          return Align(
            alignment: textDirection == TextDirection.ltr
                ? Alignment.bottomLeft
                : Alignment.bottomRight,
            child: Container(
              color: widget.backgroundColor,
              width: maxWidth,
              child: ClipRect(
                clipper: NavCustomClipper(
                  deviceHeight: MediaQuery.sizeOf(context).height,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Positioned(
                      bottom: -40 - (75.0 - widget.height),
                      left: textDirection == TextDirection.rtl
                          ? null
                          : _pos * maxWidth,
                      right: textDirection == TextDirection.rtl
                          ? _pos * maxWidth
                          : null,
                      width: maxWidth / _length,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            -(1 - _buttonHide) * 80,
                          ),
                          child: Material(
                            color: widget.buttonBackgroundColor ?? widget.color,
                            type: MaterialType.circle,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _icon,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0 - (75.0 - widget.height),
                      child: CustomPaint(
                        painter: NavCustomPainter(
                            _pos, _length, widget.color, textDirection),
                        child: Container(
                          height: 75.0,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0 - (75.0 - widget.height),
                      child: SizedBox(
                          height: 100.0,
                          child: Row(
                              children: widget.items.map((item) {
                            return NavButton(
                              onTap: _buttonTap,
                              position: _pos,
                              length: _length,
                              index: widget.items.indexOf(item),
                              child: Center(child: item),
                            );
                          }).toList())),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void setPage(int index) {
    _buttonTap(index);
  }

  void _buttonTap(int index) {
    if (!widget.letIndexChange(index) || _animationController.isAnimating) {
      return;
    }
    if (widget.onTap != null) {
      widget.onTap!(index);
    }
    final newPosition = index / _length;
    setState(() {
      _startingPos = _pos;
      _endingIndex = index;
      _animationController.animateTo(newPosition,
          duration: widget.animationDuration, curve: widget.animationCurve);
    });
  }
}

class NavCustomPainter extends CustomPainter {
  late double loc;
  late double s;
  Color color;
  TextDirection textDirection;

  NavCustomPainter(
      double startingLoc, int itemsLength, this.color, this.textDirection) {
    final span = 1.0 / itemsLength;
    s = 0.2;
    double l = startingLoc + (span - s) / 2;
    loc = textDirection == TextDirection.rtl ? 0.8 - l : l;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo((loc - 0.1) * size.width, 0)
      ..cubicTo(
        (loc + s * 0.20) * size.width,
        size.height * 0.05,
        loc * size.width,
        size.height * 0.60,
        (loc + s * 0.50) * size.width,
        size.height * 0.60,
      )
      ..cubicTo(
        (loc + s) * size.width,
        size.height * 0.60,
        (loc + s - s * 0.20) * size.width,
        size.height * 0.05,
        (loc + s + 0.1) * size.width,
        0,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return this != oldDelegate;
  }
}

class NavButton extends StatelessWidget {
  final double position;
  final int length;
  final int index;
  final ValueChanged<int> onTap;
  final Widget child;

  const NavButton({
    super.key,
    required this.onTap,
    required this.position,
    required this.length,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final desiredPosition = 1.0 / length * index;
    final difference = (position - desiredPosition).abs();
    final verticalAlignment = 1 - length * difference;
    final opacity = length * difference;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          onTap(index);
        },
        child: SizedBox(
          height: 75.0,
          child: Transform.translate(
            offset: Offset(
                0, difference < 1.0 / length ? verticalAlignment * 40 : 0),
            child: Opacity(
                opacity: difference < 1.0 / length * 0.99 ? opacity : 1.0,
                child: child),
          ),
        ),
      ),
    );
  }
}

class NavCustomClipper extends CustomClipper<Rect> {
  final double deviceHeight;

  NavCustomClipper({required this.deviceHeight});

  @override
  Rect getClip(Size size) {
    //Clip only the bottom of the widget
    return Rect.fromLTWH(
      0,
      -deviceHeight + size.height,
      size.width,
      deviceHeight,
    );
  }

  @override
  bool shouldReclip(NavCustomClipper oldClipper) {
    return oldClipper.deviceHeight != deviceHeight;
  }
}
//*-CurvedNativationAppBar*-\\

//*-AnimSearchBar*-\\
class AnimSearchBar extends StatefulWidget {
  final double width;
  final TextEditingController textController;
  final Icon? suffixIcon;
  final Icon? prefixIcon;
  final String helpText;
  final int animationDurationInMilli;
  final dynamic onSuffixTap;
  final bool rtl;
  final bool autoFocus;
  final TextStyle? style;
  final bool closeSearchOnSuffixTap;
  final Color? color;
  final Color? textFieldColor;
  final Color? searchIconColor;
  final Color? textFieldIconColor;
  final List<TextInputFormatter>? inputFormatters;
  final bool boxShadow;
  final Function(String) onSubmitted;

  const AnimSearchBar({
    super.key,

    /// The width cannot be null
    required this.width,

    /// The textController cannot be null
    required this.textController,
    this.suffixIcon,
    this.prefixIcon,
    this.helpText = "Search...",

    /// choose your custom color
    this.color = Colors.white,

    /// choose your custom color for the search when it is expanded
    this.textFieldColor = Colors.white,

    /// choose your custom color for the search when it is expanded
    this.searchIconColor = Colors.black,

    /// choose your custom color for the search when it is expanded
    this.textFieldIconColor = Colors.black,

    /// The onSuffixTap cannot be null
    required this.onSuffixTap,
    this.animationDurationInMilli = 375,

    /// The onSubmitted cannot be null
    required this.onSubmitted,

    /// make the search bar to open from right to left
    this.rtl = false,

    /// make the keyboard to show automatically when the searchbar is expanded
    this.autoFocus = false,

    /// TextStyle of the contents inside the searchbar
    this.style,

    /// close the search on suffix tap
    this.closeSearchOnSuffixTap = false,

    /// enable/disable the box shadow decoration
    this.boxShadow = true,

    /// can add list of inputformatters to control the input
    this.inputFormatters,
    required Null Function() onTap,
  });

  @override
  AnimSearchBarState createState() => AnimSearchBarState();
}

class AnimSearchBarState extends State<AnimSearchBar>
    with SingleTickerProviderStateMixin {
  ///initializing the AnimationController
  late AnimationController _con;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    ///Initializing the animationController which is responsible for the expanding and shrinking of the search bar
    _con = AnimationController(
      vsync: this,

      /// animationDurationInMilli is optional, the default value is 375
      duration: Duration(milliseconds: widget.animationDurationInMilli),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _con.dispose();
    focusNode.dispose();
  }

  unfocusKeyboard() {
    final FocusScopeNode currentScope = FocusScope.of(context);
    if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.0,

      ///if the rtl is true, search bar will be from right to left
      alignment:
          widget.rtl ? Alignment.centerRight : const Alignment(-1.0, 0.0),

      ///Using Animated container to expand and shrink the widget
      child: AnimatedContainer(
        duration: Duration(milliseconds: widget.animationDurationInMilli),
        height: 48.0,
        width: (toggle == 0) ? 48.0 : widget.width,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          /// can add custom  color or the color will be white
          color: toggle == 1 ? widget.textFieldColor : widget.color,
          borderRadius: BorderRadius.circular(30.0),

          /// show boxShadow unless false was passed
          boxShadow: !widget.boxShadow
              ? null
              : [
                  const BoxShadow(
                    color: Colors.black26,
                    spreadRadius: -10.0,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
        ),
        child: Stack(
          children: [
            ///Using Animated Positioned widget to expand and shrink the widget
            AnimatedPositioned(
              duration: Duration(milliseconds: widget.animationDurationInMilli),
              top: 6.0,
              right: 7.0,
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: (toggle == 0) ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    /// can add custom color or the color will be white
                    color: widget.color,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: AnimatedBuilder(
                    builder: (context, widget) {
                      ///Using Transform.rotate to rotate the suffix icon when it gets expanded
                      return Transform.rotate(
                        angle: _con.value * 2.0 * pi,
                        child: widget,
                      );
                    },
                    animation: _con,
                    child: GestureDetector(
                      onTap: () {
                        try {
                          ///trying to execute the onSuffixTap function
                          widget.onSuffixTap();

                          // * if field empty then the user trying to close bar
                          if (textFieldValue == '') {
                            unfocusKeyboard();
                            setState(() {
                              toggle = 0;
                            });

                            ///reverse == close
                            _con.reverse();
                          }

                          // * why not clear textfield here?
                          widget.textController.clear();
                          textFieldValue = '';

                          ///closeSearchOnSuffixTap will execute if it's true
                          if (widget.closeSearchOnSuffixTap) {
                            unfocusKeyboard();
                            setState(() {
                              toggle = 0;
                            });
                          }
                        } catch (e) {
                          ///print the error if the try block fails
                          printLog(e);
                        }
                      },

                      ///suffixIcon is of type Icon
                      child: widget.suffixIcon ??
                          Icon(
                            Icons.close,
                            size: 20.0,
                            color: widget.textFieldIconColor,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: widget.animationDurationInMilli),
              left: (toggle == 0) ? 20.0 : 40.0,
              curve: Curves.easeOut,
              top: 11.0,

              ///Using Animated opacity to change the opacity of th textField while expanding
              child: AnimatedOpacity(
                opacity: (toggle == 0) ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.only(left: 10),
                  alignment: Alignment.topCenter,
                  width: widget.width / 1.7,
                  child: TextField(
                    ///Text Controller. you can manipulate the text inside this textField by calling this controller.
                    controller: widget.textController,
                    inputFormatters: widget.inputFormatters,
                    focusNode: focusNode,
                    cursorRadius: const Radius.circular(10.0),
                    cursorWidth: 2.0,
                    onChanged: (value) {
                      textFieldValue = value;
                    },
                    onSubmitted: (value) => {
                      widget.onSubmitted(value),
                      unfocusKeyboard(),
                      setState(() {
                        toggle = 0;
                      }),
                      widget.textController.clear(),
                    },
                    onEditingComplete: () {
                      /// on editing complete the keyboard will be closed and the search bar will be closed
                      unfocusKeyboard();
                      setState(() {
                        toggle = 0;
                      });
                    },

                    ///style is of type TextStyle, the default is just a color black
                    style: widget.style ?? const TextStyle(color: Colors.black),
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(bottom: 5),
                      isDense: true,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      labelText: widget.helpText,
                      labelStyle: const TextStyle(
                        color: Color(0xff5B5B5B),
                        fontSize: 17.0,
                        fontWeight: FontWeight.w500,
                      ),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            ///Using material widget here to get the ripple effect on the prefix icon
            Material(
              /// can add custom color or the color will be white
              /// toggle button color based on toggle state
              color: toggle == 0 ? widget.color : widget.textFieldColor,
              borderRadius: BorderRadius.circular(30.0),
              child: IconButton(
                splashRadius: 19.0,

                ///if toggle is 1, which means it's open. so show the back icon, which will close it.
                ///if the toggle is 0, which means it's closed, so tapping on it will expand the widget.
                ///prefixIcon is of type Icon
                icon: widget.prefixIcon != null
                    ? toggle == 1
                        ? Icon(
                            Icons.arrow_back_ios,
                            color: widget.textFieldIconColor,
                          )
                        : widget.prefixIcon!
                    : Icon(
                        toggle == 1 ? Icons.arrow_back_ios : Icons.search,
                        // search icon color when closed
                        color: toggle == 0
                            ? widget.searchIconColor
                            : widget.textFieldIconColor,
                        size: 20.0,
                      ),
                onPressed: () {
                  setState(
                    () {
                      ///if the search bar is closed
                      if (toggle == 0) {
                        toggle = 1;
                        setState(() {
                          ///if the autoFocus is true, the keyboard will pop open, automatically
                          if (widget.autoFocus) {
                            FocusScope.of(context).requestFocus(focusNode);
                          }
                        });

                        ///forward == expand
                        _con.forward();
                      } else {
                        ///if the search bar is expanded
                        toggle = 0;

                        ///if the autoFocus is true, the keyboard will close, automatically
                        setState(() {
                          if (widget.autoFocus) unfocusKeyboard();
                        });

                        ///reverse == close
                        _con.reverse();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//*-AnimSearchBar*-\\

//*-ThumbSlider-*//
class IconThumbSlider extends SliderComponentShape {
  final IconData iconData;
  final double thumbRadius;

  const IconThumbSlider({required this.iconData, required this.thumbRadius});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw the thumb as a circle
    final paint = Paint()
      ..color = sliderTheme.thumbColor!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, thumbRadius, paint);

    // Draw the icon on the thumb
    TextSpan span = TextSpan(
      style: TextStyle(
        fontSize: thumbRadius,
        fontFamily: iconData.fontFamily,
        color: sliderTheme.valueIndicatorColor,
      ),
      text: String.fromCharCode(iconData.codePoint),
    );
    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    Offset iconOffset = Offset(
      center.dx - (tp.width / 2),
      center.dy - (tp.height / 2),
    );
    tp.paint(canvas, iconOffset);
  }
}
//*-ThumbSlider-*//

//*-Easter egg-*\\
class EasterEggs {
  static List<String> legajosMeme = [
    '1865',
    '1860',
    '1799',
    '1750',
    '1928',
    '1982',
    '1988',
  ];

  static Widget things(String legajo) {
    switch (legajo) {
      case '1860':
        return Image.asset('assets/eg/Mecha.gif');
      case '1928':
        return Image.asset('assets/eg/kiwi.webp');
      case '1865':
        return Image.asset('assets/eg/Vaca.webp');
      case '1750':
        return Image.asset('assets/eg/cucaracha.gif');
      case '1799':
        return Image.asset('assets/eg/puto.jpeg');
      case '1982':
        return Image.asset('assets/eg/cateat.gif');
      case '1988':
        return Image.asset('assets/eg/cat.gif');
      default:
        return const SizedBox.shrink();
    }
  }

  static Widget profile(String legajo) {
    switch (legajo) {
      case '1860':
        return Image.asset('assets/eg/Lautaro.webp');
      case '1928':
        return Image.asset('assets/eg/javi.webp');
      case '1865':
        return Image.asset('assets/eg/Gonzalo.webp');
      case '1750':
        return Image.asset('assets/eg/joaco.webp');
      case '1799':
        return Image.asset('assets/eg/Cristian.webp');
      default:
        return const SizedBox.shrink();
    }
  }

  static String loading(String legajo) {
    switch (legajo) {
      case '1860':
        return 'assets/eg/Mecha.gif';
      case '1928':
        return 'assets/eg/kiwi.webp';
      case '1865':
        return 'assets/eg/Vaca.webp';
      case '1750':
        return 'assets/eg/goose.gif';
      case '1799':
        return 'assets/eg/puto.jpeg';
      case '1982':
        return 'assets/eg/cateat.gif';
      case '1988':
        return 'assets/eg/cat.gif';
      default:
        return 'assets/Loading.gif';
    }
  }
}
//*-Easter egg-*\\
