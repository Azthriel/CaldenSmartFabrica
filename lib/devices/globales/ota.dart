import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:path_provider/path_provider.dart';

import '../../master.dart';

class OtaTab extends StatefulWidget {
  const OtaTab({super.key});
  @override
  OtaTabState createState() => OtaTabState();
}

class OtaTabState extends State<OtaTab> {
  var dataReceive = [];
  var dataToShow = 0;
  var progressValue = 0.0;
  TextEditingController otaSVController = TextEditingController();
  TextEditingController otaHVController = TextEditingController();
  TextEditingController otaPCController = TextEditingController();
  late Uint8List firmwareGlobal;
  bool sizeWasSend = false;
  bool _isAuto = true;
  bool _factory = false;
  final pc = DeviceManager.getProductCode(deviceName);
  final sn = DeviceManager.extractSerialNumber(deviceName);

  @override
  void dispose() {
    otaSVController.dispose();
    otaHVController.dispose();
    otaPCController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (bluetoothManager.newGeneration) {
      subToProgressNewGen();
    } else {
      subToProgress();
    }
  }

  void subToProgressNewGen() {
    final otaWifiSub =
        bluetoothManager.otaWifiUuid.onValueReceived.listen((List<int> data) {
      try {
        Map<String, dynamic> otaWifiData =
            deserialize(Uint8List.fromList(data));
        if (otaWifiData.containsKey('ota_progress')) {
          setState(() {
            progressValue = double.tryParse(otaWifiData['ota_progress']) ?? 0.0;
          });
          printLog('Progreso OTA Wifi: ${otaWifiData['ota_progress']}');
        }

        if (otaWifiData.containsKey('ota_response')) {
          showToast('Respuesta OTA Wifi: ${otaWifiData['ota_response']}');
        }
      } catch (e) {
        printLog('Error malevolo: $e');
        showToast('Error al actualizar progreso OTA Wifi');
      }
    });
    final otaBleSub =
        bluetoothManager.otaBleUuid.onValueReceived.listen((List<int> data) {
      try {
        Map<String, dynamic> otaBleData = deserialize(Uint8List.fromList(data));
        if (otaBleData.containsKey('ota_progress')) {
          setState(() {
            progressValue = double.tryParse(otaBleData['ota_progress']) ?? 0.0;
          });
          printLog('Progreso OTA BLE: ${otaBleData['ota_progress']}');
        }
        if (otaBleData.containsKey('ota_response')) {
          showToast('Respuesta OTA BLE: ${otaBleData['ota_response']}');
        }
      } catch (e) {
        printLog('Error malevolo: $e');
        showToast('Error al actualizar progreso OTA BLE');
      }
    });

    bluetoothManager.otaWifiUuid.setNotifyValue(true);
    bluetoothManager.otaBleUuid.setNotifyValue(true);

    bluetoothManager.device.cancelWhenDisconnected(otaWifiSub);
    bluetoothManager.device.cancelWhenDisconnected(otaBleSub);
  }

  void subToProgress() async {
    await bluetoothManager.otaUuid.setNotifyValue(true);

    final otaSub =
        bluetoothManager.otaUuid.onValueReceived.listen((List<int> event) {
      try {
        var fun = utf8.decode(event);
        fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
        printLog(fun);
        var parts = fun.split(':');
        if (parts[0] == 'OTAPR') {
          printLog('Se recibio');
          setState(() {
            progressValue = int.parse(parts[1]) / 100;
          });
          printLog('Progreso: ${parts[1]}');
        } else if (fun.contains('OTA:HTTP_CODE')) {
          RegExp exp = RegExp(r'\(([^)]+)\)');
          final Iterable<RegExpMatch> matches = exp.allMatches(fun);

          for (final RegExpMatch match in matches) {
            String valorEntreParentesis = match.group(1)!;
            showToast('HTTP CODE recibido: $valorEntreParentesis');
          }
        } else {
          switch (fun) {
            case 'OTA:START':
              showToast('Iniciando actualización');
              break;
            case 'OTA:SUCCESS':
              printLog('Estreptococo');
              navigatorKey.currentState?.pushReplacementNamed('/menu');
              showToast("OTA completada exitosamente");
              break;
            case 'OTA:FAIL':
              showToast("Fallo al enviar OTA");
              break;
            case 'OTA:OVERSIZE':
              showToast("El archivo es mayor al espacio reservado");
              break;
            case 'OTA:WIFI_LOST':
              showToast("Se perdió la conexión wifi");
              break;
            case 'OTA:HTTP_LOST':
              showToast("Se perdió la conexión HTTP durante la actualización");
              break;
            case 'OTA:STREAM_LOST':
              showToast("Excepción de stream durante la actualización");
              break;
            case 'OTA:NO_WIFI':
              showToast("Dispositivo no conectado a una red Wifi");
              break;
            case 'OTA:HTTP_FAIL':
              showToast("No se pudo iniciar una peticion HTTP");
              break;
            case 'OTA:NO_ROLLBACK':
              showToast("Imposible realizar un rollback");
              break;
            default:
              break;
          }
        }
      } catch (e, stackTrace) {
        printLog('Error malevolo: $e $stackTrace');
        // handleManualError(e, stackTrace);
        // showToast('Error al actualizar progreso');
      }
    });
    bluetoothManager.device.cancelWhenDisconnected(otaSub);
  }

