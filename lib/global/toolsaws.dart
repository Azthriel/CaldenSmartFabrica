import 'dart:convert';

import 'package:caldensmartfabrica/aws/mqtt/mqtt.dart';
import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../aws/dynamo/dynamo.dart';
import '../aws/dynamo/dynamo_certificates.dart';

class ToolsAWS extends StatefulWidget {
  const ToolsAWS({super.key});

  @override
  ToolsAWSState createState() => ToolsAWSState();
}

class ToolsAWSState extends State<ToolsAWS> {
  final TextEditingController serialNumberController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  String productCode = '';
  String commandText = '';
  int key = 0;
  List<String> content = [];
  bool tools = false;
  bool config = false;
  List<String> productos = [];

  @override
  void initState() {
    super.initState();
    List<dynamic> lista = fbData['Productos'] ?? [];
    productos = lista.map((item) => item.toString()).toList();
  }

  String hintAWS(String cmd) {
    switch (cmd) {
      case '0':
        return '1 borrar NVS, 0 Conservar';
      case '2':
        return 'HardVer#SoftVer';
      case '4':
        return 'Nuevo SN';
      case '5':
        return '0 desactivar CPD';
      case '6':
        if (key == 0) {
          return 'Amazon CA';
        } else if (key == 1) {
          return 'Device Cert.';
        } else {
          return 'Private Key';
        }
      case '16':
        return '0 desactivar | 1 activar';
      case '17':
        return 'No requiere parametros';
      case '':
        return 'Aún no se agrega comando';
      default:
        return 'Este comando no existe...';
    }
  }

  TextInputType contentType(String cmd) {
    switch (cmd) {
      case '0':
        return TextInputType.number;
      case '2':
        return TextInputType.text;
      case '4':
        return TextInputType.number;
      case '5':
        return TextInputType.text;
      case '6':
        return TextInputType.multiline;
      case '16':
        return TextInputType.number;
      case '':
        return TextInputType.none;
      default:
        return TextInputType.none;
    }
  }

