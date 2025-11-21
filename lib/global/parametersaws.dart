import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';

import '../aws/dynamo/dynamo.dart';

class ParametersAWS extends StatefulWidget {
  const ParametersAWS({super.key});

  @override
  ParametersAWSState createState() => ParametersAWSState();
}

class ParametersAWSState extends State<ParametersAWS> {
  final TextEditingController serialNumberController = TextEditingController();
  String productCode = '';
  List<String> productos = [];

  // Variables para almacenar los datos del equipo
  String currentOwner = '';
  List<String> currentSecondaryAdmins = [];
  String currentSecAdmDate = '';
  String currentAtDate = '';
  bool currentDistanceControlActive = false;
  bool currentRiegoActive = false;
  String currentRiegoMaster = '';
  bool canBeRiego = false;

  @override
  void initState() {
    super.initState();
    List<dynamic> lista = fbData['Productos'] ?? [];
    productos = lista.map((item) => item.toString()).toList();
  }

  void clearVariables() {
    setState(() {
      currentOwner = '';
      currentSecondaryAdmins.clear();
      currentSecAdmDate = '';
      currentAtDate = '';
      currentDistanceControlActive = false;
      currentRiegoActive = false;
      currentRiegoMaster = '';
      canBeRiego = false;
    });
  }

  void loadEquipmentData() async {
    if (productCode.isNotEmpty && serialNumberController.text.isNotEmpty) {
      // Cargar datos del equipo desde la base de datos
      await queryItems(productCode, serialNumberController.text.trim());

      setState(() {
        // Cargar datos desde las variables globales
        currentOwner = owner;
        currentSecondaryAdmins = List.from(secondaryAdmins);
        currentSecAdmDate = secAdmDate;
        currentAtDate = atDate;
        currentDistanceControlActive = distanceControlActive;
        currentRiegoActive = riegoActive;
        currentRiegoMaster = riegoMaster;

        // Verificar si puede tener riego
        canBeRiego = (productCode == '020010_IOT' ||
            productCode == '020020_IOT' ||
            (productCode == '027313_IOT' &&
                Versioner.isPosterior(hardwareVersion, '241220A')));
      });
    }
  }

