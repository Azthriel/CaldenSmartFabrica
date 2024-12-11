import 'package:flutter/material.dart';
import '../../aws/dynamo/dynamo.dart';
import '../../aws/dynamo/dynamo_certificates.dart';
import '../../master.dart';

class ParamsTab extends StatefulWidget {
  const ParamsTab({super.key});
  @override
  State<ParamsTab> createState() => ParamsTabState();
}

class ParamsTabState extends State<ParamsTab> {
  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;
    return Scaffold(
      backgroundColor: color4,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              buildText(
                text: '',
                textSpans: [
                  const TextSpan(
                    text: 'Estado del control por distancia en el equipo:\n',
                    style:
                        TextStyle(color: color4, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: distanceControlActive ? 'Activado' : 'Desactivado',
                    style: TextStyle(
                        color:
                            distanceControlActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ],
                fontSize: 20.0,
                textAlign: TextAlign.center,
              ),
              if (distanceControlActive) ...[
                const SizedBox(height: 10),
                buildButton(
                  text: 'Desactivar control por distancia',
                  onPressed: () {
                    String mailData =
                        '${DeviceManager.getProductCode(deviceName)} ';
                    myDevice.toolsUuid.write(mailData.codeUnits);
                    registerActivity(
                      DeviceManager.getProductCode(deviceName),
                      DeviceManager.extractSerialNumber(deviceName),
                      'Se desactivo el control por distancia',
                    );
                    setState(() {
                      distanceControlActive = false;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
              buildText(
                text: '',
                textSpans: [
                  const TextSpan(
                    text: 'Owner actual del equipo:\n',
                    style:
                        TextStyle(color: color4, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: owner == '' ? 'No hay owner registrado' : owner,
                    style: TextStyle(
                        color: owner == '' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                ],
                fontSize: 20.0,
                textAlign: TextAlign.center,
              ),
              if (owner != '') ...[
                const SizedBox(height: 10),
                buildButton(
                  text: 'Eliminar Owner',
                  onPressed: () {
                    putOwner(service, DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName), '');
                    registerActivity(
                      DeviceManager.getProductCode(deviceName),
                      DeviceManager.extractSerialNumber(deviceName),
                      'Se elimino el owner del equipo',
                    );
                    setState(() {
                      owner = '';
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 5),
              if (secondaryAdmins.isEmpty) ...[
                buildText(
                  text: 'No hay administradores \nsecundarios para este equipo',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ] else ...[
                buildText(
                  text: 'Administradores del equipo:',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                if (secondaryAdmins.isNotEmpty) ...{
                  for (int i = 0; i < secondaryAdmins.length; i++) ...[
                    const Divider(color: color1),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              registerActivity(
                                DeviceManager.getProductCode(deviceName),
                                DeviceManager.extractSerialNumber(deviceName),
                                'Se elimino el admin ${secondaryAdmins[i]} del equipo',
                              );
                              setState(() {
                                secondaryAdmins.removeAt(i);
                              });
                              putSecondaryAdmins(
                                service,
                                DeviceManager.getProductCode(deviceName),
                                DeviceManager.extractSerialNumber(deviceName),
                                secondaryAdmins,
                              );
                            },
                            icon: const Icon(Icons.delete, color: color1),
                          ),
                          Text(
                            secondaryAdmins[i],
                            style: const TextStyle(
                                fontSize: 20.0,
                                color: color0,
                                fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                } else
                  ...{},
                const Divider(color: color1),
              ],
              const SizedBox(height: 10),
              buildText(
                text: '',
                textSpans: [
                  const TextSpan(
                    text:
                        'Vencimiento beneficio\nAdministradores secundarios extra:\n',
                    style:
                        TextStyle(color: color4, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: secAdmDate,
                    style: TextStyle(
                        color: secAdmDate == 'No tiene activado este beneficio'
                            ? Colors.red
                            : Colors.yellow,
                        fontWeight: FontWeight.bold),
                  ),
                ],
                fontSize: 20.0,
                textAlign: TextAlign.center,
              ),
              buildButton(
                text: 'Modificar fecha',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final TextEditingController dateController =
                          TextEditingController();
                      return AlertDialog(
                        backgroundColor: color1,
                        title: const Center(
                          child: Text(
                            'Especificar nueva fecha de vencimiento:',
                            style: TextStyle(
                                color: color4, fontWeight: FontWeight.bold),
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 300,
                              child: TextField(
                                style: const TextStyle(color: color4),
                                controller: dateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'aaaa/mm/dd',
                                  hintStyle: TextStyle(color: color4),
                                ),
                                onChanged: (value) {
                                  if (value.length > 10) {
                                    dateController.text =
                                        value.substring(0, 10);
                                  } else if (value.length == 4) {
                                    dateController.text = '$value/';
                                  } else if (value.length == 7) {
                                    dateController.text = '$value/';
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              navigatorKey.currentState!.pop();
                            },
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: color4),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              registerActivity(
                                  DeviceManager.getProductCode(deviceName),
                                  DeviceManager.extractSerialNumber(deviceName),
                                  'Se modifico el vencimiento del beneficio "alquiler temporario"');
                              putDate(
                                  service,
                                  DeviceManager.getProductCode(deviceName),
                                  DeviceManager.extractSerialNumber(deviceName),
                                  dateController.text.trim(),
                                  true);
                              setState(() {
                                atDate = dateController.text.trim();
                              });
                              navigatorKey.currentState!.pop();
                            },
                            child: const Text(
                              'Enviar fecha',
                              style: TextStyle(color: color4),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              buildText(
                text: '',
                textSpans: [
                  const TextSpan(
                    text: 'Vencimiento beneficio\nAlquiler temporario:\n',
                    style:
                        TextStyle(color: color4, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: atDate,
                    style: TextStyle(
                        color: secAdmDate == 'No tiene activado este beneficio'
                            ? Colors.red
                            : Colors.yellow,
                        fontWeight: FontWeight.bold),
                  ),
                ],
                fontSize: 20.0,
                textAlign: TextAlign.center,
              ),
              buildButton(
                text: 'Modificar fecha',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final TextEditingController dateController =
                          TextEditingController();
                      return AlertDialog(
                        backgroundColor: color1,
                        title: const Center(
                          child: Text(
                            'Especificar nueva fecha de vencimiento:',
                            style: TextStyle(
                                color: color4, fontWeight: FontWeight.bold),
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 300,
                              child: TextField(
                                style: const TextStyle(color: color4),
                                controller: dateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'aaaa/mm/dd',
                                  hintStyle: TextStyle(color: color4),
                                ),
                                onChanged: (value) {
                                  if (value.length > 10) {
                                    dateController.text =
                                        value.substring(0, 10);
                                  } else if (value.length == 4) {
                                    dateController.text = '$value/';
                                  } else if (value.length == 7) {
                                    dateController.text = '$value/';
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              navigatorKey.currentState!.pop();
                            },
                            child: const Text('Cancelar',
                                style: TextStyle(color: color4)),
                          ),
                          TextButton(
                            onPressed: () {
                              registerActivity(
                                  DeviceManager.getProductCode(deviceName),
                                  DeviceManager.extractSerialNumber(deviceName),
                                  'Se modifico el vencimiento del beneficio "alquiler temporario"');
                              putDate(
                                  service,
                                  DeviceManager.getProductCode(deviceName),
                                  DeviceManager.extractSerialNumber(deviceName),
                                  dateController.text.trim(),
                                  true);
                              setState(() {
                                atDate = dateController.text.trim();
                              });
                              navigatorKey.currentState!.pop();
                            },
                            child: const Text('Enviar fecha',
                                style: TextStyle(color: color4)),
                          ),
                        ],
                      );
                    },
                  );
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
