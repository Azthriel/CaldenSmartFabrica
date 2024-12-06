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
    return Scaffold(
      backgroundColor: const Color(0xff190019),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text('Estado del control por\n distancia en el equipo:',
                  textAlign: TextAlign.center,
                  style: (TextStyle(
                      fontSize: 20.0,
                      color: Color(0xfffbe4d8),
                      fontWeight: FontWeight.bold))),
              Text.rich(
                TextSpan(
                  text: distanceControlActive ? 'Activado' : 'Desactivado',
                  style: (const TextStyle(
                      fontSize: 20.0,
                      color: Color(0xFFdfb6b2),
                      fontWeight: FontWeight.normal)),
                ),
              ),
              if (distanceControlActive) ...[
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () {
                    String mailData =
                        '${DeviceManager.getProductCode(deviceName)}[5](0)';
                    myDevice.toolsUuid.write(mailData.codeUnits);
                    registerActivity(
                        DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName),
                        'Se desactivo el control por distancia');
                    setState(() {
                      distanceControlActive = false;
                    });
                  },
                  child: const Text(
                    'Desacticar control por distancia',
                  ),
                ),
              ],
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Owner actual del equipo:',
                textAlign: TextAlign.center,
                style: (TextStyle(
                    fontSize: 20.0,
                    color: Color(0xfffbe4d8),
                    fontWeight: FontWeight.bold)),
              ),
              Text(
                owner == '' ? 'No hay owner registrado' : owner,
                textAlign: TextAlign.center,
                style: (const TextStyle(
                    fontSize: 20.0,
                    color: Color(0xFFdfb6b2),
                    fontWeight: FontWeight.bold)),
              ),
              if (owner != '') ...[
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () {
                    putOwner(service, DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName), '');
                    registerActivity(
                        DeviceManager.getProductCode(deviceName),
                        DeviceManager.extractSerialNumber(deviceName),
                        'Se elimino el owner del equipo');
                    setState(() {
                      owner = '';
                    });
                  },
                  child: const Text(
                    'Eliminar Owner',
                  ),
                ),
              ],
              const SizedBox(
                height: 20,
              ),
              if (secondaryAdmins.isEmpty) ...[
                const Text(
                  'No hay administradores \nsecundarios para este equipo',
                  textAlign: TextAlign.center,
                  style: (TextStyle(
                      fontSize: 20.0,
                      color: Color(0xfffbe4d8),
                      fontWeight: FontWeight.bold)),
                )
              ] else ...[
                const Text(
                  'Administradores del equipo:',
                  textAlign: TextAlign.center,
                  style: (TextStyle(
                      fontSize: 20.0,
                      color: Color(0xfffbe4d8),
                      fontWeight: FontWeight.bold)),
                ),
                for (int i = 0; i < secondaryAdmins.length; i++) ...[
                  const Divider(),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () {
                              registerActivity(
                                  DeviceManager.getProductCode(deviceName),
                                  DeviceManager.extractSerialNumber(deviceName),
                                  'Se elimino el admin ${secondaryAdmins[i]} del equipo');
                              setState(() {
                                secondaryAdmins.remove(secondaryAdmins[i]);
                              });
                              putSecondaryAdmins(
                                  service,
                                  DeviceManager.getProductCode(deviceName),
                                  DeviceManager.extractSerialNumber(deviceName),
                                  secondaryAdmins);
                            },
                            icon: const Icon(Icons.delete, color: Colors.grey),
                          ),
                          Text(
                            secondaryAdmins[i],
                            style: (const TextStyle(
                                fontSize: 20.0,
                                color: Color(0xFFdfb6b2),
                                fontWeight: FontWeight.normal)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                ],
                const Divider(),
              ],
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Vencimiento beneficio\nAdministradores secundarios extra:',
                textAlign: TextAlign.center,
                style: (TextStyle(
                    fontSize: 20.0,
                    color: Color(0xfffbe4d8),
                    fontWeight: FontWeight.bold)),
              ),
              Text(
                secAdmDate,
                textAlign: TextAlign.center,
                style: (const TextStyle(
                    fontSize: 20.0,
                    color: Color(0xFFdfb6b2),
                    fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final TextEditingController dateController =
                          TextEditingController();
                      return AlertDialog(
                        title: const Center(
                          child: Text(
                            'Especificar nueva fecha de vencimiento:',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 300,
                              child: TextField(
                                style: const TextStyle(color: Colors.black),
                                controller: dateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'aaaa/mm/dd',
                                  hintStyle: TextStyle(color: Colors.black),
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
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              registerActivity(
                                  DeviceManager.getProductCode(deviceName),
                                  DeviceManager.extractSerialNumber(deviceName),
                                  'Se modifico el vencimiento del beneficio "administradores secundarios extras"');
                              putDate(
                                  service,
                                  DeviceManager.getProductCode(deviceName),
                                  DeviceManager.extractSerialNumber(deviceName),
                                  dateController.text.trim(),
                                  false);
                              setState(() {
                                secAdmDate = dateController.text.trim();
                              });
                              navigatorKey.currentState!.pop();
                            },
                            child: const Text('Enviar fecha'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text(
                  'Modificar fecha',
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Vencimiento beneficio\nAlquiler temporario:',
                textAlign: TextAlign.center,
                style: (TextStyle(
                    fontSize: 20.0,
                    color: Color(0xfffbe4d8),
                    fontWeight: FontWeight.bold)),
              ),
              Text(
                atDate,
                textAlign: TextAlign.center,
                style: (const TextStyle(
                    fontSize: 20.0,
                    color: Color(0xFFdfb6b2),
                    fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final TextEditingController dateController =
                          TextEditingController();
                      return AlertDialog(
                        title: const Center(
                          child: Text(
                            'Especificar nueva fecha de vencimiento:',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 300,
                              child: TextField(
                                style: const TextStyle(color: Colors.black),
                                controller: dateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'aaaa/mm/dd',
                                  hintStyle: TextStyle(color: Colors.black),
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
                            child: const Text('Cancelar'),
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
                            child: const Text('Enviar fecha'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text(
                  'Modificar fecha',
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
