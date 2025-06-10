import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    Uri uri = Uri.parse(
      'https://7afkb3q46b.execute-api.sa-east-1.amazonaws.com/v1/THINGS',
    );

    final pc = DeviceManager.getProductCode(deviceName);
    final sn = DeviceManager.extractSerialNumber(deviceName);

    // Verifica si el número de serie es igual al código de producto sin "_IOT" y con "00" al final
    final defaultSerial = '${pc.replaceAll('_IOT', '')}00';
    if (sn == defaultSerial) {
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

      registerActivity(pc, sn, 'Cree $thingName y lo cargué al equipo');

      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      Map<String, dynamic> body = jsonDecode(jsonResponse['body']);

      String amazonCA = body['amazonCA'];
      String deviceCert = body['deviceCert'];
      String privateKey = body['privateKey'];

      printLog('Certificado: $deviceCert', "Cyan");
      printLog('Llave privada: $privateKey', "Cyan");
      printLog('Amazon CA: $amazonCA', "Cyan");

      // Envía cada certificado al puerto asignado
      for (String line in amazonCA.split('\n')) {
        if (line.isEmpty || line == ' ') break;
        printLog(line, "Cyan");
        String datatoSend = '$pc[6](0#$line)';
        await myDevice.toolsUuid
            .write(datatoSend.codeUnits, withoutResponse: false);
        // await Future.delayed(const Duration(milliseconds: 200));
      }
      for (String line in deviceCert.split('\n')) {
        if (line.isEmpty || line == ' ') break;
        printLog(line, "Cyan");
        String datatoSend = '$pc[6](1#$line)';
        await myDevice.toolsUuid
            .write(datatoSend.codeUnits, withoutResponse: false);
        // await Future.delayed(const Duration(milliseconds: 200));
      }
      for (String line in privateKey.split('\n')) {
        if (line.isEmpty || line == ' ') break;
        printLog(line, "Cyan");
        String datatoSend = '$pc[6](2#$line)';
        await myDevice.toolsUuid
            .write(datatoSend.codeUnits, withoutResponse: false);
        // await Future.delayed(const Duration(milliseconds: 200));
      }
    } else {
      printLog('Error: ${response.statusCode}');
      showToast('Error al crear el Thing: $thingName');
      registerActivity(pc, sn, 'Fallo la creación de $thingName');
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
                    text: awsInit ? 'SI' : 'NO',
                    style: TextStyle(
                      color: awsInit ? color4 : const Color(0xffFF0000),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              buildText(
                // text: '¿Thing cargada? ${awsInit ? 'SI' : 'NO'}',
                text: '',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                // color: awsInit ? color4 : const Color(0xffFF0000),
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
              const SizedBox(height: 10),
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
                        myDevice.toolsUuid.write(
                            '${DeviceManager.getProductCode(deviceName)}[0](0)'
                                .codeUnits);
                      }),
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
