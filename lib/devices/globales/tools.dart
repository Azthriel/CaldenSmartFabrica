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

  //!Visual
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text.rich(
              TextSpan(
                text: 'Número de serie',
                style: TextStyle(
                    fontSize: 30.0, color: color0, fontWeight: FontWeight.bold),
              ),
            ),
            Text.rich(
              TextSpan(
                text: DeviceManager.extractSerialNumber(deviceName),
                style: const TextStyle(
                    fontSize: 30.0, color: color0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 300,
              child: TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: color0),
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Introducir nuevo numero de serie',
                  labelStyle: TextStyle(color: color0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                registerActivity(
                  DeviceManager.getProductCode(deviceName),
                  textController.text,
                  'Se coloco el número de serie',
                );
                sendDataToDevice();
              },
              style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
              ),
              child: const Text('Enviar'),
            ),
            const SizedBox(height: 20),
            const Text.rich(
              TextSpan(
                text: 'Código de producto:',
                style: TextStyle(
                    fontSize: 20.0, color: color0, fontWeight: FontWeight.bold),
              ),
            ),
            Text.rich(
              TextSpan(
                text: DeviceManager.getProductCode(deviceName),
                style: const TextStyle(
                    fontSize: 20.0, color: color0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Text.rich(
              TextSpan(
                text: 'Version de software del modulo IOT:',
                style: TextStyle(
                    fontSize: 20.0, color: color0, fontWeight: FontWeight.bold),
              ),
            ),
            Text.rich(
              TextSpan(
                text: softwareVersion,
                style: const TextStyle(
                  fontSize: 20.0,
                  color: color0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text.rich(
              TextSpan(
                text: 'Version de hardware del modulo IOT:',
                style: TextStyle(
                  fontSize: 20.0,
                  color: color0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                text: hardwareVersion,
                style: (const TextStyle(
                    fontSize: 20.0,
                    color: color0,
                    fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                registerActivity(
                    DeviceManager.getProductCode(deviceName),
                    DeviceManager.extractSerialNumber(deviceName),
                    'Se borró la NVS de este equipo...');
                myDevice.toolsUuid.write(
                    '${DeviceManager.getProductCode(deviceName)}[0](1)'
                        .codeUnits);
              },
              style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
              ),
              child: const Text('Borrar NVS'),
            ),
          ],
        ),
      ),
    );
  }
}
