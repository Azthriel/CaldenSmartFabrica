// file: resource_monitor_page.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'dart:convert'; // Necesario para el fallback a JSON/UTF8
import '../../master.dart'; // Asegúrate de que esta ruta sea correcta

// =======================================================================
// MODELO DE PARÁMETROS CONFIGURABLES
// Estos valores viven dentro de staticResmonData, pero además de mostrarse
// se pueden editar y reenviar al device por la misma característica.
// Para agregar uno nuevo en el futuro: solo sumar una entrada acá.
// =======================================================================

enum ConfigType { boolean, enumSelect }

class ConfigOption {
  final String label;
  final dynamic value;
  const ConfigOption(this.label, this.value);
}

class ConfigParam {
  final String key;
  final ConfigType type;
  final List<ConfigOption>? options; // requerido para enumSelect

  const ConfigParam({
    required this.key,
    required this.type,
    this.options,
  });
}

final List<ConfigParam> configurableParams = [
  const ConfigParam(
    key: 'cpu_freq',
    type: ConfigType.enumSelect,
    options: [
      ConfigOption('10 MHz', 10),
      ConfigOption('20 MHz', 20),
      ConfigOption('40 MHz', 40),
      ConfigOption('80 MHz', 80),
      ConfigOption('160 MHz', 160),
    ],
  ),
  const ConfigParam(
    key: 'ext_ant',
    type: ConfigType.boolean,
  ),
  const ConfigParam(
    key: 'ble_tx_power',
    type: ConfigType.enumSelect,
    options: [
      ConfigOption('-24 dBm', 0),
      ConfigOption('-21 dBm', 1),
      ConfigOption('-18 dBm', 2),
      ConfigOption('-15 dBm', 3),
      ConfigOption('-12 dBm', 4),
      ConfigOption('-9 dBm', 5),
      ConfigOption('-6 dBm', 6),
      ConfigOption('-3 dBm', 7),
      ConfigOption('0 dBm', 8),
      ConfigOption('+3 dBm', 9),
      ConfigOption('+6 dBm', 10),
      ConfigOption('+9 dBm', 11),
      ConfigOption('+12 dBm', 12),
      ConfigOption('+15 dBm', 13),
      ConfigOption('+18 dBm', 14),
      ConfigOption('+21 dBm', 15),
    ],
  ),
  const ConfigParam(
    key: 'wifi_tx_power',
    type: ConfigType.enumSelect,
    options: [
      ConfigOption('19.5 dBm', 78),
      ConfigOption('19 dBm', 76),
      ConfigOption('18.5 dBm', 74),
      ConfigOption('17 dBm', 68),
      ConfigOption('15 dBm', 60),
      ConfigOption('13 dBm', 52),
      ConfigOption('11 dBm', 44),
      ConfigOption('8.5 dBm', 34),
      ConfigOption('7 dBm', 28),
      ConfigOption('5 dBm', 20),
      ConfigOption('2 dBm', 8),
      ConfigOption('-1 dBm', -4),
    ],
  ),
];

class ResourceMonitorPage extends StatefulWidget {
  const ResourceMonitorPage({super.key});

  @override
  State<ResourceMonitorPage> createState() => _ResourceMonitorPageState();
}

class _ResourceMonitorPageState extends State<ResourceMonitorPage> {
  // --- State Variables ---

  bool _isLoadingStaticData = true;
  bool _isSavingConfig = false;
  StreamSubscription<List<int>>? resourceMonitorSubscription;
  Map<String, dynamic> realTimeResmonData = {};
  Map<String, dynamic> staticResmonData = {};

  // Copia editable de los valores configurables. Se inicializa cada vez que
  // se leen datos estáticos nuevos del device.
  Map<String, dynamic> pendingConfig = {};

  Set<String> get _configurableKeys =>
      configurableParams.map((p) => p.key).toSet();

  // Solo usuarios con nivel de acceso 3 o superior pueden editar.
  // `accessLevel` es la variable global que se carga al loguearse con legajo.
  bool get _canEditConfig => accessLevel >= 3;

