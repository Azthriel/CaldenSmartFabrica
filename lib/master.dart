import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wifi_scan/wifi_scan.dart';

//! VARIABLES !\\

//!-------------------------VERSION NUMBER-------------------------!\\
String appVersionNumber = '1.0.5';
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
String myDeviceid = '';
bool connectionFlag = false;
bool distanceControlActive = false;
bool awsInit = false;
String deviceResponseMqtt = '';
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
bool wifiError = false;
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
//*-Relacionado al wifi-*\\

//*-Relacionado al ble-*\\
MyDevice myDevice = MyDevice();
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

//*-AnimSearchBar*-\\
int toggle = 0;
String textFieldValue = '';
//*-AnimSearchBar*-\\

//*-Calefactores-*\\
bool turnOn = false;
bool trueStatus = false;
bool nightMode = false;
double distOnValue = 0.0;
double distOffValue = 0.0;
bool tempMap = false;
double tempValue = 0.0;
String actualTemp = '';
//*-Calefactores-*\\

//*- Roller -*\\
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
//*-Relé-*\\

//*-Fetch data from firestore-*\\
Map<String, dynamic> fbData = {};
//*-Fetch data from firestore-*\\

//*-Solicitudes http-*\\
Dio dio = Dio();
//*-Solicitudes http-*\\

//*-Registro temperatura ambiente enviada-*\\
bool roomTempSended = false;
String tempDate = '';
//*-Registro temperatura ambiente enviada-*\\

//*- altura de la barra -*\\
double bottomBarHeight = kBottomNavigationBarHeight;
//*- altura de la barra -*\\

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
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: color3,
    textColor: color0,
    fontSize: 16.0,
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
Future<void> sendWifitoBle(String ssid, String pass) async {
  MyDevice myDevice = MyDevice();
  String value = '$ssid#$pass';
  String deviceCommand = DeviceManager.getProductCode(deviceName);
  printLog(deviceCommand);
  String dataToSend = '$deviceCommand[1]($value)';
  printLog(dataToSend);
  try {
    await myDevice.toolsUuid.write(dataToSend.codeUnits);
    printLog('Se mando el wifi ANASHE');
  } catch (e) {
    printLog('Error al conectarse a Wifi $e');
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

  showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          // Función para construir la vista principal
          Widget buildMainView() {
            if (!_scanInProgress &&
                _wifiNetworksList.isEmpty &&
                Platform.isAndroid) {
              _fetchWiFiNetworks().then((wifiNetworks) {
                setState(() {
                  _wifiNetworksList = wifiNetworks;
                });
              });
            }

            return AlertDialog(
              backgroundColor: color1,
              title: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text.rich(
                      TextSpan(
                        text: 'Estado de conexión: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: color4,
                        ),
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: isWifiConnected ? 'Conectado' : 'Desconectado',
                        style: TextStyle(
                          color: isWifiConnected ? Colors.green : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (werror) ...[
                      Text.rich(
                        TextSpan(
                          text: 'Error: $errorMessage',
                          style: const TextStyle(
                            fontSize: 10,
                            color: color4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                          foregroundColor: WidgetStatePropertyAll(
                            color4,
                          ),
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
                    const SizedBox(height: 10),
                    if (Platform.isAndroid) ...[
                      _wifiNetworksList.isEmpty && _scanInProgress
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: color4,
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
                                  // printLog('${network.ssid}: $nivel dBm ');
                                  return nivel >= -80
                                      ? SizedBox(
                                          child: ExpansionTile(
                                            initiallyExpanded:
                                                _expandedIndex == index,
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
                                                  : // Excelente
                                                  nivel >= -67
                                                      ? Icons.signal_wifi_4_bar
                                                      : // Muy buena
                                                      nivel >= -70
                                                          ? Icons
                                                              .network_wifi_3_bar
                                                          : // Okay
                                                          nivel >= -80
                                                              ? Icons
                                                                  .network_wifi_2_bar
                                                              : // No buena
                                                              Icons
                                                                  .signal_wifi_off, // Inusable
                                              color: color4,
                                            ),
                                            title: Text(
                                              network.ssid,
                                              style: const TextStyle(
                                                color: color4,
                                              ),
                                            ),
                                            backgroundColor: color1,
                                            collapsedBackgroundColor: color1,
                                            textColor: color4,
                                            iconColor: color4,
                                            collapsedIconColor: color4,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                          color: color4,
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                          hintText:
                                                              'Escribir contraseña',
                                                          hintStyle: TextStyle(
                                                            color: color3,
                                                          ),
                                                          enabledBorder:
                                                              UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: color4,
                                                            ),
                                                          ),
                                                          focusedBorder:
                                                              UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: color4,
                                                            ),
                                                          ),
                                                          border:
                                                              UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: color4,
                                                            ),
                                                          ),
                                                        ),
                                                        obscureText: true,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _currentlySelectedSSID =
                                                                network.ssid;
                                                            _wifiPasswordsMap[
                                                                    network
                                                                        .ssid] =
                                                                value;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                },
                              ),
                            ),
                    ] else ...[
                      SingleChildScrollView(
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
                                const SizedBox(
                                  width: 8.0,
                                ),
                                Expanded(
                                  child: TextField(
                                    cursorColor: color4,
                                    style: const TextStyle(
                                      color: color4,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Agregar WiFi',
                                      hintStyle: TextStyle(
                                        color: color3,
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: color4,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: color4,
                                        ),
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
                                    style: const TextStyle(
                                      color: color4,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Contraseña',
                                      hintStyle: TextStyle(
                                        color: color3,
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: color4,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: color4,
                                        ),
                                      ),
                                    ),
                                    obscureText: true,
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
                    ]
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          openQRScanner(navigatorKey.currentContext ?? context);
                        }
                      },
                    ),
                    Platform.isAndroid
                        ? TextButton(
                            style: const ButtonStyle(),
                            child: const Text(
                              'Agregar Red',
                              style: TextStyle(
                                color: color4,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                isAddingNetwork = true;
                              });
                            },
                          )
                        : const SizedBox.shrink(),
                    TextButton(
                      style: const ButtonStyle(),
                      child: const Text(
                        'Conectar',
                        style: TextStyle(
                          color: color4,
                        ),
                      ),
                      onPressed: () {
                        if (_currentlySelectedSSID != null &&
                            _wifiPasswordsMap[_currentlySelectedSSID] != null) {
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
                            style: const TextStyle(
                              color: color4,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Agregar WiFi',
                              hintStyle: TextStyle(
                                color: color3,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: color4,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: color4,
                                ),
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
                            style: const TextStyle(
                              color: color4,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Contraseña',
                              hintStyle: TextStyle(
                                color: color3,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: color4,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: color4,
                                ),
                              ),
                            ),
                            obscureText: true,
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
                    } else {}
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      color1,
                    ),
                  ),
                  child: const Text(
                    'Agregar',
                    style: TextStyle(
                      color: color4,
                    ),
                  ),
                ),
              ],
            );
          }

          return isAddingNetwork
              ? buildAddNetworkView()
              : buildMainView(); // Mostrar la vista correspondiente
        },
      );
    },
  ).then((_) {
    _scanInProgress = false;
    _expandedIndex = null;
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
  required VoidCallback onPressed,
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
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: color4),
    ),
  );
}