  @override
  void dispose() {
    serialNumberController.dispose();
    contentController.dispose();
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
                'Comandos a distancia',
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
        body: Consumer<GlobalDataNotifier>(
          builder: (context, notifier, child) {
            String textToShow = notifier.getData();
            printLog(textToShow);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 335,
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
                        items: productos
                            .map<DropdownMenuItem<String>>((String value) {
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
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 335,
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
                                String topic =
                                    'tools/$productCode/${serialNumberController.text.trim()}';
                                unSubToTopicMQTT(topic);
                                setState(() {
                                  serialNumberController.clear();
                                  notifier.updateData(
                                      'Esperando respuesta del esp...');
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
                            setState(() {
                              queryItems(service, productCode,
                                  serialNumberController.text.trim());
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        String topic =
                            'tools/$productCode/${serialNumberController.text.trim()}';
                        subToTopicMQTT(topic);
                        listenToTopics();
                        final data = {"alive": true};
                        String msg = jsonEncode(data);
                        registerActivity(
                            productCode,
                            serialNumberController.text.trim(),
                            'Se envio via mqtt: $msg');
                        sendMessagemqtt(topic, msg);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: color4,
                        backgroundColor: color1,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text('Verificar conexión equipo'),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (!tools && !config) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                config = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: color4,
                              backgroundColor: color1,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text('Parametros'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                tools = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: color4,
                              backgroundColor: color1,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text('Comandos'),
                          ),
                        ],
                      ),
                    ],
                    if (config) ...[
                      if (productCode != '' &&
                          serialNumberController.text != '') ...[
                        const SizedBox(height: 20),

                        // Card para el Owner
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Card(
                            color: color0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Owner Actual del Equipo:',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      color: color4,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    owner == ''
                                        ? 'No hay owner registrado'
                                        : owner,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: color3,
                                    ),
                                  ),
                                  if (owner != '') ...[
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        putOwner(service, productCode,
                                            serialNumberController.text, '');
                                        registerActivity(
                                            productCode,
                                            serialNumberController.text.trim(),
                                            'Se eliminó el owner del equipo');
                                        setState(() {
                                          owner = '';
                                        });
                                      },
                                      icon: const Icon(Icons.delete,
                                          color: color4),
                                      label: const Text(
                                        'Eliminar Owner',
                                        style: TextStyle(color: color4),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color2,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Card para Administradores Secundarios
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Card(
                            color: color0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Administradores del Equipo:',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      color: color4,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  secondaryAdmins.isEmpty
                                      ? const Text(
                                          'No hay administradores secundarios para este equipo',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: color3,
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: secondaryAdmins.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: const Icon(
                                                  Icons.admin_panel_settings,
                                                  color: color3),
                                              title: Text(
                                                secondaryAdmins[index],
                                                style: const TextStyle(
                                                  fontSize: 16.0,
                                                  color: color3,
                                                ),
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: color3),
                                                onPressed: () {
                                                  registerActivity(
                                                      productCode,
                                                      serialNumberController
                                                          .text
                                                          .trim(),
                                                      'Se eliminó el admin ${secondaryAdmins[index]} del equipo');
                                                  setState(() {
                                                    secondaryAdmins
                                                        .removeAt(index);
                                                  });
                                                  putSecondaryAdmins(
                                                      service,
                                                      productCode,
                                                      serialNumberController
                                                          .text
                                                          .trim(),
                                                      secondaryAdmins);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Card para Vencimiento Beneficios
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Card(
                            color: color0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Vencimiento Administradores Secundarios Extra
                                  const Text(
                                    'Vencimiento Beneficio\nAdministradores Secundarios Extra:',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      color: color4,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    secAdmDate,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: color3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          final TextEditingController
                                              dateController =
                                              TextEditingController();
                                          return AlertDialog(
                                            backgroundColor: color1,
                                            title: const Text(
                                              'Especificar nueva fecha de vencimiento:',
                                              style: TextStyle(
                                                  color: color4,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 300,
                                                  child: TextField(
                                                    style: const TextStyle(
                                                        color: color4),
                                                    controller: dateController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'aaaa/mm/dd',
                                                      hintStyle: TextStyle(
                                                          color: color3),
                                                      filled: true,
                                                      fillColor: color2,
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    8)),
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      if (value.length > 10) {
                                                        dateController.text =
                                                            value.substring(
                                                                0, 10);
                                                        dateController
                                                                .selection =
                                                            TextSelection
                                                                .fromPosition(
                                                                    const TextPosition(
                                                                        offset:
                                                                            10));
                                                      } else if (value.length ==
                                                              4 ||
                                                          value.length == 7) {
                                                        dateController.text =
                                                            '$value/';
                                                        dateController
                                                                .selection =
                                                            TextSelection.fromPosition(
                                                                TextPosition(
                                                                    offset:
                                                                        value.length +
                                                                            1));
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  navigatorKey.currentState!
                                                      .pop();
                                                },
                                                child: const Text(
                                                  'Cancelar',
                                                  style:
                                                      TextStyle(color: color3),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  registerActivity(
                                                      productCode,
                                                      serialNumberController
                                                          .text,
                                                      'Se modificó el vencimiento del beneficio "administradores secundarios extras"');
                                                  putDate(
                                                      service,
                                                      productCode,
                                                      serialNumberController
                                                          .text
                                                          .trim(),
                                                      dateController.text
                                                          .trim(),
                                                      false);
                                                  setState(() {
                                                    secAdmDate = dateController
                                                        .text
                                                        .trim();
                                                  });
                                                  navigatorKey.currentState!
                                                      .pop();
                                                },
                                                child: const Text(
                                                  'Enviar fecha',
                                                  style:
                                                      TextStyle(color: color4),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.edit, color: color4),
                                    label: const Text(
                                      'Modificar Fecha',
                                      style: TextStyle(color: color4),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color2,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Vencimiento Alquiler Temporario
                                  const Text(
                                    'Vencimiento Beneficio\nAlquiler Temporario:',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      color: color4,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    atDate,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: color3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          final TextEditingController
                                              dateController =
                                              TextEditingController();
                                          return AlertDialog(
                                            backgroundColor: color1,
                                            title: const Text(
                                              'Especificar nueva fecha de vencimiento:',
                                              style: TextStyle(
                                                  color: color4,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 300,
                                                  child: TextField(
                                                    style: const TextStyle(
                                                        color: color4),
                                                    controller: dateController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'aaaa/mm/dd',
                                                      hintStyle: TextStyle(
                                                          color: color3),
                                                      filled: true,
                                                      fillColor: color2,
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    8)),
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      if (value.length > 10) {
                                                        dateController.text =
                                                            value.substring(
                                                                0, 10);
                                                        dateController
                                                                .selection =
                                                            TextSelection
                                                                .fromPosition(
                                                                    const TextPosition(
                                                                        offset:
                                                                            10));
                                                      } else if (value.length ==
                                                              4 ||
                                                          value.length == 7) {
                                                        dateController.text =
                                                            '$value/';
                                                        dateController
                                                                .selection =
                                                            TextSelection.fromPosition(
                                                                TextPosition(
                                                                    offset:
                                                                        value.length +
                                                                            1));
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  navigatorKey.currentState!
                                                      .pop();
                                                },
                                                child: const Text(
                                                  'Cancelar',
                                                  style:
                                                      TextStyle(color: color3),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  registerActivity(
                                                      productCode,
                                                      serialNumberController
                                                          .text,
                                                      'Se modificó el vencimiento del beneficio "alquiler temporario"');
                                                  putDate(
                                                      service,
                                                      productCode,
                                                      serialNumberController
                                                          .text
                                                          .trim(),
                                                      dateController.text
                                                          .trim(),
                                                      true);
                                                  setState(() {
                                                    atDate = dateController.text
                                                        .trim();
                                                  });
                                                  navigatorKey.currentState!
                                                      .pop();
                                                },
                                                child: const Text(
                                                  'Enviar fecha',
                                                  style:
                                                      TextStyle(color: color4),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.edit, color: color4),
                                    label: const Text(
                                      'Modificar Fecha',
                                      style: TextStyle(color: color4),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color2,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color3),
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
                      ]
                    ],
                    if (tools) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: color0,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color4, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: color4.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Comando:',
                                  labelStyle: TextStyle(color: color4),
                                  hintStyle: TextStyle(color: color4),
                                  border: InputBorder.none,
                                ),
                                dropdownColor: color0,
                                items: <String>[
                                  '0',
                                  '2',
                                  '4',
                                  '5',
                                  '6',
                                  if (productCode == '027000_IOT' ||
                                      productCode == '022000_IOT' ||
                                      productCode == '041220_IOT' ||
                                      productCode == '050217_IOT') ...{
                                    '16',
                                    '17'
                                  },
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        color: color4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    commandText = value!;
                                    contentController.clear();
                                  });
                                  printLog(contentType(commandText));
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: color0,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color4, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: color4.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                style: const TextStyle(color: color4),
                                controller: contentController,
                                maxLines: null,
                                keyboardType: contentType(commandText),
                                decoration: InputDecoration(
                                  labelText: 'Contenido:',
                                  hintText: hintAWS(commandText),
                                  labelStyle: const TextStyle(color: color4),
                                  hintStyle: const TextStyle(color: color4),
                                  border: InputBorder.none,
                                  suffixIcon: commandText == '6'
                                      ? IconButton(
                                          onPressed: () {
                                            showDialog<void>(
                                              context: context,
                                              barrierDismissible: true,
                                              builder: (BuildContext context) {
                                                return SimpleDialog(
                                                  backgroundColor: color0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  title: const Center(
                                                    child: Text(
                                                      '¿Qué vas a enviar?',
                                                      style: TextStyle(
                                                        color: color4,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  children: <Widget>[
                                                    const Divider(
                                                        color: color4),
                                                    SimpleDialogOption(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        contentController
                                                            .clear();
                                                        key = 0;
                                                        printLog(
                                                            'Amazon CA seleccionada');
                                                        setState(() {});
                                                      },
                                                      child: const Text(
                                                        'Amazon CA',
                                                        style: TextStyle(
                                                          color: color4,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                    SimpleDialogOption(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        contentController
                                                            .clear();
                                                        key = 1;
                                                        printLog(
                                                            'Device Cert. seleccionada');
                                                        setState(() {});
                                                      },
                                                      child: const Text(
                                                        'Device Cert.',
                                                        style: TextStyle(
                                                          color: color4,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                    SimpleDialogOption(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        contentController
                                                            .clear();
                                                        key = 2;
                                                        printLog(
                                                            'Private key seleccionada');
                                                        setState(() {});
                                                      },
                                                      child: const Text(
                                                        'Private key',
                                                        style: TextStyle(
                                                          color: color4,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.paste,
                                            color: color4,
                                          ),
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  if (commandText == '6') {
                                    content =
                                        contentController.text.split('\n');
                                    contentController.text = 'Cargado';
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildButton(
                          text: 'Enviar comando',
                          onPressed: () {
                            if (commandText != '' &&
                                contentController.text.isNotEmpty) {
                              String topic =
                                  'tools/$productCode/${serialNumberController.text.trim()}';
                              subToTopicMQTT(topic);
                              listenToTopics();
                              if (commandText == '6') {
                                for (var line in content) {
                                  String msg = jsonEncode({
                                    'cmd': commandText,
                                    'content': '$key#$line'
                                  });
                                  printLog(msg);
                                  sendMessagemqtt(topic, msg);
                                }
                                String fun = key == 0
                                    ? 'Amazon CA'
                                    : key == 1
                                        ? 'Device cert.'
                                        : 'Private Key';
                                registerActivity(
                                    productCode,
                                    serialNumberController.text.trim(),
                                    'Se envió vía MQTT un $fun');
                                contentController.clear();
                              } else {
                                String msg = jsonEncode({
                                  'cmd': commandText,
                                  'content': contentController.text.trim()
                                });
                                registerActivity(
                                    productCode,
                                    serialNumberController.text.trim(),
                                    'Se envió vía MQTT: $msg');
                                sendMessagemqtt(topic, msg);
                                contentController.clear();
                              }
                            }else if(commandText == '17'){
                              printLog('Enviando comando 17');
                              String topic = 'tools/$productCode/${serialNumberController.text.trim()}';
                              subToTopicMQTT(topic);
                              listenToTopics();
                              String msg = jsonEncode({
                                'cmd': commandText,
                                'content': 'ANASHARDO'
                              });
                              registerActivity(
                                  productCode,
                                  serialNumberController.text.trim(),
                                  'Se consultó temperatura vía MQTT');
                              sendMessagemqtt(topic, msg);
                              contentController.clear();
                            } else {
                              showToast('Faltan datos para enviar el comando');
                            }
                          }),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: color0,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: color4.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Respuesta:',
                              style: TextStyle(
                                color: color4,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: color0,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: textToShow.isNotEmpty
                                  ? Text(
                                      textToShow,
                                      style: const TextStyle(
                                        color: Color(0xFFdfb6b2),
                                        fontSize: 18,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  : const Text(
                                      'No hubo respuesta.',
                                      style: TextStyle(
                                        color: color4,
                                        fontSize: 18,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ]),
            );
          },
        ));
  }
}
