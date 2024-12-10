import 'package:flutter/material.dart';

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
    String dataToSend = textController.text;
    String data = '${DeviceManager.getProductCode(deviceName)}[4]($dataToSend)';
    try {
      await myDevice.toolsUuid.write(data.codeUnits);
    } catch (e) {
      printLog(e);
    }
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
            buildButton(
              text: 'Borrar NVS',
              onPressed: () {
                registerActivity(
                  DeviceManager.getProductCode(deviceName),
                  DeviceManager.extractSerialNumber(deviceName),
                  'Se borró la NVS de este equipo...',
                );
                myDevice.toolsUuid.write(
                    '${DeviceManager.getProductCode(deviceName)} '.codeUnits);
              },
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
