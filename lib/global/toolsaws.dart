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
        appBar: AppBar(
          backgroundColor: color1,
          foregroundColor: color4,
          title: const Align(
            alignment: Alignment.center,
            child: Text(
              'Customer service\nComandos a distancia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          elevation: 0,
        ),
        body: Consumer<GlobalDataNotifier>(
          builder: (context, notifier, child) {
            String textToShow = notifier.getData();
            printLog(textToShow);

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 335,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: color0,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color3.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Ingrese el código de producto',
                          labelStyle: TextStyle(
                            color: Color(0xfffbe4d8),
                            fontWeight: FontWeight.w500,
                          ),
                          hintText: 'Seleccione un código',
                          hintStyle: TextStyle(color: Color(0xfffbe4d8)),
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
                                color: Color(0xfffbe4d8),
                                fontWeight: FontWeight.bold,
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
                          boxShadow: [
                            BoxShadow(
                              color: color3.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          style: const TextStyle(color: Color(0xfffbe4d8)),
                          controller: serialNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Ingrese el número de serie',
                            labelStyle:
                                const TextStyle(color: Color(0xfffbe4d8)),
                            hintStyle:
                                const TextStyle(color: Color(0xfffbe4d8)),
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
                                color: Color(0xfffbe4d8),
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
                        child: const Text('Verificar conexión equipo')),
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
                              child: const Text('Parametros')),
                          ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  tools = true;
                                });
                              },
                              child: const Text('Comandos')),
                        ],
                      ),
                    ],
                    if (config) ...[
                      if (productCode != '' &&
                          serialNumberController.text != '') ...[
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
                              putOwner(service, productCode, serialNumberController.text, '');
                              registerActivity(
                                  productCode,
                                  serialNumberController.text.trim(),
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
                                            productCode,
                                            serialNumberController.text.trim(),
                                            'Se elimino el admin ${secondaryAdmins[i]} del equipo');
                                        setState(() {
                                          secondaryAdmins
                                              .remove(secondaryAdmins[i]);
                                        });
                                        putSecondaryAdmins(
                                            service,
                                            productCode,
                                            serialNumberController.text.trim(),
                                            secondaryAdmins);
                                      },
                                      icon: const Icon(Icons.delete,
                                          color: Colors.grey),
                                    ),
                                    const SizedBox(
                                      width: 5,
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
                            )
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
                                          style: const TextStyle(
                                              color: Colors.black),
                                          controller: dateController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: 'aaaa/mm/dd',
                                            hintStyle:
                                                TextStyle(color: Colors.black),
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
                                            productCode,
                                            serialNumberController.text,
                                            'Se modifico el vencimiento del beneficio "administradores secundarios extras"');
                                        putDate(
                                            service,
                                            productCode,
                                            serialNumberController.text.trim(),
                                            dateController.text.trim(),
                                            false);
                                        setState(() {
                                          secAdmDate =
                                              dateController.text.trim();
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
                                          style: const TextStyle(
                                              color: Colors.black),
                                          controller: dateController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: 'aaaa/mm/dd',
                                            hintStyle:
                                                TextStyle(color: Colors.black),
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
                                            productCode,
                                            serialNumberController.text,
                                            'Se modifico el vencimiento del beneficio "alquiler temporario"');
                                        putDate(
                                            service,
                                            productCode,
                                            serialNumberController.text.trim(),
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
                      ] else ...[
                        const CircularProgressIndicator(),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'Esperando a que se\n seleccione un equipo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Color(0xfffbe4d8),
                          ),
                        )
                      ]
                    ],
                    if (tools) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 115,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Comando:',
                                labelStyle: TextStyle(color: Color(0xfffbe4d8)),
                                hintStyle: TextStyle(color: Color(0xfffbe4d8)),
                                // fillColor: Color(0xfffbe4d8),
                              ),
                              dropdownColor: const Color(0xff190019),
                              items: <String>[
                                '0',
                                '2',
                                '4',
                                '5',
                                '6'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style: const TextStyle(
                                        color: Color(0xfffbe4d8),
                                      )),
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
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 200,
                            child: TextField(
                              style: const TextStyle(color: Color(0xfffbe4d8)),
                              controller: contentController,
                              maxLines: null,
                              keyboardType: contentType(commandText),
                              decoration: InputDecoration(
                                labelText: 'Contenido:',
                                hintText: hintAWS(commandText),
                                labelStyle:
                                    const TextStyle(color: Color(0xfffbe4d8)),
                                hintStyle:
                                    const TextStyle(color: Color(0xfffbe4d8)),
                                suffixIcon: commandText == '6'
                                    ? IconButton(
                                        onPressed: () {
                                          showDialog<void>(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (BuildContext context) {
                                              return SimpleDialog(
                                                title: const Text(
                                                    '¿Que vas a envíar?'),
                                                children: <Widget>[
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      contentController.clear();
                                                      key = 0;
                                                      printLog(
                                                          'Amazon CA seleccionada');
                                                      setState(() {});
                                                    },
                                                    child:
                                                        const Text('Amazon CA'),
                                                  ),
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      contentController.clear();
                                                      key = 1;
                                                      printLog(
                                                          'Device Cert. seleccionada');
                                                      setState(() {});
                                                    },
                                                    child: const Text(
                                                        'Device Cert.'),
                                                  ),
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      contentController.clear();
                                                      key = 2;
                                                      printLog(
                                                          'Private key seleccionada');
                                                      setState(() {});
                                                    },
                                                    child: const Text(
                                                        'Private key'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.paste,
                                          color: Color(0xfffbe4d8),
                                        ),
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                if (commandText == '6') {
                                  content = contentController.text.split('\n');
                                  contentController.text = 'Cargado';
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                          onPressed: () {
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
                                  'Se envio via mqtt un $fun');
                              contentController.clear();
                            } else {
                              String msg = jsonEncode({
                                'cmd': commandText,
                                'content': contentController.text.trim()
                              });
                              registerActivity(
                                  productCode,
                                  serialNumberController.text.trim(),
                                  'Se envio via mqtt: $msg');
                              sendMessagemqtt(topic, msg);
                              contentController.clear();
                            }
                          },
                          child: const Text('Enviar comando')),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: const Color(0xff2b124c),
                          borderRadius: BorderRadius.circular(20),
                          border: const Border(
                            bottom:
                                BorderSide(color: Color(0xff854f6c), width: 5),
                            right:
                                BorderSide(color: Color(0xff854f6c), width: 5),
                            left:
                                BorderSide(color: Color(0xff854f6c), width: 5),
                            top: BorderSide(color: Color(0xff854f6c), width: 5),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Respuesta:',
                              style: TextStyle(
                                  color: Color(0xFFdfb6b2),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Text(
                              textToShow,
                              style: const TextStyle(
                                  color: Color(0xFFdfb6b2), fontSize: 30),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    ],
                  ],
                ),
              ),
            );
          },
        ));
  }
}
