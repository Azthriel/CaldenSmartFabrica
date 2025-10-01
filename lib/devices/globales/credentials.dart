import 'dart:convert';
import 'package:caldensmartfabrica/secret.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msgpack_dart/msgpack_dart.dart';
import '../../master.dart';

class CredsTab extends StatefulWidget {
  const CredsTab({super.key});
  @override
  CredsTabState createState() => CredsTabState();
}

class CredsTabState extends State<CredsTab> {
  bool sending = false;

  Future<void> createAndSendThings() async {
    setState(() {
      sending = true;
    });
    Uri uri = Uri.parse(createThingURL);

    final pc = DeviceManager.getProductCode(deviceName);
    final sn = DeviceManager.extractSerialNumber(deviceName);

    // Verifica si el número de serie es igual al código de producto sin "_IOT" y con "00" al final
    final defaultSerial = '${pc.replaceAll('_IOT', '')}00';
    if (sn == defaultSerial || sn == '57730810') {
      showToast(
          'El dispositivo tiene el número de serie por defecto ($defaultSerial).');
      setState(() {
        sending = false;
      });
      return;
    }

    String thingName = '$pc:$sn';

    String bd = jsonEncode({'thingName': thingName});

    printLog('Body: $bd');
    var response = await http.post(uri, body: bd);
    if (response.statusCode == 200) {
      printLog('Respuesta: ${response.body}');
      showToast('Thing creado: $thingName');

      registerActivity(pc, sn, 'Cree $thingName');

      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      Map<String, dynamic> body = jsonDecode(jsonResponse['body']);

      String amazonCA = body['amazonCA'];
      String deviceCert = body['deviceCert'];
      String privateKey = body['privateKey'];

      printLog('Certificado: $deviceCert', "Cyan");
      printLog('Llave privada: $privateKey', "Cyan");
      printLog('Amazon CA: $amazonCA', "Cyan");
      printLog('Certificado público: $publicCert', "Cyan");

      // Envía cada certificado al puerto asignado
      for (String line in amazonCA.split('\n')) {
        if (line.isEmpty || line == ' ') break;
        printLog(line, "Cyan");
        if (bluetoothManager.newGeneration) {
          Map<String, dynamic> command = {
            "root_ca": line,
          };
          List<int> messagePackData = serialize(command);
          await bluetoothManager.awsUuid.write(messagePackData);
        } else {
          String datatoSend = '$pc[6](0#$line)';
          await bluetoothManager.toolsUuid
              .write(datatoSend.codeUnits, withoutResponse: false);
        }
      }
      for (String line in deviceCert.split('\n')) {
        if (line.isEmpty || line == ' ') break;
        printLog(line, "Cyan");
        if (bluetoothManager.newGeneration) {
          Map<String, dynamic> command = {
            "ca_cert": line,
          };
          List<int> messagePackData = serialize(command);
          await bluetoothManager.awsUuid.write(messagePackData);
        } else {
          String datatoSend = '$pc[6](1#$line)';
          await bluetoothManager.toolsUuid
              .write(datatoSend.codeUnits, withoutResponse: false);
        }
      }
      for (String line in privateKey.split('\n')) {
        if (line.isEmpty || line == ' ') break;
        printLog(line, "Cyan");
        if (bluetoothManager.newGeneration) {
          Map<String, dynamic> command = {
            "private_key": line,
          };
          List<int> messagePackData = serialize(command);
          await bluetoothManager.awsUuid.write(messagePackData);
        } else {
          String datatoSend = '$pc[6](2#$line)';
          await bluetoothManager.toolsUuid
              .write(datatoSend.codeUnits, withoutResponse: false);
        }
      }
      if (bluetoothManager.newGeneration) {
        for (String line in publicCert.split('\n')) {
          if (line.isEmpty || line == ' ') break;
          printLog(line, "Cyan");
          Map<String, dynamic> command = {
            "device_sig": line,
          };
          List<int> messagePackData = serialize(command);
          await bluetoothManager.awsUuid.write(messagePackData);
        }
      }
      registerActivity(
          pc, sn, 'Envié los certificados de $thingName al equipo');
    } else {
      printLog('Error: ${response.statusCode}');
      showToast('Error al crear el Thing: $thingName');
      registerActivity(pc, sn, 'Fallo el proceso de $thingName');
    }
  }

  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;
    return Scaffold(
      backgroundColor: color4,
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              buildText(
                // text: '¿Thing cargada? ${awsInit ? 'SI' : 'NO'}',
                text: '',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                // color: awsInit ? color4 : const Color(0xffFF0000),
                textSpans: [
                  const TextSpan(
                    text: '¿Thing cargada?  ',
                    style: TextStyle(
                      color: color4,
                    ),
                  ),
                  TextSpan(
                    text: bluetoothManager.newGeneration
                        ? bluetoothManager.data['aws_init']
                            ? 'SI'
                            : 'NO'
                        : (awsInit || isConnectedToAWS)
                            ? 'SI'
                            : 'NO',
                    style: TextStyle(
                      color: bluetoothManager.newGeneration
                          ? (bluetoothManager.data['aws_init']
                              ? color4
                              : const Color(0xffFF0000))
                          : (awsInit || isConnectedToAWS)
                              ? color4
                              : const Color(0xffFF0000),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              buildText(
                text: '',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                textSpans: [
                  const TextSpan(
                    text: '¿Está conectado al servidor?  ',
                    style: TextStyle(
                      color: color4,
                    ),
                  ),
                  TextSpan(
                    text: isConnectedToAWS ? 'SI' : 'NO',
                    style: TextStyle(
                      color:
                          isConnectedToAWS ? color4 : const Color(0xffFF0000),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              if (!isConnectedToAWS) ...[
                sending
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EasterEggs.things(legajoConectado),
                          const LinearProgressIndicator(),
                        ],
                      )
                    : buildButton(
                        text: 'Crear y enviar Thing',
                        onPressed: () async {
                          await createAndSendThings();
                          setState(() {
                            sending = false;
                          });
                          if (bluetoothManager.newGeneration) {
                            Map<String, dynamic> command = {
                              "reboot": {'erase_nvs': false},
                            };
                            List<int> messagePackData = serialize(command);
                            bluetoothManager.appDataUuid.write(messagePackData);
                          } else {
                            bluetoothManager.toolsUuid.write(
                                '${DeviceManager.getProductCode(deviceName)}[0](0)'
                                    .codeUnits);
                          }
                        },
                      ),
                const SizedBox(
                  height: 20,
                ),
              ],
              if (accessLevel == 3) ...[
                buildButton(
                  text: 'Borrar thing del equipo',
                  onPressed: () async {
                    Uri uri = Uri.parse(deleteThingURL);

                    final pc = DeviceManager.getProductCode(deviceName);
                    final sn = DeviceManager.extractSerialNumber(deviceName);

                    // Verifica si el número de serie es igual al código de producto sin "_IOT" y con "00" al final
                    final defaultSerial = '${pc.replaceAll('_IOT', '')}00';
                    if (sn == defaultSerial || sn == '57730810') {
                      showToast(
                          'El dispositivo tiene el número de serie por defecto ($defaultSerial).');
                      setState(() {
                        sending = false;
                      });
                      return;
                    }

                    String thingName = '$pc:$sn';

                    String bd = jsonEncode({'thingName': thingName});

                    printLog('Body: $bd');
                    var response = await http.post(uri, body: bd);

                    if (response.statusCode == 200) {
                      printLog('Respuesta: ${response.body}');

                      // Parsear la respuesta JSON para obtener el statusCode real
                      final responseData = jsonDecode(response.body);
                      final actualStatusCode = responseData['statusCode'];

                      if (actualStatusCode == 200) {
                        showToast('Thing borrado: $thingName');

                        registerActivity(
                            pc, sn, 'Se borró la thing con nombre $thingName');
                        if (bluetoothManager.newGeneration) {
                          Map<String, dynamic> command = {
                            "delete_thing": true,
                          };
                          List<int> messagePackData = serialize(command);
                          bluetoothManager.awsUuid.write(messagePackData);
                        }
                      } else {
                        // Obtener el mensaje de error del body
                        final errorBody = jsonDecode(responseData['body']);
                        final errorMessage =
                            errorBody['error'] ?? 'Error desconocido';

                        printLog('Error del Lambda: $errorMessage');
                        showToast('Error al borrar el Thing: $errorMessage');
                        registerActivity(pc, sn,
                            'Fallo el borrado de $thingName: $errorMessage');
                      }
                    } else {
                      printLog('Error HTTP: ${response.statusCode}');
                      showToast('Error de conexión al borrar el Thing');
                      registerActivity(
                          pc, sn, 'Error de conexión al borrar $thingName');
                    }
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
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
