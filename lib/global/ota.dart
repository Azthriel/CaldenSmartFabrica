import 'dart:convert';

import 'package:caldensmartfabrica/aws/mqtt/mqtt.dart';
import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';

class OtaGlobalPage extends StatefulWidget {
  const OtaGlobalPage({super.key});

  @override
  State<OtaGlobalPage> createState() => OtaGlobalPagePageState();
}

class OtaGlobalPagePageState extends State<OtaGlobalPage> {
  final TextEditingController verSoftController = TextEditingController();
  final TextEditingController verHardController = TextEditingController();
  final TextEditingController productCodeController = TextEditingController();
  bool productCodeAdded = false;
  bool versionSoftAdded = false;
  bool versionHardAdded = false;
  String productCode = '';

  @override
  void dispose() {
    verSoftController.dispose();
    verHardController.dispose();
    productCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4, // Fondo de la página
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.center,
          child: Text(
            'OTA Global',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color4),
          ),
        ),
        backgroundColor: color1, // Fondo del AppBar
        foregroundColor: color3, // Color de los textos del AppBar
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Código de producto
              Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: color0,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color3.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: productCodeController,
                  onChanged: (value) {
                    productCodeAdded = true;
                    if (productCodeController.text.contains('_IOT')) {
                      productCode = productCodeController.text.trim();
                    } else {
                      productCode = '${productCodeController.text.trim()}_IOT';
                    }
                    setState(() {});
                  },
                  style: const TextStyle(color: color4),
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Ingrese código de producto',
                    labelStyle: const TextStyle(
                        color: color3,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    hintStyle: TextStyle(color: color3.withOpacity(0.7)),
                    suffixIcon: productCodeAdded
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 28)
                        : const Icon(Icons.cancel_rounded,
                            color: Colors.red, size: 28),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Versión de software
              Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: color0,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color3.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: verSoftController,
                  onChanged: (value) {
                    versionSoftAdded = true;
                    setState(() {});
                  },
                  style: const TextStyle(color: color4),
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Ingrese versión de software',
                    labelStyle: const TextStyle(
                        color: color3,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    hintStyle: TextStyle(color: color3.withOpacity(0.7)),
                    suffixIcon: versionSoftAdded
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 28)
                        : const Icon(Icons.cancel_rounded,
                            color: Colors.red, size: 28),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Versión de hardware
              Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: color0,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color3.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: verHardController,
                  onChanged: (value) {
                    versionHardAdded = true;
                    setState(() {});
                  },
                  style: const TextStyle(color: color4),
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Ingrese versión de hardware',
                    labelStyle: const TextStyle(
                        color: color3,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    hintStyle: TextStyle(color: color3.withOpacity(0.7)),
                    suffixIcon: versionHardAdded
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 28)
                        : const Icon(Icons.cancel_rounded,
                            color: Colors.red, size: 28),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Botón para hacer OTA global
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color1, // Color de fondo del botón
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  shadowColor: color3.withOpacity(0.4),
                ),
                onPressed: () {
                  if (versionSoftAdded &&
                      versionHardAdded &&
                      productCodeAdded) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text(
                            '¿Estás seguro?',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'Enviar OTA sin estar seguro puede afectar el funcionamiento de los equipos.',
                            style: TextStyle(fontSize: 16),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Cancelar',
                                  style: TextStyle(fontSize: 16)),
                            ),
                            TextButton(
                              onPressed: () {
                                registerActivity('Global', 'OTA',
                                    'Se envió OTA global para los equipos $productCode. DATA: ${verHardController.text.trim()}#${verSoftController.text.trim()}');
                                String topic = 'tools/$productCode/global';
                                String msg = jsonEncode({
                                  'cmd': '2',
                                  'content':
                                      '${verHardController.text.trim()}#${verSoftController.text.trim()}'
                                });
                                sendMessagemqtt(topic, msg);

                                setState(() {
                                  productCodeAdded = false;
                                  versionSoftAdded = false;
                                  versionHardAdded = false;
                                  productCodeController.clear();
                                  verHardController.clear();
                                  verSoftController.clear();
                                  productCode = '';
                                });
                                showToast('OTA realizada con éxito');
                                Navigator.of(dialogContext).pop();
                              },
                              child: const Text('Hacer OTA',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    showToast(
                        'Debes agregar todas las versiones antes de enviar la OTA');
                  }
                },
                child: const Text(
                  'Hacer OTA global',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
