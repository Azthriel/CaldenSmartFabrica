import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import '../../master.dart';

class LoggerBlePage extends StatefulWidget {
  const LoggerBlePage({super.key});

  @override
  LoggerBlePageState createState() => LoggerBlePageState();
}

class LoggerBlePageState extends State<LoggerBlePage> {
  // Variables para el logger en tiempo real
  List<Map<String, dynamic>> liveLogMessages = [];
  bool isLiveSubscribed = false;
  StreamSubscription<List<int>>? liveLoggerSubscription;

  // Variables para el registro histórico
  List<String> registeredLogMessages = [];
  bool isRegisterSubscribed = false;
  StreamSubscription<List<int>>? registerLoggerSubscription;

  // Controlador para el campo de texto de escritura
  final TextEditingController _writeController = TextEditingController();

  // Controlador para scroll automático
  final ScrollController _liveScrollController = ScrollController();
  final ScrollController _registerScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _stopLiveLogger();
    _stopRegisterLogger();
    _liveScrollController.dispose();
    _registerScrollController.dispose();
    _writeController.dispose();
    super.dispose();
  }

  // Función para decodificar MessagePack
  dynamic _decodeMessagePack(List<int> data) {
    try {
      // Convertimos List<int> a Uint8List para MessagePack
      final uint8Data = Uint8List.fromList(data);
      final result = deserialize(uint8Data);
      return result;
    } catch (e) {
      // Si falla MessagePack, intentamos como UTF-8
      try {
        String textData = utf8.decode(data, allowMalformed: true);
        textData = textData.trim();

        if (textData.isNotEmpty && !textData.contains('\uFFFD')) {
          // Si parece JSON, intentamos parsearlo
          if (textData.startsWith('{') || textData.startsWith('[')) {
            try {
              return jsonDecode(textData);
            } catch (e) {
              return textData;
            }
          }
          return textData;
        }
      } catch (e) {
        // Si UTF-8 también falla, continuamos
      }

      // Como último recurso, mostramos información de debug
      String hexData =
          data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
      String asciiData = data
          .map((byte) =>
              (byte >= 32 && byte <= 126) ? String.fromCharCode(byte) : '.')
          .join('');

      printLog('Error decodificando MessagePack: $e', 'rojo');
      printLog('Datos HEX: $hexData', 'amarillo');
      printLog('Datos ASCII: $asciiData', 'amarillo');

      return {
        'error': 'Error decodificando datos',
        'raw_hex': hexData,
        'raw_ascii': asciiData,
        'exception': e.toString()
      };
    }
  }

  // Función para formatear los datos del log
  Map<String, dynamic> _formatLogData(dynamic logData) {
    try {
      String content = 'Datos inválidos';
      String level = 'INFO';
      int timestampMs = DateTime.now().millisecondsSinceEpoch;

      // Si es un mapa (JSON decodificado), extraemos la información
      if (logData is Map) {
        // Extraer el contenido
        content = logData['content']?.toString() ??
            logData['message']?.toString() ??
            logData['msg']?.toString() ??
            logData['text']?.toString() ??
            'Sin contenido';

        // Extraer el nivel de log
        level = logData['log_level']?.toString() ??
            logData['level']?.toString() ??
            logData['lvl']?.toString() ??
            logData['severity']?.toString() ??
            'INFO';

        // Extraer el timestamp (siempre viene en milisegundos)
        if (logData['timestamp'] != null) {
          try {
            timestampMs = int.parse(logData['timestamp'].toString());
          } catch (e) {
            // Si falla el parsing, usar tiempo actual
            timestampMs = DateTime.now().millisecondsSinceEpoch;
          }
        }
      }
      // Si es un string directo
      else if (logData is String) {
        content = logData;
      }
      // Para otros tipos
      else {
        content = logData.toString();
      }

      return {
        'content': content,
        'level': level.toUpperCase(),
        'timestampMs': timestampMs,
        'formattedTime': _formatTimestampFromMs(timestampMs),
      };
    } catch (e) {
      return {
        'content': 'Error formateando: $e',
        'level': 'ERROR',
        'timestampMs': DateTime.now().millisecondsSinceEpoch,
        'formattedTime': _formatTimestampFromMs(DateTime.now().millisecondsSinceEpoch),
      };
    }
  }

  // Función para obtener color según log level
  Color _getLogLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return Colors.blue.shade300;
      case 'INFO':
        return Colors.green.shade400;
      case 'WARN':
      case 'WARNING':
        return Colors.orange.shade400;
      case 'ERROR':
        return Colors.red.shade400;
      default:
        return color4;
    }
  }

  // Función para formatear timestamp desde milisegundos
  String _formatTimestampFromMs(int timestampMs) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);

    // Formatear con milisegundos
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');
    String millisecond = dateTime.millisecond.toString().padLeft(3, '0');

    return '$hour:$minute:$second.$millisecond';
  }

  // Función para suscribirse al live logger
  void _startLiveLogger() async {
    try {
      if (!isLiveSubscribed) {
        await bluetoothManager.liveLoggerUuid.setNotifyValue(true);
        liveLoggerSubscription =
            bluetoothManager.liveLoggerUuid.lastValueStream.listen(
          (data) {
            if (data.isNotEmpty) {
              final decoded = _decodeMessagePack(data);
              final formattedMessage = _formatLogData(decoded);

              setState(() {
                // Agregar el nuevo mensaje al principio de la lista
                liveLogMessages.insert(0, formattedMessage);

                // Limitar el número de mensajes para evitar problemas de memoria
                if (liveLogMessages.length > 1000) {
                  liveLogMessages.removeLast(); // Remover el último (más viejo)
                }
              });

              // Auto-scroll al inicio (donde están los mensajes nuevos)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_liveScrollController.hasClients) {
                  _liveScrollController.animateTo(
                    0, // Scroll al inicio
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          },
          onError: (error) {
            printLog('Error en live logger stream: $error', 'rojo');
          },
        );

        setState(() {
          isLiveSubscribed = true;
        });

        printLog('Suscrito al live logger', 'verde');
        showToast('Suscrito al live logger');
      }
    } catch (e) {
      printLog('Error iniciando live logger: $e', 'rojo');
      showToast('Error iniciando live logger');
    }
  }

  // Función para detener la suscripción al live logger
  void _stopLiveLogger() async {
    try {
      if (isLiveSubscribed) {
        await bluetoothManager.liveLoggerUuid.setNotifyValue(false);
        liveLoggerSubscription?.cancel();

        setState(() {
          isLiveSubscribed = false;
        });

        printLog('Desuscrito del live logger', 'amarillo');
        showToast('Desuscrito del live logger');
      }
    } catch (e) {
      printLog('Error deteniendo live logger: $e', 'rojo');
    }
  }

  // Función para iniciar la suscripción del registro
  void _startRegisterLogger() async {
    if (isRegisterSubscribed) return;

    try {
      // Asegurarse de que las notificaciones estén habilitadas
      await bluetoothManager.registerLoggerUuid.setNotifyValue(true);

      registerLoggerSubscription =
          bluetoothManager.registerLoggerUuid.onValueReceived.listen(
        (data) {
          if (data.isNotEmpty) {
            final decoded = _decodeMessagePack(data);

            // Si es una lista de logs, procesamos cada uno
            if (decoded is List) {
              for (var logEntry in decoded) {
                final formattedMessage = _formatLogData(logEntry);
                setState(() {
                  registeredLogMessages.insert(0,
                      '${formattedMessage['content']} | ${formattedMessage['formattedTime']}');
                });
              }
            } else {
              // Si es un solo entry, lo agregamos
              final formattedMessage = _formatLogData(decoded);
              setState(() {
                registeredLogMessages.insert(0,
                    '${formattedMessage['content']} | ${formattedMessage['formattedTime']}');
              });
            }

            // Auto-scroll hacia arriba para mostrar los nuevos mensajes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_registerScrollController.hasClients) {
                _registerScrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        },
        onError: (error) {
          printLog('Error en suscripción del registro: $error', 'rojo');
          showToast('Error en suscripción del registro');
        },
      );

      setState(() {
        isRegisterSubscribed = true;
      });

      showToast('Suscrito al registro');
      printLog('Suscripción al registro iniciada correctamente', 'verde');
    } catch (e) {
      printLog('Error iniciando suscripción del registro: $e', 'rojo');
      showToast('Error iniciando suscripción');
    }
  }

  // Función para detener la suscripción del registro
  void _stopRegisterLogger() async {
    if (!isRegisterSubscribed) return;

    try {
      await registerLoggerSubscription?.cancel();
      registerLoggerSubscription = null;
      await bluetoothManager.registerLoggerUuid.setNotifyValue(false);

      setState(() {
        isRegisterSubscribed = false;
      });

      showToast('Desuscrito del registro');
    } catch (e) {
      printLog('Error deteniendo suscripción del registro: $e', 'rojo');
      showToast('Error deteniendo suscripción');
    }
  }

  // Función para escribir a la característica del registro
  void _writeToRegister() async {
    if (_writeController.text.trim().isEmpty) {
      showToast('Escribe algo para enviar');
      return;
    }

    try {
      String message = _writeController.text.trim();
      List<int> data = utf8.encode(message);

      // Escribir al dispositivo
      await bluetoothManager.registerLoggerUuid.write(data);

      showToast('Mensaje enviado: $message');
      _writeController.clear();

      // Pequeña pausa para que el dispositivo procese y responda
      await Future.delayed(const Duration(milliseconds: 100));

      // Si no estamos suscritos, intentar leer la respuesta inmediata
      if (!isRegisterSubscribed) {
        try {
          List<int> response = await bluetoothManager.registerLoggerUuid.read();
          if (response.isNotEmpty) {
            final decoded = _decodeMessagePack(response);
            final formattedMessage = _formatLogData(decoded);
            setState(() {
              registeredLogMessages.insert(0,
                  'Respuesta: ${formattedMessage['content']} | ${formattedMessage['formattedTime']}');
            });
          }
        } catch (e) {
          // Si falla la lectura, no es crítico
          printLog('No se pudo leer respuesta inmediata: $e', 'amarillo');
        }
      }
    } catch (e) {
      printLog('Error escribiendo al registro: $e', 'rojo');
      showToast('Error enviando mensaje');
    }
  } // Función para limpiar los mensajes del registro

  void _clearRegisterMessages() {
    setState(() {
      registeredLogMessages.clear();
    });
    showToast('Registro limpiado');
  }

  // Función para limpiar los logs en tiempo real
  void _clearLiveLogs() {
    setState(() {
      liveLogMessages.clear();
    });
    showToast('Logs limpiados');
  }

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de la pantalla para adaptarse
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: color4,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Tab Bar
            Container(
              color: color4,
              child: TabBar(
                indicator: BoxDecoration(
                  color: color1,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: color4,
                unselectedLabelColor: color1,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenHeight < 700 ? 14 : 16,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.live_tv),
                    text: 'Live Logger',
                  ),
                  Tab(
                    icon: Icon(Icons.storage),
                    text: 'Registro',
                  ),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  // Primera pestaña: Live Logger
                  _buildLiveLoggerTab(screenHeight),
                  // Segunda pestaña: Registro
                  _buildRegisterTab(screenHeight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveLoggerTab(double screenHeight) {
    return Padding(
      padding: EdgeInsets.all(screenHeight < 700 ? 8.0 : 16.0),
      child: Column(
        children: [
          // Controles simplificados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed:
                    isLiveSubscribed ? _stopLiveLogger : _startLiveLogger,
                icon: Icon(
                  isLiveSubscribed ? Icons.stop : Icons.play_arrow,
                  color: color4,
                  size: screenHeight < 700 ? 18 : 24,
                ),
                label: Text(
                  isLiveSubscribed ? 'Detener' : 'Iniciar',
                  style: TextStyle(
                    color: color4,
                    fontSize: screenHeight < 700 ? 12 : 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLiveSubscribed ? Colors.red : Colors.green,
                  padding: EdgeInsets.symmetric(
                      horizontal: screenHeight < 700 ? 12 : 20,
                      vertical: screenHeight < 700 ? 8 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: liveLogMessages.isNotEmpty ? _clearLiveLogs : null,
                icon: Icon(
                  Icons.clear,
                  color: color4,
                  size: screenHeight < 700 ? 18 : 24,
                ),
                label: Text(
                  'Limpiar',
                  style: TextStyle(
                    color: color4,
                    fontSize: screenHeight < 700 ? 12 : 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color1,
                  padding: EdgeInsets.symmetric(
                      horizontal: screenHeight < 700 ? 12 : 20,
                      vertical: screenHeight < 700 ? 8 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight < 700 ? 8 : 20),

          // Pantalla de logs (ocupa la mayor parte del espacio)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color0,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color1, width: 2),
              ),
              child: liveLogMessages.isEmpty
                  ? Center(
                      child: Text(
                        'No hay mensajes.\nPresiona "Iniciar" para comenzar a recibir logs.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color3,
                          fontSize: screenHeight < 700 ? 14 : 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _liveScrollController,
                      padding: EdgeInsets.all(screenHeight < 700 ? 8 : 12),
                      itemCount: liveLogMessages.length,
                      itemBuilder: (context, index) {
                        final message = liveLogMessages[index];
                        return Container(
                          margin: EdgeInsets.symmetric(
                              vertical: screenHeight < 700 ? 2 : 4),
                          padding: EdgeInsets.all(screenHeight < 700 ? 8 : 12),
                          decoration: BoxDecoration(
                            color: _getLogLevelColor(message['level'])
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getLogLevelColor(message['level']),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Contenido principal (adaptativo)
                              Text(
                                message['content'],
                                style: TextStyle(
                                  color: color4,
                                  fontSize: screenHeight < 700 ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: screenHeight < 700 ? 4 : 8),
                              // Timestamp y nivel (pequeño, abajo a la derecha)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Badge del nivel
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: screenHeight < 700 ? 6 : 8,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          _getLogLevelColor(message['level']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      message['level'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenHeight < 700 ? 8 : 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Timestamp
                                  Text(
                                    message['formattedTime'] ?? '',
                                    style: TextStyle(
                                      color: color3,
                                      fontSize: screenHeight < 700 ? 10 : 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(double screenHeight) {
    return Padding(
      padding: EdgeInsets.all(screenHeight < 700 ? 8.0 : 16.0),
      child: Column(
        children: [
          // Controles del Registro
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón de Suscribir/Desuscribir
              ElevatedButton.icon(
                onPressed: isRegisterSubscribed
                    ? _stopRegisterLogger
                    : _startRegisterLogger,
                icon: Icon(
                  isRegisterSubscribed ? Icons.stop : Icons.play_arrow,
                  color: color4,
                  size: screenHeight < 700 ? 16 : 20,
                ),
                label: Text(
                  isRegisterSubscribed ? 'Desuscribir' : 'Suscribir',
                  style: TextStyle(
                    color: color4,
                    fontSize: screenHeight < 700 ? 10 : 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isRegisterSubscribed ? Colors.red.shade600 : color1,
                  padding: EdgeInsets.symmetric(
                      horizontal: screenHeight < 700 ? 8 : 12,
                      vertical: screenHeight < 700 ? 6 : 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Botón de Limpiar
              ElevatedButton.icon(
                onPressed: _clearRegisterMessages,
                icon: Icon(
                  Icons.clear_all,
                  color: color4,
                  size: screenHeight < 700 ? 16 : 20,
                ),
                label: Text(
                  'Limpiar',
                  style: TextStyle(
                    color: color4,
                    fontSize: screenHeight < 700 ? 10 : 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  padding: EdgeInsets.symmetric(
                      horizontal: screenHeight < 700 ? 8 : 12,
                      vertical: screenHeight < 700 ? 6 : 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight < 700 ? 8 : 16),

          // Campo de texto y botón para escribir
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _writeController,
                  style: TextStyle(
                    color: color4,
                    fontSize: screenHeight < 700 ? 14 : 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje para enviar...',
                    hintStyle: TextStyle(
                      color: color3,
                      fontSize: screenHeight < 700 ? 14 : 16,
                    ),
                    filled: true,
                    fillColor: color0,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: color1, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: color1, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: color2, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenHeight < 700 ? 8 : 12,
                      vertical: screenHeight < 700 ? 8 : 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenHeight < 700 ? 8 : 12),
              ElevatedButton(
                onPressed: _writeToRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color2,
                  padding: EdgeInsets.all(screenHeight < 700 ? 12 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Icon(
                  Icons.send,
                  color: color4,
                  size: screenHeight < 700 ? 20 : 24,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight < 700 ? 8 : 16),

          // Lista de registros
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color0,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color1, width: 2),
              ),
              child: registeredLogMessages.isEmpty
                  ? Center(
                      child: Text(
                        isRegisterSubscribed
                            ? 'Esperando mensajes del registro...'
                            : 'No hay registros cargados.\nPresiona "Suscribir" para recibir datos en tiempo real.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color3,
                          fontSize: screenHeight < 700 ? 14 : 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _registerScrollController,
                      padding: EdgeInsets.all(screenHeight < 700 ? 8 : 12),
                      itemCount: registeredLogMessages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                              vertical: screenHeight < 700 ? 2 : 4),
                          padding: EdgeInsets.all(screenHeight < 700 ? 8 : 12),
                          decoration: BoxDecoration(
                            color: index % 2 == 0
                                ? color4.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: color1.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Text(
                            registeredLogMessages[index],
                            style: TextStyle(
                              color: color4,
                              fontSize: screenHeight < 700 ? 12 : 14,
                              fontFamily: 'Courier',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        ],
      ),
    );
  }
}