  void sendAutoOTA({
    required bool factory,
  }) async {
    final fileName =
        await Versioner.fetchLatestFirmwareFile(pc, hardwareVersion, factory);
    String url = Versioner.buildFirmwareUrl(pc, fileName, factory);
    printLog('URL del firmware: $url');

    registerActivity(pc, sn, 'Envié OTA automatica con el file: $fileName');

    try {
      if (isWifiConnected) {
        printLog('Si mandé ota Wifi');
        printLog('url: $url');
        if (bluetoothManager.newGeneration) {
          Map<String, dynamic> command = {
            "ota_url": url,
          };
          List<int> messagePackData = serialize(command);
          bluetoothManager.otaWifiUuid.write(messagePackData);
          return;
        } else {
          String data = '$pc[2]($url)';
          await bluetoothManager.toolsUuid.write(data.codeUnits);
        }
      } else {
        printLog('Arranca por la derecha la OTA BLE');
        String dir = (await getApplicationDocumentsDirectory()).path;
        File file = File('$dir/firmware.bin');

        if (await file.exists()) {
          await file.delete();
        }

        var req = await http.get(Uri.parse(url));

        var bytes = req.bodyBytes;

        await file.writeAsBytes(bytes);

        var firmware = await file.readAsBytes();

        if (bluetoothManager.newGeneration) {
          Map<String, dynamic> command = {
            "ota_size": bytes.length,
          };
          List<int> messagePackData = serialize(command);
          await bluetoothManager.otaBleUuid.write(messagePackData);
        } else {
          String data = '$pc[3](${bytes.length})';
          printLog(data);
          await bluetoothManager.toolsUuid.write(data.codeUnits);
        }

        printLog("Arranco OTA");
        try {
          int chunk = 255 - 3;
          for (int i = 0; i < firmware.length; i += chunk) {
            List<int> subvalue = firmware.sublist(
              i,
              min(i + chunk, firmware.length),
            );
            if (bluetoothManager.newGeneration) {
              Map<String, dynamic> command = {
                "ota_chunk": subvalue,
              };
              List<int> messagePackData = serialize(command);
              await bluetoothManager.otaBleUuid.write(messagePackData);
            } else {
              await bluetoothManager.infoUuid
                  .write(subvalue, withoutResponse: false);
            }
          }
          printLog('Acabe');
        } catch (e, stackTrace) {
          printLog('El error es: $e $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      printLog('Error al enviar la OTA $e $stackTrace');
    }
  }

  void sendManualOTA({
    required String productCode,
    required String hardwareVersion,
    required String softwareVersion,
    required bool factory,
  }) async {
    if (productCode.isEmpty ||
        hardwareVersion.isEmpty ||
        softwareVersion.isEmpty) {
      showToast('Por favor, completa todos los campos');
      return;
    }

    if (factory && !softwareVersion.contains('_F')) {
      softwareVersion = '${softwareVersion}_F';
    }

    String url =
        'https://raw.githubusercontent.com/barberop/sime-domotica/main/'
        '$productCode/OTA_FW/${factory ? 'F' : 'W'}/hv${hardwareVersion}sv$softwareVersion.bin';

    registerActivity(pc, sn,
        'Envié OTA manual $productCode con el file: hv${hardwareVersion}sv$softwareVersion.bin');

    try {
      if (isWifiConnected) {
        printLog('Si mandé ota Wifi');
        printLog('url: $url');
        if (bluetoothManager.newGeneration) {
          Map<String, dynamic> command = {
            "ota_url": url,
          };
          List<int> messagePackData = serialize(command);
          await bluetoothManager.otaWifiUuid.write(messagePackData);
          return;
        } else {
          String data = '$pc[2]($url)';
          await bluetoothManager.toolsUuid.write(data.codeUnits);
        }
      } else {
        printLog('Arranca por la derecha la OTA BLE');
        String dir = (await getApplicationDocumentsDirectory()).path;
        File file = File('$dir/firmware.bin');

        if (await file.exists()) {
          await file.delete();
        }

        var req = await http.get(Uri.parse(url));

        var bytes = req.bodyBytes;

        await file.writeAsBytes(bytes);

        var firmware = await file.readAsBytes();

        if (bluetoothManager.newGeneration) {
          Map<String, dynamic> command = {
            "ota_size": bytes.length,
          };
          List<int> messagePackData = serialize(command);
          await bluetoothManager.otaBleUuid.write(messagePackData);
        } else {
          String data = '$pc[3](${bytes.length})';
          printLog(data);
          await bluetoothManager.toolsUuid.write(data.codeUnits);
        }
        printLog("Arranco OTA");
        try {
          int chunk = 255 - 3;
          for (int i = 0; i < firmware.length; i += chunk) {
            List<int> subvalue = firmware.sublist(
              i,
              min(i + chunk, firmware.length),
            );
            if (bluetoothManager.newGeneration) {
              Map<String, dynamic> command = {
                "ota_chunk": subvalue,
              };
              List<int> messagePackData = serialize(command);
              await bluetoothManager.otaBleUuid.write(messagePackData);
            } else {
              await bluetoothManager.infoUuid
                  .write(subvalue, withoutResponse: false);
            }
          }
          printLog('Acabe');
        } catch (e, stackTrace) {
          printLog('El error es: $e $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      printLog('Error al enviar la OTA $e $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: color4,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─────────── ChoiceChips Auto / Manual ───────────
              if (accessLevel > 2) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Auto'),
                      selected: _isAuto,
                      onSelected: (sel) => setState(() => _isAuto = true),
                      selectedColor: color1,
                      backgroundColor: color0,
                      labelStyle: TextStyle(color: _isAuto ? color4 : color1),
                      checkmarkColor: color4,
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Manual'),
                      selected: !_isAuto,
                      onSelected: (sel) => setState(() => _isAuto = false),
                      selectedColor: color1,
                      backgroundColor: color0,
                      labelStyle: TextStyle(color: !_isAuto ? color4 : color1),
                      checkmarkColor: color4,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              // ─────────── Barra de progreso OTA ───────────
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 40,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: color0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: Colors.transparent,
                        color: color1,
                      ),
                    ),
                  ),
                  Text(
                    'Progreso descarga OTA: ${progressValue.round()}%',
                    style: const TextStyle(
                      color: color4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ─────────── UI Condicional según isAuto ───────────
              if (_isAuto) ...[
                buildButton(
                    text: 'Enviar OTA Work',
                    onPressed: () => sendAutoOTA(factory: false)),
                const SizedBox(height: 12),
                buildButton(
                    text: 'Enviar OTA Factory',
                    onPressed: () => sendAutoOTA(factory: true)),
              ] else ...[
                SizedBox(
                  height: 100,
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        final text = otaPCController.text;
                        if (!text.endsWith('_IOT')) {
                          otaPCController.text = '${text}_IOT';
                          otaPCController.selection = TextSelection.collapsed(
                            offset: otaPCController.text.length,
                          );
                          printLog('Appended _IOT to productCode', 'magenta');
                        }
                      }
                    },
                    child: buildTextField(
                        label: 'Código de Producto',
                        onSubmitted: (_) {},
                        controller: otaPCController,
                        keyboard: TextInputType.number),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 100,
                  child: buildTextField(
                      label: 'Versión de Hardware',
                      onSubmitted: (_) {},
                      controller: otaHVController),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 100,
                  child: buildTextField(
                      label: 'Versión de Software',
                      onSubmitted: (_) {},
                      controller: otaSVController),
                ),
                const SizedBox(
                  height: 6,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Work'),
                      selected: !_factory,
                      onSelected: (sel) => setState(() => _factory = false),
                      selectedColor: color1,
                      backgroundColor: color0,
                      labelStyle: TextStyle(color: !_factory ? color4 : color1),
                      checkmarkColor: color4,
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Factory'),
                      selected: _factory,
                      onSelected: (sel) => setState(() => _factory = true),
                      selectedColor: color1,
                      backgroundColor: color0,
                      labelStyle: TextStyle(color: _factory ? color4 : color1),
                      checkmarkColor: color4,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildButton(
                  text: 'Enviar OTA',
                  onPressed: () => sendManualOTA(
                    productCode: otaPCController.text.trim(),
                    hardwareVersion: otaHVController.text.trim(),
                    softwareVersion: otaSVController.text.trim(),
                    factory: _factory,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.only(bottom: bottomBarHeight + 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