  bool get _hasChanges {
    for (final param in configurableParams) {
      if (!pendingConfig.containsKey(param.key)) continue;
      if (pendingConfig[param.key] != staticResmonData[param.key]) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _readStaticData();
    _startSubscription();
  }

  @override
  void dispose() {
    resourceMonitorSubscription?.cancel();
    bluetoothManager.resourceMonitorUuid.setNotifyValue(false);
    super.dispose();
  }

  // --- Data Handling Logic ---

  /// Decodifica los datos recibidos.
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
        printLog('Datos estáticos recibidos del monitor: $value', 'verde');
        final decodedData = _decodeMessagePack(value);
        if (decodedData is Map) {
          printLog('Datos estáticos decodificados: $decodedData', 'verde');
          final data = Map<String, dynamic>.from(decodedData);
          setState(() {
            staticResmonData = data;
            // Inicializa (o reinicializa) la copia editable con los
            // valores configurables presentes en la respuesta del device.
            pendingConfig = {
              for (final key in _configurableKeys)
                if (data.containsKey(key)) key: data[key],
            };
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

  /// Envía únicamente las claves configurables que cambiaron respecto al
  /// último valor confirmado por el device (no el mapa estático completo).
  Future<void> _saveConfig() async {
    if (!_canEditConfig) return;

    setState(() => _isSavingConfig = true);

    final Map<String, dynamic> changedValues = {};
    for (final param in configurableParams) {
      if (!pendingConfig.containsKey(param.key)) continue;
      if (pendingConfig[param.key] != staticResmonData[param.key]) {
        changedValues[param.key] = pendingConfig[param.key];
      }
    }

    if (changedValues.isEmpty) {
      setState(() => _isSavingConfig = false);
      return;
    }

    try {
      final bytes = serialize(changedValues);
      await bluetoothManager.resourceMonitorUuid.write(bytes);
      printLog('Cambios enviados al device: $changedValues', 'verde');
      setState(() {
        staticResmonData = {
          ...staticResmonData,
          ...changedValues,
        };
      });
      showToast('Configuración guardada');
      final String pc = DeviceManager.getProductCode(deviceName);
      final String sn = DeviceManager.extractSerialNumber(deviceName);
      registerActivity(pc, sn,
          'Configuración del monitor de recursos modificada: $changedValues');
    } catch (e) {
      printLog('Error al guardar la configuración: $e', 'rojo');
      showToast('Error al guardar la configuración');
    } finally {
      setState(() => _isSavingConfig = false);
    }
  }

  void _discardChanges() {
    setState(() {
      pendingConfig = {
        for (final key in _configurableKeys)
          if (staticResmonData.containsKey(key)) key: staticResmonData[key],
      };
    });
  }

  /// Inicia la suscripción a los datos en tiempo real.
  void _startSubscription() async {
    try {
      resourceMonitorSubscription =
          bluetoothManager.resourceMonitorUuid.onValueReceived.listen(
        (List<int> data) {
          if (data.isNotEmpty) {
            final decoded = _decodeMessagePack(data);
            printLog('Datos recibidos del monitor: $decoded', 'verde');
            if (decoded is Map) {
              setState(() {
                realTimeResmonData = Map<String, dynamic>.from(decoded);
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
      body: RefreshIndicator(
        onRefresh: _readStaticData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección de Información Estática (incluye los editables)
              _buildStaticInfoCard(),
              const SizedBox(height: 20),

              // Sección de Monitoreo en Tiempo Real
              _buildDynamicInfoCard(),
              const SizedBox(height: kBottomNavigationBarHeight + 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para mostrar la información estática del dispositivo.
  /// Las claves configurables se renderizan como widgets editables.
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
            else if (staticResmonData.isEmpty)
              const Center(
                child: Text('No se pudieron cargar los datos.',
                    style: TextStyle(color: color3)),
              )
            else ...[
              ...staticResmonData.entries.map((entry) {
                if (_configurableKeys.contains(entry.key) && _canEditConfig) {
                  final param =
                      configurableParams.firstWhere((p) => p.key == entry.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: _buildConfigWidget(param),
                  );
                }
                // Sin acceso suficiente (o claves no configurables): solo lectura.
                return _buildInfoRow(
                  _getSpanishLabel(entry.key),
                  entry.value.toString(),
                );
              }),
              if (_hasChanges && _canEditConfig) ...[
                const Divider(height: 24),
                _buildConfigActionButtons(),
              ],
            ],
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
            if (realTimeResmonData.isNotEmpty) ...{
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
          value: realTimeResmonData['used_heap'] ?? 0,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          label: 'Máximo Heap Usado',
          value: realTimeResmonData['max_used_heap'] ?? 0,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          label: 'Uso de SPIFFS',
          value: realTimeResmonData['used_spiffs'] ?? 0,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          label: 'Máximo Stack Usado',
          value: realTimeResmonData['max_used_stack'] ?? 0,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Temperatura del Núcleo',
              style: TextStyle(color: color3, fontWeight: FontWeight.bold),
            ),
            Text(
              '${realTimeResmonData['core_temp']}°C',
              style: const TextStyle(
                  color: color2, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper para crear una fila de información de solo lectura (label: value).
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

  /// Dispatcher: arma el widget editable según el tipo del parámetro.
  Widget _buildConfigWidget(ConfigParam param) {
    switch (param.type) {
      case ConfigType.boolean:
        return _buildBoolConfigRow(param);
      case ConfigType.enumSelect:
        return _buildEnumConfigRow(param);
    }
  }

  Widget _buildBoolConfigRow(ConfigParam param) {
    final bool value = pendingConfig[param.key] ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${_getSpanishLabel(param.key)}:',
            style: const TextStyle(color: color3, fontWeight: FontWeight.bold)),
        Switch(
          value: value,
          activeThumbColor: color2,
          onChanged: (newValue) {
            setState(() => pendingConfig[param.key] = newValue);
          },
        ),
      ],
    );
  }

  Widget _buildEnumConfigRow(ConfigParam param) {
    final options = param.options ?? [];
    final currentValue = pendingConfig[param.key];

    final selected = options.firstWhere(
      (o) => o.value == currentValue,
      orElse: () =>
          options.isNotEmpty ? options.first : const ConfigOption('—', null),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${_getSpanishLabel(param.key)}:',
            style: const TextStyle(color: color3, fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<dynamic>(
            initialValue: selected.value,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            style: const TextStyle(color: color4, fontSize: 14),
            dropdownColor: color0,
            items: options
                .map(
                  (o) => DropdownMenuItem<dynamic>(
                    value: o.value,
                    child: Text(
                      o.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: color4),
                    ),
                  ),
                )
                .toList(),
            onChanged: (newValue) {
              setState(() => pendingConfig[param.key] = newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfigActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSavingConfig ? null : _discardChanges,
            child: const Text('Descartar', style: TextStyle(color: color4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color2),
            onPressed: _isSavingConfig ? null : _saveConfig,
            child: _isSavingConfig
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color4,
                    ),
                  )
                : const Text('Guardar', style: TextStyle(color: color4)),
          ),
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
        return 'Frecuencia CPU';
      case 'ext_ant':
        return 'Antena Externa';
      case 'ble_tx_power':
        return 'Potencia TX BLE';
      case 'wifi_tx_power':
        return 'Potencia TX WiFi';
      default:
        return key;
    }
  }
}
