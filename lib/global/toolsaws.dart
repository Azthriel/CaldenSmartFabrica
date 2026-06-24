import 'dart:convert';

import 'package:caldensmartfabrica/aws/mqtt/mqtt.dart';
import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../aws/dynamo/dynamo.dart';

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
  List<String> productos = [];

  @override
  void initState() {
    super.initState();
    List<dynamic> lista = fbData['Productos'] ?? [];
    productos = lista.map((item) => item.toString()).toList();
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
                              queryItems(productCode,
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
                    const SizedBox(height: 20),
                    Container(
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
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Comando:',
                          labelStyle: TextStyle(color: color4),
                          hintStyle: TextStyle(color: color4),
                          border: InputBorder.none,
                        ),
                        dropdownColor: color0,
                        items: <String>[
                          '0 - Reiniciar equipo',
                          '2 - OTA WiFi Trigger',
                          '4 - Cambiar número de serie',
                          '5 - Activar/desactivar CPD',
                          '6 - Cargar certificados',
                          if (productCode == '027000_IOT' ||
                              productCode == '022000_IOT' ||
                              productCode == '041220_IOT' ||
                              productCode == '050217_IOT') ...{
                            '16 - Modo manual',
                            '17 - Consultar temperatura y Offset',
                            '19 - Activar/Desactivar Offset de temperatura',
                          },
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
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
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
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
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: 'Contenido:',
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
                                                BorderRadius.circular(12),
                                          ),
                                          title: const Center(
                                            child: Text(
                                              '¿Qué vas a enviar?',
                                              style: TextStyle(
                                                color: color4,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                          children: <Widget>[
                                            const Divider(color: color4),
                                            SimpleDialogOption(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                contentController.clear();
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
                                                Navigator.of(context).pop();
                                                contentController.clear();
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
                                                Navigator.of(context).pop();
                                                contentController.clear();
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
                            content = contentController.text.split('\n');
                            contentController.text = 'Cargado';
                          }
                        },
                      ),
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
                          } else if (commandText == '17') {
                            printLog('Enviando comando 17');
                            String topic =
                                'tools/$productCode/${serialNumberController.text.trim()}';
                            subToTopicMQTT(topic);
                            listenToTopics();
                            String msg = jsonEncode(
                                {'cmd': commandText, 'content': 'ANASHARDO'});
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
                    const SizedBox(
                      height: 50,
                    ),
                  ]),
            );
          },
        ));
  }
}
