import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';
import '../aws/dynamo/dynamo.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});
  @override
  LoadState createState() => LoadState();
}

class LoadState extends State<LoadingPage> {
  String _dots = '';
  int dot = 0;
  late Timer _dotTimer;
  final String pc = DeviceManager.getProductCode(deviceName);
  final String sn = DeviceManager.extractSerialNumber(deviceName);

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
          case '023430_IOT':
            navigatorKey.currentState?.pushReplacementNamed('/termometro');
            break;
        }
      } else {
        showToast('Error en el dispositivo, intente nuevamente');
        bluetoothManager.device.disconnect();
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
      printLog("🏳️‍🌈💥 ╾━╤デ╦︻ඞ");

      Platform.isAndroid ? await bluetoothManager.device.requestMtu(255) : null;
      toolsValues = await bluetoothManager.toolsUuid.read();
      printLog('Valores tools: $toolsValues || ${utf8.decode(toolsValues)}');
      printLog('Valores info: $infoValues || ${utf8.decode(infoValues)}');

      await queryItems(
        pc,
        sn,
      );
      switch (pc) {
        case '022000_IOT' ||
              '041220_IOT' ||
              '050217_IOT' ||
              '028000_IOT' ||
              '027000_IOT':
          varsValues = await bluetoothManager.varsUuid.read();
          var parts2 = utf8.decode(varsValues).split(':');
          printLog('Valores vars: $parts2');

          if (parts2[0] == '0' || parts2[0] == '1') {
            tempValue = double.parse(parts2[1]);
            turnOn = parts2[2] == '1';
            trueStatus = parts2[4] == '1';
            nightMode = parts2[5] == '1';
            actualTemp = parts2[6];
            if (factoryMode) {
              awsInit = parts2[7] == '1';
              // tempMap = parts2[8] == '1';
              offsetTemp = parts2[8];
              parts2.length > 9
                  ? manualControl = parts2[9] == '1'
                  : manualControl = false;
            }
            printLog('Estado: $turnOn');
          } else {
            tempValue = double.parse(parts2[0]);
            turnOn = parts2[1] == '1';
            trueStatus = parts2[3] == '1';
            nightMode = parts2[4] == '1';
            actualTemp = parts2[5];
            if (factoryMode) {
              awsInit = parts2[6] == '1';
              // tempMap = parts2[7] == '1';
              offsetTemp = parts2[7];
            }
            manualControl = parts2.length > 8 ? parts2[8] == '1' : false;
            printLog('Estado: $turnOn');
          }

          hasSensor = hasDallasSensor(pc, hardwareVersion);

          if (!hasSensor) {
            roomTempSended = await tempWasSended(
              pc,
              sn,
            );
          }

          printLog('Estado: $turnOn');
          break;
        case '015773_IOT':
          workValues = await bluetoothManager.workUuid.read();
          if (factoryMode) {
            calibrationValues = await bluetoothManager.calibrationUuid.read();
            regulationValues = await bluetoothManager.regulationUuid.read();
            debugValues = await bluetoothManager.debugUuid.read();
            awsInit = workValues[23] == 1;
          }

          printLog('Valores calibracion: $calibrationValues');
          printLog('Valores regulacion: $regulationValues');
          printLog('Valores debug: $debugValues');
          printLog('Valores trabajo: $workValues');
          printLog('Valores work: $workValues');
          break;
        case '020010_IOT' || '020020_IOT':
          ioValues = await bluetoothManager.ioUuid.read();
          printLog('Valores IO: $ioValues || ${utf8.decode(ioValues)}');
          varsValues = await bluetoothManager.varsUuid.read();
          printLog('Valores VARS: $varsValues || ${utf8.decode(varsValues)}');
          var parts2 = utf8.decode(varsValues).split(':');
          distanceControlActive = parts2[0] == '1';
          awsInit = parts2[1] == '1';
          burneoDone = parts2[2] == '1';
          break;
        case '027313_IOT':
          if (Versioner.isPosterior(hardwareVersion, '241220A')) {
            ioValues = await bluetoothManager.ioUuid.read();
            printLog('Valores IO: $ioValues || ${utf8.decode(ioValues)}');
            varsValues = await bluetoothManager.varsUuid.read();
            printLog('Valores VARS: $varsValues || ${utf8.decode(varsValues)}');
            var parts2 = utf8.decode(varsValues).split(':');
            distanceControlActive = parts2[0] == '1';
            awsInit = parts2[1] == '1';
            burneoDone = parts2[2] == '1';
          } else {
            varsValues = await bluetoothManager.varsUuid.read();
            var parts2 = utf8.decode(varsValues).split(':');
            printLog('Valores vars: $parts2');
            distanceControlActive = parts2[0] == '1';
            turnOn = parts2[1] == '1';
            energyTimer = parts2[2];
            awsInit = parts2[3] == '1';
          }
          break;
        case '024011_IOT':
          varsValues = await bluetoothManager.varsUuid.read();
          var partes = utf8.decode(varsValues).split(':');
          printLog('Valores VARS: $varsValues || ${utf8.decode(varsValues)}');
          distanceControlActive = partes[0] == '1';
          rollerlength = partes[1];
          rollerPolarity = partes[2];
          rollerRPM = partes[3];
          rollerMicroStep = partes[4];
          rollerIMAX = partes[5];
          rollerIRMSRUN = partes[6];
          rollerIRMSHOLD = partes[7];
          rollerFreewheeling = partes[8] == '1';
          rollerTPWMTHRS = partes[9];
          rollerTCOOLTHRS = partes[10];
          rollerSGTHRS = partes[11];
          actualPositionGrades = int.parse(partes[12]);
          actualPosition = int.parse(partes[13]);
          workingPosition = int.parse(partes[14]);
          rollerMoving = partes[15] == '1';
          awsInit = partes[16] == '1';
          break;
        case '023430_IOT':
          varsValues = await bluetoothManager.varsUuid.read();
          var partes = utf8.decode(varsValues).split(':');
          printLog('Valores VARS: $varsValues || ${utf8.decode(varsValues)}');
          actualTemp = partes[0];
          offsetTemp = partes[1];
          awsInit = partes[2] == '1';
          alertMaxFlag = partes[3] == '1';
          alertMinFlag = partes[4] == '1';
          alertMaxTemp = partes[5];
          alertMinTemp = partes[6];
          tempMap = partes[7] == '1';
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
