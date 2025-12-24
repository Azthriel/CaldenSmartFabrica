import 'dart:async';
import 'dart:convert';
import 'package:caldensmartfabrica/aws/dynamo/dynamo.dart';
import 'package:caldensmartfabrica/aws/mqtt/mqtt.dart';
import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:provider/provider.dart';

class WifiTestScreen extends StatefulWidget {
  const WifiTestScreen({super.key});

  @override
  WifiTestScreenState createState() => WifiTestScreenState();
}

class WifiTestScreenState extends State<WifiTestScreen> {
  final _serialCtrl = TextEditingController();
  List<String> productos = [];
  String pc = '';
  String toHear = '';
  bool _alert = false;
  bool _estado = false;
  String _temperature = '';
  bool _alertMax = false;
  bool _alertMin = false;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? sub;
  bool testing = false;
  bool created = false;
  final outController = TextEditingController();
  final inController = TextEditingController();
  int outLenght = 0;
  int inLenght = 0;
  bool _oldDevice = false;
  Map<String, Map<String, dynamic>> ioData = {};

  @override
  void initState() {
    super.initState();
    listener();
    List<dynamic> lista = fbData['Productos'] ?? [];
    productos = lista.map((item) => item.toString()).toList();
  }

  @override
  void dispose() {
    _serialCtrl.dispose();
    unSubToTopicMQTT(toHear);
    sub?.cancel();
    super.dispose();
  }

  void listener() {
    sub = mqttAWSFlutterClient!.updates!.listen((c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String topic = c[0].topic;

      if (topic == toHear) {
        final List<int> message = recMess.payload.message;
        final String messageString = utf8.decode(message);
        printLog('Mensaje recibido: $messageString');
        try {
          final Map<String, dynamic> messageMap =
              json.decode(messageString) ?? {};
          setState(() {
            if (messageMap.keys.contains('cstate')) {
              isConnectedToAWS = messageMap['cstate'];
              // Actualizar el Provider
              try {
                GlobalDataNotifier notifier = Provider.of<GlobalDataNotifier>(
                    navigatorKey.currentContext!,
                    listen: false);
                notifier.updateAWSConnectionState(isConnectedToAWS);
              } catch (e) {
                printLog('Error actualizando Provider desde wifi_tester: $e');
              }
            }
            messageMap.keys.contains('alert')
                ? _alert = messageMap['alert'] == 1
                : null;
            messageMap.keys.contains('w_status')
                ? _estado = messageMap['w_status']
                : null;
            messageMap.keys.contains('actualTemp')
                ? _temperature = messageMap['actualTemp'].toString()
                : null;
            messageMap.keys.contains('alert_maxflag')
                ? _alertMax = messageMap['alert_maxflag']
                : null;
            messageMap.keys.contains('alert_minflag')
                ? _alertMin = messageMap['alert_minflag']
                : null;

            if (messageMap.keys.contains('index')) {
              ioData['io${messageMap['index']}'] = {
                'w_status': messageMap['w_status'],
                'r_state': messageMap['r_state'],
                'pinType': messageMap['pinType'],
                'index': messageMap['index'],
              };
            }
          });
        } catch (e) {
          printLog('Error al procesar el mensaje: $e');
        }
      }
    });
  }

  void _loadDevice() async {
    if (pc.isNotEmpty && _serialCtrl.text.trim().isNotEmpty) {
      await queryItems(pc, _serialCtrl.text.trim());
      final String topic = 'devices_tx/$pc/${_serialCtrl.text.trim()}';
      subToTopicMQTT(topic);

      setState(() {
        toHear = topic;
        testing = true;
      });
    } else {
      showToast(
          "Debes seleccionar un código de producto y número de serie primero");
    }
  }

