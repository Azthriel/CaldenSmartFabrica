import 'package:flutter/material.dart';
import '../../aws/dynamo/dynamo.dart';
import '../../master.dart';

class ParamsTab extends StatefulWidget {
  const ParamsTab({super.key});
  @override
  State<ParamsTab> createState() => ParamsTabState();
}

class ParamsTabState extends State<ParamsTab> {
  final String pc = DeviceManager.getProductCode(deviceName);
  final String sn = DeviceManager.extractSerialNumber(deviceName);

  bool canBeRiego = false;

  @override
  void initState() {
    super.initState();
    canBeRiego = (pc == '020010_IOT' ||
        pc == '020020_IOT' ||
        (pc == '027313_IOT' &&
            Versioner.isPosterior(hardwareVersion, '241220A')));

    printLog('Riego: $canBeRiego');
  }

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
                    putDistanceControl(pc, sn, false);
                    registerActivity(
                      pc,
                      sn,
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
                    putOwner(pc, sn, '');
                    registerActivity(
                      pc,
                      sn,
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                registerActivity(
                                  pc,
                                  sn,
                                  'Se elimino el admin ${secondaryAdmins[i]} del equipo',
                                );
                                setState(() {
                                  secondaryAdmins.removeAt(i);
                                });
                                putSecondaryAdmins(
                                  pc,
                                  sn,
                                  secondaryAdmins,
                                );
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: color1,
                              ),
                            ),
                            Text(
                              secondaryAdmins[i],
                              style: const TextStyle(
                                fontSize: 20.0,
                                color: color0,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
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
                              registerActivity(pc, sn,
                                  'Se modifico el vencimiento del beneficio "alquiler temporario"');
                              putDate(pc, sn, dateController.text.trim(), true);
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
                              registerActivity(pc, sn,
                                  'Se modifico el vencimiento del beneficio "alquiler temporario"');
                              putDate(pc, sn, dateController.text.trim(), true);
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
              if (canBeRiego) ...[
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'Estado del sistema de riego en el equipo:\n',
                      style:
                          TextStyle(color: color4, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: riegoActive ? 'Activado' : 'Desactivado',
                      style: TextStyle(
                          color: riegoActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                if (riegoActive) ...[
                  const SizedBox(height: 10),
                  buildButton(
                    text: 'Desactivar sistema de riego',
                    onPressed: () {
                      putRiego(pc, sn, false);
                      registerActivity(
                        pc,
                        sn,
                        'Se desactivo el sistema de riego',
                      );
                      setState(() {
                        riegoActive = false;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  const SizedBox(height: 10),
                  buildButton(
                    text: 'Activar sistema de riego',
                    onPressed: () {
                      putRiego(pc, sn, true);
                      registerActivity(
                        pc,
                        sn,
                        'Se activo el sistema de riego',
                      );
                      setState(() {
                        riegoActive = true;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'Riego master:\n',
                      style: TextStyle(
                        color: color4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: riegoMaster.isNotEmpty
                          ? riegoMaster
                          : 'No tiene riego master asignado',
                      style: TextStyle(
                        color:
                            riegoMaster.isNotEmpty ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                if (riegoMaster.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  buildButton(
                    text: 'Eliminar riego master',
                    onPressed: () {
                      putRiegoMaster(pc, sn, '');
                      registerActivity(
                        pc,
                        sn,
                        'Se elimino el riego master del equipo',
                      );
                      setState(() {
                        riegoMaster = '';
                      });
                    },
                  ),
                ],
                const SizedBox(height: 20),
              ],
              if (pc == '023430_IOT') ...[
                const SizedBox(height: 20),
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'Histórico de temperaturas premium:\n',
                      style:
                          TextStyle(color: color4, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: historicTempPremium ? 'Activado' : 'Desactivado',
                      style: TextStyle(
                          color:
                              historicTempPremium ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                buildButton(
                  text: historicTempPremium ? 'Desactivar' : 'Activar',
                  onPressed: () {
                    putHistoricTempPremium(pc, sn, !historicTempPremium);
                    registerActivity(
                      pc,
                      sn,
                      historicTempPremium
                          ? 'Se desactivo el beneficio histórico de temperaturas premium'
                          : 'Se activo el beneficio histórico de temperaturas premium',
                    );
                    setState(() {
                      historicTempPremium = !historicTempPremium;
                    });
                  },
                )
              ],
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
