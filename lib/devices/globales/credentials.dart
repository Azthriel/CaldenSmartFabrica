import 'package:flutter/material.dart';
import '../../master.dart';

class CredsTab extends StatefulWidget {
  const CredsTab({super.key});
  @override
  CredsTabState createState() => CredsTabState();
}

class CredsTabState extends State<CredsTab> {
  TextEditingController amazonCAController = TextEditingController();
  TextEditingController privateKeyController = TextEditingController();
  TextEditingController deviceCertController = TextEditingController();
  String? amazonCA;
  String? privateKey;
  String? deviceCert;
  bool sending = false;

  @override
  void dispose() {
    amazonCAController.dispose();
    privateKeyController.dispose();
    deviceCertController.dispose();
    super.dispose();
  }

  Future<void> writeLarge(String value, int thing, String device,
      {int timeout = 15}) async {
    List<String> sublist = value.split('\n');
    for (var line in sublist) {
      // printLog('Mande chunk');
      String datatoSend =
          '${DeviceManager.getProductCode(deviceName)}[6]($thing#$line)';
      printLog(datatoSend);
      await myDevice.toolsUuid
          .write(datatoSend.codeUnits, withoutResponse: false);
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
              buildTextField(
                controller: amazonCAController,
                label: 'Ingresa Amazon CA cert',
                hint: 'Introduce el certificado Amazon CA',
                keyboard: TextInputType.multiline,
                onSubmitted: (text) {},
                onChanged: (value) {
                  amazonCA = amazonCAController.text;
                  amazonCAController.text = 'Cargado';
                },
              ),
              const SizedBox(height: 10),
              buildTextField(
                controller: privateKeyController,
                label: 'Ingresa la Private Key',
                hint: 'Introduce la Private key',
                keyboard: TextInputType.multiline,
                onSubmitted: (text) {},
                onChanged: (value) {
                  privateKey = privateKeyController.text;
                  privateKeyController.text = 'Cargado';
                },
              ),
              const SizedBox(height: 10),
              buildTextField(
                controller: deviceCertController,
                label: 'Ingresa Device Cert',
                hint: 'Introduce el certificado del dispositivo',
                keyboard: TextInputType.multiline,
                onSubmitted: (text) {},
                onChanged: (value) {
                  deviceCert = deviceCertController.text;
                  deviceCertController.text = 'Cargado';
                },
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
                      text: 'Enviar certificados',
                      onPressed: () async {
                        printLog(amazonCA);
                        printLog(privateKey);
                        printLog(deviceCert);
                        if (amazonCA != null &&
                            privateKey != null &&
                            deviceCert != null) {
                          printLog('Estan todos anashe');
                          registerActivity(
                            DeviceManager.getProductCode(deviceName),
                            DeviceManager.extractSerialNumber(deviceName),
                            'Se asignó credenciales de AWS al equipo',
                          );
                          setState(() {
                            sending = true;
                          });
                          await writeLarge(amazonCA!, 0, deviceName);
                          await writeLarge(deviceCert!, 1, deviceName);
                          await writeLarge(privateKey!, 2, deviceName);
                          setState(() {
                            sending = false;
                          });
                          myDevice.toolsUuid.write(
                              '${DeviceManager.getProductCode(deviceName)}[0](0)'
                                  .codeUnits);
                        }
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
    );
  }
}
