import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../aws/dynamo/dynamo.dart';
import '../aws/dynamo/dynamo_certificates.dart';
import '../master.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});
  @override
  LoadState createState() => LoadState();
}

class LoadState extends State<LoadingPage> {
  MyDevice myDevice = MyDevice();
  String _dots = '';
  int dot = 0;
  late Timer _dotTimer;
  String pc = DeviceManager.getProductCode(deviceName);

  @override
  void initState() {
    super.initState();
    printLog('HOSTIAAAAAAAAAAAAAAAAAAAAAAAA');
    _dotTimer =
        Timer.periodic(const Duration(milliseconds: 800), (Timer timer) {
      setState(
        () {
          dot++;
          if (dot >= 4) dot = 0;
          _dots = '.' * dot;
        },
      );
    });
    precharge().then((precharge) {
      if (precharge == true) {
        showToast('Dispositivo conectado exitosamente');
        switch (pc) {
          case '022000_IOT' || '027000_IOT' || '041220_IOT':
            navigatorKey.currentState?.pushReplacementNamed('/calefactor');
            break;
          case '015773_IOT':
            navigatorKey.currentState?.pushReplacementNamed('/detector');
            break;
          case '020010_IOT':
            navigatorKey.currentState?.pushReplacementNamed('/domotica');
            break;
          case '020020_IOT':
            navigatorKey.currentState?.pushReplacementNamed('/modulo');
            break;
          case '024011_IOT':
            navigatorKey.currentState?.pushReplacementNamed('/roller');
            break;
          case '027170_IOT':
            navigatorKey.currentState?.pushReplacementNamed('/patito');
            break;
          case '027313_IOT':
            if (Versioner.isPosterior(hardwareVersion, '241220A')) {
              navigatorKey.currentState?.pushReplacementNamed('/rele1i1o');
            } else {
              navigatorKey.currentState?.pushReplacementNamed('/rele');
            }

            break;
          case '050217_IOT':
            navigatorKey.currentState?.pushReplacementNamed('/millenium');
            break;
          case '028000_IOT':
            navigatorKey.currentState?.pushReplacementNamed('/heladera');
            break;
        }
      } else {
        showToast('Error en el dispositivo, intente nuevamente');
        myDevice.device.disconnect();
      }
    });
  }

  @override
  void dispose() {
    _dotTimer.cancel();
    super.dispose();
  }

  Future<bool> precharge() async {
    try {
      printLog('Estoy precargando');
      await myDevice.device.requestMtu(255);
      toolsValues = await myDevice.toolsUuid.read();
      printLog('Valores tools: $toolsValues || ${utf8.decode(toolsValues)}');
      printLog('Valores info: $infoValues || ${utf8.decode(infoValues)}');

      await queryItems(
        service,
        DeviceManager.getProductCode(deviceName),
        DeviceManager.extractSerialNumber(deviceName),
      );
//THE GAME
      switch (pc) {
        case '022000_IOT' ||
              '027000_IOT' ||
              '041120_IOT' ||
              '050217_IOT' ||
              '028000_IOT':
          varsValues = await myDevice.varsUuid.read();
          var parts2 = utf8.decode(varsValues).split(':');
          printLog('Valores vars: $parts2');
          distanceControlActive = parts2[0] == '1';
          tempValue = double.parse(parts2[1]);
          turnOn = parts2[2] == '1';
          trueStatus = parts2[4] == '1';
          nightMode = parts2[5] == '1';
          actualTemp = parts2[6];
          if (factoryMode) {
            awsInit = parts2[7] == '1';
            tempMap = parts2[8] == '1';
          }

          roomTempSended = await tempWasSended(
            DeviceManager.getProductCode(deviceName),
            DeviceManager.extractSerialNumber(deviceName),
          );

          printLog('Estado: $turnOn');
          break;
        case '015773_IOT':
          workValues = await myDevice.workUuid.read();
          if (factoryMode) {
            calibrationValues = await myDevice.calibrationUuid.read();
            regulationValues = await myDevice.regulationUuid.read();
            debugValues = await myDevice.debugUuid.read();
            awsInit = workValues[23] == 1;
          }
          printLog('Valores calibracion: $calibrationValues');
          printLog('Valores regulacion: $regulationValues');
          printLog('Valores debug: $debugValues');
          printLog('Valores trabajo: $workValues');
          printLog('Valores work: $workValues');
          break;
        case '020010_IOT' || '020020_IOT':
          ioValues = await myDevice.ioUuid.read();
          printLog('Valores IO: $ioValues || ${utf8.decode(ioValues)}');
          varsValues = await myDevice.varsUuid.read();
          printLog('Valores VARS: $varsValues || ${utf8.decode(varsValues)}');
          var parts2 = utf8.decode(varsValues).split(':');
          distanceControlActive = parts2[0] == '1';
          awsInit = parts2[1] == '1';
          burneoDone = parts2[2] == '1';
          break;
        case '027313_IOT':
          if (Versioner.isPosterior(hardwareVersion, '241220A')) {
            ioValues = await myDevice.ioUuid.read();
            printLog('Valores IO: $ioValues || ${utf8.decode(ioValues)}');
            varsValues = await myDevice.varsUuid.read();
            printLog('Valores VARS: $varsValues || ${utf8.decode(varsValues)}');
            var parts2 = utf8.decode(varsValues).split(':');
            distanceControlActive = parts2[0] == '1';
            awsInit = parts2[1] == '1';
            burneoDone = parts2[2] == '1';
          } else {
            varsValues = await myDevice.varsUuid.read();
            var parts2 = utf8.decode(varsValues).split(':');
            printLog('Valores vars: $parts2');
            distanceControlActive = parts2[0] == '1';
            turnOn = parts2[1] == '1';
            energyTimer = parts2[2];
            awsInit = parts2[3] == '1';
          }
          break;
        case '024011_IOT':
          varsValues = await myDevice.varsUuid.read();
          var parts2 = utf8.decode(varsValues).split(':');
          printLog('Valores vars: $parts2');
          distanceControlActive = parts2[0] == '1';
          rollerlength = parts2[1];
          rollerPolarity = parts2[2];
          rollerRPM = parts2[3];
          rollerMicroStep = parts2[4];
          rollerIMAX = parts2[5];
          rollerIRMSRUN = parts2[6];
          rollerIRMSHOLD = parts2[7];
          rollerFreewheeling = parts2[8] == '1';
          rollerTPWMTHRS = parts2[9];
          rollerTCOOLTHRS = parts2[10];
          rollerSGTHRS = parts2[11];
          actualPosition = int.parse(parts2[12]);
          workingPosition = int.parse(parts2[13]);
          rollerMoving = parts2[14] == '1';
          awsInit = parts2[15] == '1';
          break;
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      printLog('Error en la precarga $e $stackTrace');
      showToast('Error en la precarga');
      // handleManualError(e, stackTrace);
      return Future.value(false);
    }
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // GIF cargando
            Image.asset(
              EasterEggs.loading(legajoConectado),
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            // Texto "Cargando"
            RichText(
              text: TextSpan(
                text: 'Cargando',
                style: const TextStyle(
                  color: color4,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: _dots,
                    style: const TextStyle(
                      color: color4,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Versión
          ],
        ),
      ),
      bottomSheet: Text(
        'Versión $appVersionNumber',
        style: const TextStyle(color: color4, fontSize: 12),
      ),
    );
  }
}