  Widget detectors() {
    return Card(
      color: color0,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
        child: Column(
          children: [
            Text(
              _alert ? 'PELIGRO' : 'AIRE PURO',
              style: const TextStyle(
                color: color4,
                fontSize: 45,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isConnectedToAWS ? '● CONECTADO' : '● DESCONECTADO',
              style: TextStyle(
                color: isConnectedToAWS ? Colors.green : Colors.red,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            _alert
                ? const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 80,
                  )
                : const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget termometro() {
    return Card(
      color: color0,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
        child: Column(
          children: [
            Text(
              _temperature.isNotEmpty ? 'Temperatura: $_temperature °C' : 'N/A',
              style: const TextStyle(
                color: color4,
                fontSize: 45,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isConnectedToAWS ? '● CONECTADO' : '● DESCONECTADO',
              style: TextStyle(
                color: isConnectedToAWS ? Colors.green : Colors.red,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            if (_alertMax || _alertMin) ...[
              const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 80,
              )
            ] else ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget otherDevices() {
    return Card(
      color: color0,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
        child: Column(
          children: [
            Text(
              _estado ? 'ENCENDIDO' : 'APAGADO',
              style: const TextStyle(
                color: color4,
                fontSize: 45,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isConnectedToAWS ? '● CONECTADO' : '● DESCONECTADO',
              style: TextStyle(
                color: isConnectedToAWS ? Colors.green : Colors.red,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Transform.scale(
              scale: 1.5,
              child: Switch(
                value: _estado,
                onChanged: (newValue) {
                  final String tc = 'devices_rx/$pc/${_serialCtrl.text.trim()}';
                  final String tc2 =
                      'devices_tx/$pc/${_serialCtrl.text.trim()}';
                  final String message = jsonEncode({"w_status": newValue});
                  sendMessagemqtt(tc, message);
                  sendMessagemqtt(tc2, message);

                  setState(() {
                    _estado = newValue;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget multipleOutputDevices() {
    return Card(
      color: color0,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
        child: Column(
          children: [
            if (!created) ...[
              const SizedBox(
                height: 20,
              ),
              if (pc == '027313_IOT') ...[
                const Text(
                  '¿Es hardware viejo (sin salida)?',
                  style: TextStyle(
                    color: color4,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Checkbox(
                  value: _oldDevice,
                  onChanged: (bool? value) {
                    setState(() {
                      _oldDevice = value ?? false;
                    });
                  },
                  activeColor: color1,
                ),
                const SizedBox(
                  height: 5,
                ),
                const Divider(
                  color: color4,
                  thickness: 1.5,
                ),
                const SizedBox(
                  height: 5,
                ),
              ],
              if (!_oldDevice) ...[
                const Text(
                  '¿Cuántas salidas tiene el equipo?',
                  style: TextStyle(
                    color: color4,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.center,
                  widthFactor: 0.8,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: TextField(
                      controller: outController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: color4,
                      ),
                    ),
                  ),
                ),
                const Text(
                  '¿Cuántas entradas tiene el equipo?',
                  style: TextStyle(
                    color: color4,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.center,
                  widthFactor: 0.8,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: TextField(
                      controller: inController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: color4,
                      ),
                    ),
                  ),
                ),
              ],
              buildButton(
                text: 'Crear',
                onPressed: () {
                  if (_oldDevice) {
                    setState(() {
                      outLenght = 1;
                      inLenght = 0;
                      outController.clear();
                      inController.clear();
                      created = true;
                    });
                  } else {
                    if (outController.text.isNotEmpty &&
                        inController.text.isNotEmpty) {
                      int? outTest = int.tryParse(outController.text.trim());
                      int? inTest = int.tryParse(inController.text.trim());
                      if (outTest == null || inTest == null) {
                        showToast("Por favor, ingrese números válidos.");
                        return;
                      }
                      setState(() {
                        outLenght = outTest;
                        inLenght = inTest;
                        outController.clear();
                        inController.clear();
                        created = true;
                      });
                    } else {
                      showToast("Por favor, complete ambos campos.");
                    }
                  }
                },
              ),
              const SizedBox(
                height: 20,
              ),
            ] else ...[
              const Text(
                'EQUIPO',
                style: TextStyle(
                  color: color4,
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isConnectedToAWS ? '● CONECTADO' : '● DESCONECTADO',
                style: TextStyle(
                  color: isConnectedToAWS ? Colors.green : Colors.red,
                  fontSize: 15,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              const Divider(
                color: color4,
                thickness: 1.5,
              ),
              const SizedBox(
                height: 5,
              ),
              for (int i = 0; i < outLenght; i++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Salida $i',
                      style: const TextStyle(
                        color: color4,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_oldDevice) ...[
                      Transform.scale(
                        scale: 1,
                        child: Switch(
                          value: _estado,
                          onChanged: (newValue) {
                            final String tc =
                                'devices_rx/$pc/${_serialCtrl.text.trim()}';
                            final String tc2 =
                                'devices_tx/$pc/${_serialCtrl.text.trim()}';
                            final String message = jsonEncode({
                              "w_status": newValue,
                            });
                            sendMessagemqtt(tc, message);
                            sendMessagemqtt(tc2, message);

                            setState(() {
                              _estado = newValue;
                            });
                          },
                        ),
                      ),
                    ] else ...[
                      Transform.scale(
                        scale: 1,
                        child: Switch(
                          value: ioData['io$i']?['w_status'] ?? false,
                          onChanged: (newValue) {
                            final String tc =
                                'devices_rx/$pc/${_serialCtrl.text.trim()}';
                            final String tc2 =
                                'devices_tx/$pc/${_serialCtrl.text.trim()}';

                            final message = jsonEncode({
                              "w_status": newValue,
                              "index": i,
                              "r_state": "0",
                              "pinType": 0,
                            });

                            sendMessagemqtt(tc, message);
                            sendMessagemqtt(tc2, message);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              for (int j = outLenght; j < outLenght + inLenght; j++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Entrada $j',
                      style: const TextStyle(
                        color: color4,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      (ioData['io$j']?['r_state']?.toString() !=
                              (ioData['io$j']?['w_status'] == true ? '1' : '0'))
                          ? Icons.error
                          : Icons.error_outline,
                      color: (ioData['io$j']?['r_state']?.toString() !=
                              (ioData['io$j']?['w_status'] == true ? '1' : '0'))
                          ? Colors.red
                          : Colors.grey,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;
    return Scaffold(
      backgroundColor: color4,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          backgroundColor: color4,
          foregroundColor: color4,
          title: const Align(
            alignment: Alignment.center,
            child: Text(
              'Control de WiFi',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    border: InputBorder.none,
                  ),
                  hint: const Text(
                    'Seleccione un código',
                    style: TextStyle(color: color3),
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
                      pc = value ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(height: 6),
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
                    controller: _serialCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ingrese el número de serie',
                      labelStyle: const TextStyle(color: color3),
                      hintStyle: const TextStyle(color: color3),
                      hintText: 'Número de serie',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _serialCtrl.clear();
                            unSubToTopicMQTT(
                                'devices_tx/$pc:${_serialCtrl.text.trim()}');
                            testing = false;
                            _oldDevice = false;
                            created = false;
                            outController.clear();
                            inController.clear();
                          });
                        },
                        icon: const Icon(
                          Icons.delete_forever,
                          color: color3,
                        ),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(
                color: color1,
                thickness: 1.5,
                height: 32,
              ),
              buildButton(
                  text: 'Probar equipo',
                  onPressed: !testing ? _loadDevice : null),
              const SizedBox(height: 12),
              if (testing) ...[
                if (pc == '015773_IOT') ...[
                  detectors()
                ] else if (pc == '020010_IOT' ||
                    pc == '020020_IOT' ||
                    pc == '027313_IOT') ...[
                  multipleOutputDevices()
                ] else if (pc == '027170_IOT' || pc == '024011_IOT')
                  ...[]
                else if (pc == '023430_IOT') ...[
                  termometro()
                ] else ...[
                  otherDevices()
                ],
              ] else ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Por favor, seleccione un código de producto y escriba un número de serie, luego presione el botón.',
                    style: TextStyle(
                      color: color0,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