///Genera un cuadro de texto generico con los parametros que le pases
Widget buildTextField({
  TextEditingController? controller,
  required String label,
  required String hint,
  required void Function(String) onSubmitted,
  double widthFactor = 0.8,
  TextInputType? keyboard,
  void Function(String)? onChanged,
  int? maxLines,
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
class MyDevice {
  static final MyDevice _singleton = MyDevice._internal();

  factory MyDevice() {
    return _singleton;
  }

  MyDevice._internal();

  late BluetoothDevice device;
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

      List<BluetoothService> services =
          await device.discoverServices(timeout: 3);

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

      switch (pc) {
        case '022000_IOT' ||
              '027000_IOT' ||
              '041220_IOT' ||
              '050217_IOT' ||
              '028000_IOT':
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
            calibrationUuid = service.characteristics.firstWhere(
                (c) => c.uuid == Guid('0147ab2a-3987-4bb8-802b-315a664eadd6'));
            regulationUuid = service.characteristics.firstWhere(
                (c) => c.uuid == Guid('961d1cdd-028f-47d0-aa2a-e0095e387f55'));
            debugUuid = service.characteristics.firstWhere(
                (c) => c.uuid == Guid('838335a1-ff5a-4344-bfdf-38bf6730de26'));
            BluetoothService otaService = services.firstWhere(
                (s) => s.uuid == Guid('33e3a05a-c397-4bed-81b0-30deb11495c7'));
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
              c.uuid == Guid('12d3c6a1-f86e-4d5b-89b5-22dc3f5c831f')); //No leo

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
          } else {
            BluetoothService espService = services.firstWhere(
                (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

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
          break;
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      printLog('Lcdtmbe $e $stackTrace');

      return Future.value(false);
    }
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
  ///Compara si la primer versión que le envías salio después que la segunda
  ///
  ///Si son iguales también retorna true
  static bool isPosterior(String myVersion, String versionToCompare) {
    int year1 = int.parse(myVersion.substring(0, 2));
    int month1 = int.parse(myVersion.substring(2, 4));
    int day1 = int.parse(myVersion.substring(4, 6));
    String letter1 = myVersion.substring(6, 7);

    int year2 = int.parse(versionToCompare.substring(0, 2));
    int month2 = int.parse(versionToCompare.substring(2, 4));
    int day2 = int.parse(versionToCompare.substring(4, 6));
    String letter2 = versionToCompare.substring(6, 7);

    if (year1 > year2) {
      return true;
    } else {
      if (month1 > month2) {
        return true;
      } else {
        if (day1 > day2) {
          return true;
        } else {
          if (letter1.compareTo(letter2) > 0 ||
              letter1.compareTo(letter2) == 0) {
            return true;
          } else {
            return false;
          }
        }
      }
    }
  }

  ///Compara si la primer versión que le envías salio antes que la segunda
  ///
  ///Si son iguales retorna false
  static bool isPrevious(String myVersion, String versionToCompare) {
    int year1 = int.parse(myVersion.substring(0, 2));
    int month1 = int.parse(myVersion.substring(2, 4));
    int day1 = int.parse(myVersion.substring(4, 6));
    String letter1 = myVersion.substring(6, 7);

    int year2 = int.parse(versionToCompare.substring(0, 2));
    int month2 = int.parse(versionToCompare.substring(2, 4));
    int day2 = int.parse(versionToCompare.substring(4, 6));
    String letter2 = versionToCompare.substring(6, 7);

    if (year1 < year2) {
      return true;
    } else {
      if (month1 < month2) {
        return true;
      } else {
        if (day1 < day2) {
          return true;
        } else {
          if (letter1.compareTo(letter2) < 0) {
            return true;
          } else {
            return false;
          }
        }
      }
    }
  }
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

//*-ThumbSlider-*//s
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
        return 'assets/eg/cucaracha.gif';
      case '1799':
        return 'assets/eg/puto.jpeg';
      default:
        return 'assets/Loading.gif';
    }
  }
}
//*-Easter egg-*\\
