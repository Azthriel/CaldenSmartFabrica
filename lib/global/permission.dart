import 'dart:io';

import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler extends StatefulWidget {
  const PermissionHandler({super.key});

  @override
  PermissionHandlerState createState() => PermissionHandlerState();
}

class PermissionHandlerState extends State<PermissionHandler> {
  Future<void> permissionCheck() async {
    PermissionStatus permissionStatus1 =
        await Permission.bluetoothConnect.request();

    if (!permissionStatus1.isGranted) {
      await Permission.bluetoothConnect.request();
    }
    permissionStatus1 = await Permission.bluetoothConnect.status;

    PermissionStatus permissionStatus2 =
        await Permission.bluetoothScan.request();

    if (!permissionStatus2.isGranted) {
      await Permission.bluetoothScan.request();
    }
    permissionStatus2 = await Permission.bluetoothScan.status;

    PermissionStatus permissionStatus3 = await Permission.location.request();

    if (!permissionStatus3.isGranted) {
      await Permission.location.request();
    }
    permissionStatus3 = await Permission.location.status;

    printLog('Ble: ${permissionStatus1.isGranted} /// $permissionStatus1');
    printLog('Ble Scan: ${permissionStatus2.isGranted} /// $permissionStatus2');
    printLog('Locate: ${permissionStatus3.isGranted} /// $permissionStatus3');

    if (permissionStatus1.isGranted &&
        permissionStatus2.isGranted &&
        permissionStatus3.isGranted) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else if (permissionStatus3.isGranted && Platform.isIOS) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permisos requeridos'),
            content: const Text(
                'No se puede seguir sin los permisos\n Por favor activalos manualmente'),
            actions: [
              TextButton(
                child: const Text('Abrir opciones de la app'),
                onPressed: () => openAppSettings(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Ocurrió el siguiente error: ${snapshot.error}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          );
        } else {
          return const Scaffold(
            backgroundColor: Colors.black,
          );
        }
      },
      future: permissionCheck(),
    );
  }
}