  void _showRiegoMasterDialog() {
    final TextEditingController riegoMasterController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings, color: color1, size: 24),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Asignar RiegoMaster',
                  style: TextStyle(
                    color: color1,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingrese el nombre del usuario que será RiegoMaster:',
                  style: TextStyle(color: color0, fontSize: 14),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: riegoMasterController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del RiegoMaster',
                    labelStyle: const TextStyle(color: color1, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: color1, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: const TextStyle(color: color0, fontSize: 14),
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
                if (riegoMasterController.text.trim().isNotEmpty) {
                  putRiegoMaster(
                      productCode,
                      serialNumberController.text.trim(),
                      riegoMasterController.text.trim());
                  registerActivity(
                    productCode,
                    serialNumberController.text.trim(),
                    'Se asigno RiegoMaster: ${riegoMasterController.text.trim()}',
                  );
                  setState(() {
                    currentRiegoMaster = riegoMasterController.text.trim();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Asignar', style: TextStyle(color: color4)),
            ),
          ],
        );
      },
    );
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
                  if (!currentSecondaryAdmins.contains(newAdmin)) {
                    setState(() {
                      currentSecondaryAdmins.add(newAdmin);
                    });
                    putSecondaryAdmins(
                      productCode,
                      serialNumberController.text.trim(),
                      currentSecondaryAdmins,
                    );
                    registerActivity(
                      productCode,
                      serialNumberController.text.trim(),
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
  void dispose() {
    serialNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: color4,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(65),
          child: AppBar(
            backgroundColor: color4,
            foregroundColor: color4,
            title: const Align(
              alignment: Alignment.center,
              child: Text(
                'Parámetros del Equipo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: color1,
                ),
              ),
            ),
            elevation: 0,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: color0,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: color4,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Ingrese el código de producto',
                      labelStyle: TextStyle(
                        color: color3,
                      ),
                      hintText: 'Seleccione un código',
                      hintStyle: TextStyle(color: color3),
                      border: InputBorder.none,
                    ),
                    dropdownColor: color0,
                    items:
                        productos.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: color3,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        productCode = value!;
                        clearVariables();
                      });
                      if (serialNumberController.text.isNotEmpty) {
                        loadEquipmentData();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: color0,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: color4,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: const TextStyle(color: color3),
                      controller: serialNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Ingrese el número de serie',
                        labelStyle: const TextStyle(color: color3),
                        hintStyle: const TextStyle(color: color3),
                        hintText: 'Número de serie',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              serialNumberController.clear();
                              clearVariables();
                            });
                          },
                          icon: const Icon(
                            Icons.delete_forever,
                            color: color3,
                          ),
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        loadEquipmentData();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Contenido de parámetros
                if (productCode != '' && serialNumberController.text != '') ...[
                  // Control por distancia
                  buildText(
                    text: '',
                    textSpans: [
                      const TextSpan(
                        text:
                            'Estado del control por distancia en el equipo:\n',
                        style: TextStyle(
                            color: color4, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: currentDistanceControlActive
                            ? 'Activado'
                            : 'Desactivado',
                        style: TextStyle(
                            color:
                                currentDistanceControlActive ? color1 : color2,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                    fontSize: 20.0,
                    textAlign: TextAlign.center,
                  ),
                  if (currentDistanceControlActive) ...[
                    const SizedBox(height: 10),
                    buildButton(
                      text: 'Desactivar control por distancia',
                      onPressed: () {
                        putDistanceControl(productCode,
                            serialNumberController.text.trim(), false);
                        registerActivity(
                          productCode,
                          serialNumberController.text.trim(),
                          'Se desactivo el control por distancia',
                        );
                        setState(() {
                          currentDistanceControlActive = false;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Owner del equipo
                  buildText(
                    text: '',
                    textSpans: [
                      const TextSpan(
                        text: 'Owner actual del equipo:\n',
                        style: TextStyle(
                          color: color4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: currentOwner == ''
                            ? 'No hay owner registrado'
                            : currentOwner,
                        style: const TextStyle(
                          color: color2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    fontSize: 20.0,
                    textAlign: TextAlign.center,
                  ),
                  if (currentOwner != '') ...[
                    const SizedBox(height: 10),
                    buildButton(
                      text: 'Eliminar Owner',
                      onPressed: () {
                        putOwner(productCode,
                            serialNumberController.text.trim(), '');
                        registerActivity(
                          productCode,
                          serialNumberController.text.trim(),
                          'Se elimino el owner del equipo',
                        );
                        setState(() {
                          currentOwner = '';
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Administradores secundarios
                  const SizedBox(height: 15),
                  Card(
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
                            currentSecondaryAdmins.isNotEmpty
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
                                color: currentSecondaryAdmins.isNotEmpty
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
                          if (currentSecondaryAdmins.isEmpty) ...[
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
                                i < currentSecondaryAdmins.length;
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
                                      currentSecondaryAdmins[i][0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: color4,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    currentSecondaryAdmins[i],
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
                                              '¿Estás seguro de que deseas eliminar a "${currentSecondaryAdmins[i]}" de los administradores secundarios?',
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
                                                    productCode,
                                                    serialNumberController.text
                                                        .trim(),
                                                    'Se elimino el admin ${currentSecondaryAdmins[i]} del equipo',
                                                  );
                                                  setState(() {
                                                    currentSecondaryAdmins
                                                        .removeAt(i);
                                                  });
                                                  putSecondaryAdmins(
                                                    productCode,
                                                    serialNumberController.text
                                                        .trim(),
                                                    currentSecondaryAdmins,
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

                  // Botón para agregar administrador secundario
                  const SizedBox(height: 10),
                  buildButton(
                    text: 'Agregar Administrador Secundario',
                    onPressed: () {
                      _showAddSecondaryAdminDialog();
                    },
                  ),

                  // Vencimiento administradores secundarios extra
                  const SizedBox(height: 10),
                  buildText(
                    text: '',
                    textSpans: [
                      const TextSpan(
                        text:
                            'Vencimiento beneficio\nAdministradores secundarios extra:\n',
                        style: TextStyle(
                            color: color4, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: currentSecAdmDate,
                        style: const TextStyle(
                            color: color2, fontWeight: FontWeight.bold),
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
                                        dateController.selection =
                                            TextSelection.fromPosition(
                                                const TextPosition(offset: 10));
                                      } else if (value.length == 4 ||
                                          value.length == 7) {
                                        dateController.text = '$value/';
                                        dateController.selection =
                                            TextSelection.fromPosition(
                                                TextPosition(
                                                    offset: value.length + 1));
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
                                      productCode,
                                      serialNumberController.text.trim(),
                                      'Se modifico el vencimiento del beneficio "administradores secundarios extras"');
                                  putDate(
                                      productCode,
                                      serialNumberController.text.trim(),
                                      dateController.text.trim(),
                                      false);
                                  setState(() {
                                    currentSecAdmDate =
                                        dateController.text.trim();
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

                  // Vencimiento alquiler temporario
                  const SizedBox(height: 10),
                  buildText(
                    text: '',
                    textSpans: [
                      const TextSpan(
                        text: 'Vencimiento beneficio\nAlquiler temporario:\n',
                        style: TextStyle(
                            color: color4, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: currentAtDate,
                        style: const TextStyle(
                            color: color2, fontWeight: FontWeight.bold),
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
                                        dateController.selection =
                                            TextSelection.fromPosition(
                                                const TextPosition(offset: 10));
                                      } else if (value.length == 4 ||
                                          value.length == 7) {
                                        dateController.text = '$value/';
                                        dateController.selection =
                                            TextSelection.fromPosition(
                                                TextPosition(
                                                    offset: value.length + 1));
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
                                      productCode,
                                      serialNumberController.text.trim(),
                                      'Se modifico el vencimiento del beneficio "alquiler temporario"');
                                  putDate(
                                      productCode,
                                      serialNumberController.text.trim(),
                                      dateController.text.trim(),
                                      true);
                                  setState(() {
                                    currentAtDate = dateController.text.trim();
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

                  // Sistema de riego (solo para productos compatibles)
                  const SizedBox(height: 20),
                  if (canBeRiego) ...[
                    // Tarjeta estética para el estado del riego
                    Card(
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
                              currentRiegoActive
                                  ? color1.withValues(alpha: 0.1)
                                  : color2.withValues(alpha: 0.1),
                              color4,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              currentRiegoActive
                                  ? Icons.water_drop
                                  : Icons.water_drop_outlined,
                              size: 48,
                              color: currentRiegoActive ? color1 : color2,
                            ),
                            const SizedBox(height: 10),
                            buildText(
                              text: '',
                              textSpans: [
                                const TextSpan(
                                  text: 'Estado del sistema de riego:\n',
                                  style: TextStyle(
                                    color: color4,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                TextSpan(
                                  text: currentRiegoActive
                                      ? 'Activado'
                                      : 'Desactivado',
                                  style: const TextStyle(
                                    color: color2,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                              fontSize: 20.0,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            if (currentRiegoActive) ...[
                              buildButton(
                                text: 'Desactivar sistema de riego',
                                onPressed: () {
                                  putRiego(
                                      productCode,
                                      serialNumberController.text.trim(),
                                      false);
                                  registerActivity(
                                    productCode,
                                    serialNumberController.text.trim(),
                                    'Se desactivo el sistema de riego',
                                  );
                                  setState(() {
                                    currentRiegoActive = false;
                                  });
                                },
                              ),
                            ] else ...[
                              buildButton(
                                text: 'Activar sistema de riego',
                                onPressed: () {
                                  putRiego(productCode,
                                      serialNumberController.text.trim(), true);
                                  registerActivity(
                                    productCode,
                                    serialNumberController.text.trim(),
                                    'Se activo el sistema de riego',
                                  );
                                  setState(() {
                                    currentRiegoActive = true;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Tarjeta para RiegoMaster
                    const SizedBox(height: 15),
                    Card(
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
                              currentRiegoMaster.isNotEmpty
                                  ? color1.withValues(alpha: 0.1)
                                  : color3.withValues(alpha: 0.1),
                              color4,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              currentRiegoMaster.isNotEmpty
                                  ? Icons.admin_panel_settings
                                  : Icons.admin_panel_settings_outlined,
                              size: 48,
                              color: currentRiegoMaster.isNotEmpty
                                  ? color1
                                  : color3,
                            ),
                            const SizedBox(height: 10),
                            buildText(
                              text: '',
                              textSpans: [
                                const TextSpan(
                                  text: 'RiegoMaster:\n',
                                  style: TextStyle(
                                    color: color4,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                TextSpan(
                                  text: currentRiegoMaster.isNotEmpty
                                      ? currentRiegoMaster
                                      : 'No asignado',
                                  style: const TextStyle(
                                    color: color2,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                              fontSize: 20.0,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            if (currentRiegoMaster.isNotEmpty) ...[
                              buildButton(
                                text: 'Eliminar RiegoMaster',
                                onPressed: () {
                                  removeRiegoMaster(productCode,
                                      serialNumberController.text.trim());
                                  registerActivity(
                                    productCode,
                                    serialNumberController.text.trim(),
                                    'Se elimino el RiegoMaster: $currentRiegoMaster',
                                  );
                                  setState(() {
                                    currentRiegoMaster = '';
                                  });
                                },
                              ),
                            ] else ...[
                              buildButton(
                                text: 'Asignar RiegoMaster',
                                onPressed: () {
                                  _showRiegoMasterDialog();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (productCode == '023430_IOT') ...[
                    const SizedBox(height: 20),
                    buildText(
                      text: '',
                      textSpans: [
                        const TextSpan(
                          text: 'Histórico de temperaturas premium:\n',
                          style: TextStyle(
                              color: color4, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              historicTempPremium ? 'Activado' : 'Desactivado',
                          style: TextStyle(
                              color: historicTempPremium
                                  ? Colors.green
                                  : Colors.red,
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
                        putHistoricTempPremium(
                            productCode,
                            serialNumberController.text.trim(),
                            !historicTempPremium);
                        registerActivity(
                          productCode,
                          serialNumberController.text.trim(),
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
                              for (int i = discTimes.length - 1;
                                  i >= 0;
                                  i--) ...[
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
                ] else ...[
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(color3),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Esperando a que se\n seleccione un equipo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: color0,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ]),
        ));
  }
}
