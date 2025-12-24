import 'dart:convert';
import 'dart:io';

import 'package:caldensmartfabrica/aws/mqtt/mqtt_certificates.dart';
import 'package:caldensmartfabrica/master.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';

MqttServerClient? mqttAWSFlutterClient;

Future<bool> setupMqtt() async {
  try {
    printLog('Haciendo setup');
    String deviceId = 'FlutterFabrica/${generateRandomNumbers(32)}';

    mqttAWSFlutterClient = MqttServerClient(broker, deviceId);

    mqttAWSFlutterClient!.secure = true;
    mqttAWSFlutterClient!.port = 8883; // Puerto estándar para MQTT sobre TLS
    mqttAWSFlutterClient!.securityContext = SecurityContext.defaultContext;

    mqttAWSFlutterClient!.securityContext
        .setTrustedCertificatesBytes(utf8.encode(caCert));
    mqttAWSFlutterClient!.securityContext
        .useCertificateChainBytes(utf8.encode(certChain));
    mqttAWSFlutterClient!.securityContext
        .usePrivateKeyBytes(utf8.encode(privateKey));

    mqttAWSFlutterClient!.logging(on: true);
    mqttAWSFlutterClient!.onDisconnected = mqttonDisconnected;

    // Configuración de las credenciales
    mqttAWSFlutterClient!.setProtocolV311();
    mqttAWSFlutterClient!.keepAlivePeriod = 30;
    try {
      await mqttAWSFlutterClient!.connect();
      printLog('Usuario conectado a mqtt');

      return true;
    } catch (e) {
      printLog('Error intentando conectar: $e');

      return false;
    }
  } catch (e, s) {
    printLog('Error setup mqtt $e $s');
    return false;
  }
}

void mqttonDisconnected() {
  printLog('Desconectado de mqtt');
  reconnectMqtt();
}

void reconnectMqtt() async {
  await setupMqtt().then((value) {
    if (value) {
      listenToTopics();
    } else {
      reconnectMqtt();
    }
  });
}

void sendMessagemqtt(String topic, String message) {
  printLog('Voy a mandar $message');
  printLog('A el topic $topic');
  final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  builder.addString(message);

  printLog('${builder.payload} : ${utf8.decode(builder.payload!)}');

  try {
    mqttAWSFlutterClient!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
    printLog('Mensaje enviado');
  } catch (e, s) {
    printLog('Error sending message $e $s');
  }
}

void subToTopicMQTT(String topic) {
  try {
    mqttAWSFlutterClient!.subscribe(topic, MqttQos.atLeastOnce);
    printLog('Subscrito correctamente a $topic');
  } catch (e) {
    printLog('Error al subscribir al topic $topic, $e');
  }
}

void unSubToTopicMQTT(String topic) {
  mqttAWSFlutterClient!.unsubscribe(topic);
  printLog('Me desuscribo de $topic');
}

void listenToTopics() {
  mqttAWSFlutterClient!.updates!.listen((c) {
    printLog('LLego algo(mqtt)');
    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final String topic = c[0].topic;
    var listNames = topic.split('/');
    final List<int> message = recMess.payload.message;
    String keyName = "${listNames[1]}/${listNames[2]}";
    printLog('Keyname: $keyName');

    final String messageString = utf8.decode(message);
    printLog('Mensaje: $messageString');
    try {
      final Map<String, dynamic> messageMap = json.decode(messageString);

      if (messageMap['esp_res'] != null) {
        if (messageMap['esp_res'].toString().contains(':')) {
          List<String> parts = messageMap['esp_res'].toString().split(':');
          if (parts.length < 4 && !parts[0].contains('OTA')) {
            deviceResponseMqtt = 'ActualTemp: ${parts[0]}\nOffset: ${parts[1]}';
          } else if (parts.length >= 4) {
            deviceResponseMqtt = 'SoftVer: ${parts[2]}\nHardVer: ${parts[3]}';
          } else {
            deviceResponseMqtt = messageMap['esp_res'].toString();
          }

          showToast('Equipo conectado');
        } else {
          deviceResponseMqtt = messageMap['esp_res'].toString();
        }
      } else {
        deviceResponseMqtt = 'No hubo respuesta';
      }

      if (messageMap['cstate'] != null) {
        isConnectedToAWS = messageMap['cstate'];
        printLog('Estado de conexión AWS actualizado a: $isConnectedToAWS');
      }

      try {
        if (navigatorKey.currentContext != null) {
          GlobalDataNotifier notifier = Provider.of<GlobalDataNotifier>(
              navigatorKey.currentContext!,
              listen: false);
          notifier.updateData(deviceResponseMqtt);
          if (messageMap['cstate'] != null) {
            notifier.updateAWSConnectionState(isConnectedToAWS);
            printLog('Provider notificado con estado AWS: $isConnectedToAWS');
          }
        } else {
          printLog('WARNING: navigatorKey.currentContext es null, no se puede notificar al Provider');
        }
      } catch (e, stackTrace) {
        printLog('Error notificando al Provider: $e');
        printLog('StackTrace: $stackTrace');
      }

      printLog('Received message: $messageMap from topic: $topic');
    } catch (e) {
      printLog('Error decoding message: $e');
    }
  });
}
