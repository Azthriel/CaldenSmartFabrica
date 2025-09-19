import 'dart:convert';

import 'package:caldensmartfabrica/aws/dynamo/dynamo.dart';
import 'package:caldensmartfabrica/aws/mqtt/mqtt.dart';
import 'package:flutter/material.dart';
import 'package:msgpack_dart/msgpack_dart.dart';

import '../../master.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});
  @override
  ToolsPageState createState() => ToolsPageState();
}

class ToolsPageState extends State<ToolsPage> {
  TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void sendDataToDevice() async {
    String dataToSend = textController.text.trim();
    if (bluetoothManager.newGeneration) {
      Map<String, dynamic> command = {"change_sn": dataToSend};
      List<int> messagePackData = serialize(command);
      bluetoothManager.appDataUuid.write(messagePackData);
    } else {
      String data =
          '${DeviceManager.getProductCode(deviceName)}[4]($dataToSend)';
      try {
        await bluetoothManager.toolsUuid.write(data.codeUnits);
      } catch (e) {
        printLog(e);
      }
    }
  }

  void _finalizeProcess() async {
    final pc = DeviceManager.getProductCode(deviceName);
    final sn = DeviceManager.extractSerialNumber(deviceName);
    registerActivity(
      pc,
      sn,
      'Se finalizó el proceso de laboratorio',
    );

    final msg = jsonEncode({'LabFinished': true});

    final topic1 = 'devices_rx/$pc/$sn';
    final topic2 = 'devices_tx/$pc/$sn';

    sendMessagemqtt(topic1, msg);
    sendMessagemqtt(topic2, msg);

    if (pc == '022000_IOT' || pc == '027000_IOT' || pc == '041220_IOT') {
      //TODO: Ver que hace esto
      bluetoothManager.toolsUuid.write('$pc[7](10)'.codeUnits);
    }

    await putLabProcessFinished(pc, sn, true);

    setState(() {
      labProcessFinished = true;
    });
    showToast('Proceso de laboratorio finalizado correctamente.');
  }

  //! Visual
  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;
    return SingleChildScrollView(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text.rich(
              TextSpan(
                text: 'Número de serie',
                style: TextStyle(
                  fontSize: 30.0,
                  color: color1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                text: DeviceManager.extractSerialNumber(deviceName),
                style: const TextStyle(
                  fontSize: 30.0,
                  color: color0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (accessLevel > 1) ...{
              const SizedBox(height: 10),
              buildTextField(
                controller: textController,
                label: 'Introducir nuevo numero de serie',
                hint: 'Nuevo número de serie',
                onSubmitted: (text) {},
                widthFactor: 0.8,
                keyboard: TextInputType.number,
              ),
              buildButton(
                text: 'Enviar',
                onPressed: () {
                  registerActivity(
                    DeviceManager.getProductCode(deviceName),
                    textController.text,
                    'Se coloco el número de serie',
                  );
                  sendDataToDevice();
                },
              ),
            },
            const SizedBox(height: 10),
            buildText(
              text:
                  'Código de producto: ${DeviceManager.getProductCode(deviceName)}',
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              widthFactor: 0.8,
            ),
            buildText(
              text: 'Versión de software del módulo IOT: $softwareVersion',
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              widthFactor: 0.8,
            ),
            buildText(
              text: 'Versión de hardware del módulo IOT: $hardwareVersion',
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              widthFactor: 0.8,
            ),
            if (accessLevel > 1) ...[
              buildButton(
                text: 'Borrar NVS',
                onPressed: () {
                  registerActivity(
                    DeviceManager.getProductCode(deviceName),
                    DeviceManager.extractSerialNumber(deviceName),
                    'Se borró la NVS de este equipo...',
                  );
                  if (bluetoothManager.newGeneration) {
                    Map<String, dynamic> command = {
                      "reboot": {'erase_nvs': true}
                    };
                    List<int> messagePackData = serialize(command);
                    bluetoothManager.appDataUuid.write(messagePackData);
                  } else {
                    String data =
                        '${DeviceManager.getProductCode(deviceName)}[0](1)';
                    bluetoothManager.toolsUuid.write(data.codeUnits);
                  }
                },
              ),
              const SizedBox(
                height: 20,
              ),
              if (bluetoothManager.newGeneration) ...[
                buildButton(
                  text: 'Borrar SPIFFS',
                  onPressed: () {
                    registerActivity(
                      DeviceManager.getProductCode(deviceName),
                      DeviceManager.extractSerialNumber(deviceName),
                      'Se borró la SPIFFS de este equipo...',
                    );
                    Map<String, dynamic> command = {
                      "reboot": {'erase_spiffs': true}
                    };
                    List<int> messagePackData = serialize(command);
                    bluetoothManager.appDataUuid.write(messagePackData);
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
              buildText(
                text: '',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                textSpans: [
                  const TextSpan(
                    text: '¿Se finalizó el proceso de laboratorio?  ',
                    style: TextStyle(
                      color: color4,
                    ),
                  ),
                  TextSpan(
                    text: labProcessFinished ? 'SI' : 'NO',
                    style: TextStyle(
                      color: labProcessFinished ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              buildButton(
                  text: 'Finalizar Proceso',
                  onPressed: () {
                    if (isConnectedToAWS) {
                      showAlertDialog(
                          context,
                          false,
                          const Text(
                            '¡ESTE BOTÓN DEBE SER PRESIONADO UNICAMENTE POR LABORATORIO!',
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                              'Este botón marcará como finalizado el procedimiento de laboratorio.\nAl hacer esto, certificarás que el equipo cumplió todos sus pasos de manera correcta y sin fallos.\nEl mal uso o incumplimiento de este procedimiento causará una sanción a la persona correspondiente.\n'),
                          [
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: const Text('Aceptar'),
                              onPressed: () {
                                _finalizeProcess();
                                Navigator.pop(context);
                              },
                            ),
                          ]);
                    } else {
                      showToast(
                          "Si el equipo no tiene conexión al servidor, no puede finalizarse el proceso");
                    }
                  }),
            ],
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.only(bottom: bottomBarHeight + 20),
            ),
          ],
        ),
      ),
    );
  }
}
