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

  void _showAddSecondaryAdminDialog() {
    final TextEditingController adminController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: color1, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Agregar Administrador Secundario',
                  style: TextStyle(color: color1, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingrese el email del usuario que será administrador secundario:',
                  style: TextStyle(color: color0),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: adminController,
                  decoration: InputDecoration(
                    labelText: 'Email del administrador',
                    labelStyle: const TextStyle(color: color1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: color1, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.email, color: color1),
                  ),
                  style: const TextStyle(color: color0),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar', style: TextStyle(color: color2)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                String newAdmin = adminController.text.trim();
                if (newAdmin.isNotEmpty) {
                  // Verificar que no sea duplicado
                  if (!secondaryAdmins.contains(newAdmin)) {
                    setState(() {
                      secondaryAdmins.add(newAdmin);
                    });
                    putSecondaryAdmins(
                      pc,
                      sn,
                      secondaryAdmins,
                    );
                    registerActivity(
                      pc,
                      sn,
                      'Se agrego el admin $newAdmin al equipo',
                    );
                    Navigator.of(context).pop();
                  } else {
                    // Mostrar error si ya existe
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Este administrador ya existe'),
                        backgroundColor: color2,
                      ),
                    );
                  }
                }
              },
              child: const Text('Agregar', style: TextStyle(color: color4)),
            ),
          ],
        );
      },
    );
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
                // Administradores secundarios
                const SizedBox(height: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            secondaryAdmins.isNotEmpty
                                ? color1.withValues(alpha: 0.1)
                                : color3.withValues(alpha: 0.1),
                            color4,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.group,
                                size: 30,
                                color: secondaryAdmins.isNotEmpty
                                    ? color1
                                    : color3,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Administradores Secundarios',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: color1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (secondaryAdmins.isEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color3.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: color3.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: color3, size: 24),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No hay administradores secundarios para este equipo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: color2,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            for (int i = 0;
                                i < secondaryAdmins.length;
                                i++) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: color1.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: color1.withValues(alpha: 0.2)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: color1,
                                    child: Text(
                                      secondaryAdmins[i][0].toUpperCase(),
                                      style: const TextStyle(
                                        color: color4,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    secondaryAdmins[i],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: color0,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Administrador ${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: color2,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            title: const Row(
                                              children: [
                                                Icon(Icons.warning,
                                                    color: color2, size: 28),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Confirmar eliminación',
                                                    style: TextStyle(
                                                        color: color2,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: Text(
                                              '¿Estás seguro de que deseas eliminar a "${secondaryAdmins[i]}" de los administradores secundarios?',
                                              style: const TextStyle(
                                                  color: color0),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Cancelar',
                                                    style: TextStyle(
                                                        color: color3)),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: color2,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
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
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Eliminar',
                                                    style: TextStyle(
                                                        color: color4)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: color2,
                                      size: 24,
                                    ),
                                    tooltip: 'Eliminar administrador',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              // Botón para agregar administrador secundario
              const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: buildButton(
                  text: 'Agregar Administrador Secundario',
                  onPressed: _showAddSecondaryAdminDialog,
                ),
              ),
              const SizedBox(height: 30),
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
              if (discTimes.isNotEmpty) ...[
                const SizedBox(height: 20),
                buildText(
                  text: 'Tiempos de desconexión:',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  alignment: Alignment.center,
                  widthFactor: 0.9,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: color0,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: color4,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          for (int i = discTimes.length - 1; i >= 0; i--) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: () {
                                final dateTime =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(discTimes[i]));
                                final date =
                                    '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
                                final time =
                                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: color4,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: color4,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                );
                              }(),
                            ),
                            if (i > 0)
                              const Divider(
                                  color: color1, height: 1, thickness: 1),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (connecTimes.isNotEmpty) ...[
                const SizedBox(height: 20),
                buildText(
                  text: 'Tiempos de conexión:',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  alignment: Alignment.center,
                  widthFactor: 0.9,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: color0,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: color4,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          for (int i = connecTimes.length - 1; i >= 0; i--) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: () {
                                final dateTime =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(connecTimes[i]));
                                final date =
                                    '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
                                final time =
                                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: color4,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: color4,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                );
                              }(),
                            ),
                            if (i > 0)
                              const Divider(
                                  color: color1, height: 1, thickness: 1),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
