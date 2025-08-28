// file: resource_monitor_page.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'dart:convert'; // Necesario para el fallback a JSON/UTF8
import '../../master.dart'; // Asegúrate de que esta ruta sea correcta

class ResourceMonitorPage extends StatefulWidget {
  const ResourceMonitorPage({super.key});

  @override
  State<ResourceMonitorPage> createState() => _ResourceMonitorPageState();
}

class _ResourceMonitorPageState extends State<ResourceMonitorPage> {
  // --- State Variables ---

  // Para los datos que se leen una sola vez
  Map<String, dynamic> _staticData = {};
  bool _isLoadingStaticData = true;

  // Para los datos que llegan por notificación (en tiempo real)
  Map<String, dynamic> _dynamicData = {};

  @override
  void initState() {
    super.initState();
    _readStaticData();
    _startSubscription();
  }

  // --- Data Handling Logic ---

  /// Decodifica los datos recibidos.
  /// Reutilizado de tu clase LoggerBlePage para mantener la consistencia.
  dynamic _decodeMessagePack(List<int> data) {
    try {
      final uint8Data = Uint8List.fromList(data);
      return deserialize(uint8Data);
    } catch (e) {
      // Fallback a UTF-8 por si acaso
      try {
        final textData = utf8.decode(data, allowMalformed: true).trim();
        if (textData.startsWith('{') || textData.startsWith('[')) {
          return jsonDecode(textData);
        }
        return {'error': 'Formato desconocido', 'raw': textData};
      } catch (_) {
        String hexData =
            data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        return {'error': 'Fallo total de decodificación', 'hex': hexData};
      }
    }
  }

  /// Lee los datos estáticos de la característica.
  Future<void> _readStaticData() async {
    setState(() {
      _isLoadingStaticData = true;
    });

    try {
      List<int> value = await bluetoothManager.resourceMonitorUuid.read();
      if (value.isNotEmpty) {
        final decodedData = _decodeMessagePack(value);
        if (decodedData is Map) {
          setState(() {
            _staticData = Map<String, dynamic>.from(decodedData);
          });
        }
      }
    } catch (e) {
      printLog('Error leyendo datos estáticos del monitor: $e', 'rojo');
      showToast('Error al leer datos del dispositivo');
    } finally {
      setState(() {
        _isLoadingStaticData = false;
      });
    }
  }

  /// Inicia la suscripción a los datos en tiempo real.
  void _startSubscription() async {
    try {
      final resourceMonitorSubscription =
          bluetoothManager.resourceMonitorUuid.onValueReceived.listen(
        (List<int> data) {
          if (data.isNotEmpty) {
            final decoded = _decodeMessagePack(data);
            printLog('Datos recibidos del monitor: $decoded', 'verde');
            if (decoded is Map) {
              setState(() {
                // Actualizamos el mapa con los nuevos valores
                _dynamicData = Map<String, dynamic>.from(decoded);
              });
            }
          }
        },
        onError: (error) {
          printLog(
              'Error en el stream del monitor de recursos: $error', 'rojo');
        },
      );
      printLog('Iniciando suscripción al monitor de recursos...', 'verde');
      await bluetoothManager.resourceMonitorUuid.setNotifyValue(true);
      printLog('Suscripción activada.', 'verde');
      bluetoothManager.device
          .cancelWhenDisconnected(resourceMonitorSubscription);

      setState(() {});
    } catch (e) {
      printLog('Error al iniciar la suscripción del monitor: $e', 'rojo');
    }
  }

  // --- UI Builder Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de Información Estática
            _buildStaticInfoCard(),
            const SizedBox(height: 20),

            // Sección de Monitoreo en Tiempo Real
            _buildDynamicInfoCard(),
            const SizedBox(height: kBottomNavigationBarHeight + 20),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar la información estática del dispositivo.
  Widget _buildStaticInfoCard() {
    return Card(
      color: color0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: color1, width: 1),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Dispositivo',
              style: TextStyle(
                color: color4,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            if (_isLoadingStaticData)
              const Center(child: CircularProgressIndicator())
            else if (_staticData.isEmpty)
              const Center(
                child: Text('No se pudieron cargar los datos.',
                    style: TextStyle(color: color3)),
              )
            else
              ..._staticData.entries.map(
                (entry) => _buildInfoRow(
                  _getSpanishLabel(entry.key), // Traduce la clave a español
                  entry.value.toString(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar los datos dinámicos con barras de progreso.
  Widget _buildDynamicInfoCard() {
    return Card(
      color: color0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: color1, width: 1),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recursos en Tiempo Real',
              style: TextStyle(
                color: color4,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_dynamicData.isNotEmpty) ...{
              _buildProgressIndicators()
            } else ...{
              const Center(
                child: Text(
                  'Aún no hay ningun valor recibido',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color3, fontSize: 16),
                ),
              ),
            },
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Contenedor de las barras de progreso
  Widget _buildProgressIndicators() {
    return Column(
      children: [
        _buildProgressIndicator(
          label: 'Uso del Heap',
          value: _dynamicData['used_heap'] ?? 0,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          label: 'Máximo Heap Usado',
          value: _dynamicData['max_used_heap'] ?? 0,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          label: 'Uso de SPIFFS',
          value: _dynamicData['used_spiffs'] ?? 0,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          label: 'Máximo Stack Usado',
          value: _dynamicData['max_used_stack'] ?? 0,
        ),
      ],
    );
  }

  /// Helper para crear una fila de información (label: value).
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:',
              style:
                  const TextStyle(color: color3, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: color4, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper para crear una barra de progreso con su label.
  Widget _buildProgressIndicator({required String label, required int value}) {
    final double progress = (value.clamp(0, 100)) / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style:
                  const TextStyle(color: color3, fontWeight: FontWeight.bold),
            ),
            Text(
              '$value%',
              style: const TextStyle(
                  color: color2, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color1.withValues(alpha: 0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(color2),
          minHeight: 10,
        ),
      ],
    );
  }

  /// Función para "traducir" las claves del micro a un formato más legible.
  String _getSpanishLabel(String key) {
    switch (key) {
      case 'used_app':
        return 'Uso de APP';
      case 'chip_model':
        return 'Modelo de Chip';
      case 'chip_rev':
        return 'Revisión del Chip';
      case 'idf_sdk':
        return 'Versión SDK';
      case 'efuse_mac':
        return 'MAC Address';
      case 'app_md5':
        return 'Checksum App (MD5)';
      case 'cpu_freq':
        return 'Frecuencia CPU (MHz)';
      default:
        return key;
    }
  }
}
