import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:path_provider/path_provider.dart';

import '../../master.dart';

/// ──────────────────────────────────────────────────────────────
/// Config del repo de firmwares
/// ──────────────────────────────────────────────────────────────
const String _kOtaRepo = 'barberop/sime-domotica';
const String _kOtaBranch = 'main';

/// Representa un archivo .bin encontrado en GitHub.
/// Se guarda el [name] tal cual vino del repo para no recomponerlo nunca a mano.
class FirmwareFile {
  final String name; // hv2.0sv3.4.bin
  final String hv;
  final String sv;

  const FirmwareFile({
    required this.name,
    required this.hv,
    required this.sv,
  });

  String get label => 'HV $hv  ·  SV $sv';
}

class OtaTab extends StatefulWidget {
  const OtaTab({super.key});
  @override
  OtaTabState createState() => OtaTabState();
}

class OtaTabState extends State<OtaTab> {
  var progressValue = 0.0;
  TextEditingController otaSVController = TextEditingController();
  TextEditingController otaHVController = TextEditingController();
  TextEditingController otaPCController = TextEditingController();
  bool _isAuto = true;
  bool _factory = false;
  final pc = DeviceManager.getProductCode(deviceName);
  final sn = DeviceManager.extractSerialNumber(deviceName);

  // ─────────── Estado de la OTA manual asistida ───────────
  /// false = asistida (dropdowns) | true = 100% manual (lápiz)
  bool _manualEdit = false;

  bool _loadingPCs = false;
  bool _loadingVersions = false;

  List<String> _productCodes = [];
  String? _selectedPC;

  List<FirmwareFile> _versions = [];
  FirmwareFile? _selectedVersion;

  /// Cache por 'productCode/W' o 'productCode/F' para no quemar
  /// el rate limit de la API de GitHub (60 req/hora sin token).
  final Map<String, List<FirmwareFile>> _versionCache = {};

  @override
  void dispose() {
    otaSVController.dispose();
    otaHVController.dispose();
    otaPCController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (bluetoothManager.newGeneration) {
      subToProgressNewGen();
    } else {
      subToProgress();
    }
  }

  void subToProgressNewGen() {
    final otaWifiSub =
        bluetoothManager.otaWifiUuid.onValueReceived.listen((List<int> data) {
      try {
        Map<String, dynamic> otaWifiData =
            deserialize(Uint8List.fromList(data));
        if (otaWifiData.containsKey('ota_progress')) {
          setState(() {
            progressValue = double.tryParse(otaWifiData['ota_progress']) ?? 0.0;
          });
          printLog('Progreso OTA Wifi: ${otaWifiData['ota_progress']}');
        }

        if (otaWifiData.containsKey('ota_response')) {
          showToast('Respuesta OTA Wifi: ${otaWifiData['ota_response']}');
        }
      } catch (e) {
        printLog('Error malevolo: $e');
        showToast('Error al actualizar progreso OTA Wifi');
      }
    });
    final otaBleSub =
        bluetoothManager.otaBleUuid.onValueReceived.listen((List<int> data) {
      try {
        Map<String, dynamic> otaBleData = deserialize(Uint8List.fromList(data));
        if (otaBleData.containsKey('ota_progress')) {
          setState(() {
            progressValue = double.tryParse(otaBleData['ota_progress']) ?? 0.0;
          });
          printLog('Progreso OTA BLE: ${otaBleData['ota_progress']}');
        }
        if (otaBleData.containsKey('ota_response')) {
          showToast('Respuesta OTA BLE: ${otaBleData['ota_response']}');
        }
      } catch (e) {
        printLog('Error malevolo: $e');
        showToast('Error al actualizar progreso OTA BLE');
      }
    });

    bluetoothManager.otaWifiUuid.setNotifyValue(true);
    bluetoothManager.otaBleUuid.setNotifyValue(true);

    bluetoothManager.device.cancelWhenDisconnected(otaWifiSub);
    bluetoothManager.device.cancelWhenDisconnected(otaBleSub);
  }

  void subToProgress() async {
    await bluetoothManager.otaUuid.setNotifyValue(true);

    final otaSub =
        bluetoothManager.otaUuid.onValueReceived.listen((List<int> event) {
      try {
        var fun = utf8.decode(event);
        fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
        printLog(fun);
        var parts = fun.split(':');
        if (parts[0] == 'OTAPR') {
          printLog('Se recibio');
          setState(() {
            progressValue = int.parse(parts[1]) / 100;
          });
          printLog('Progreso: ${parts[1]}');
        } else if (fun.contains('OTA:HTTP_CODE')) {
          RegExp exp = RegExp(r'\(([^)]+)\)');
          final Iterable<RegExpMatch> matches = exp.allMatches(fun);

          for (final RegExpMatch match in matches) {
            String valorEntreParentesis = match.group(1)!;
            showToast('HTTP CODE recibido: $valorEntreParentesis');
          }
        } else {
          switch (fun) {
            case 'OTA:START':
              showToast('Iniciando actualización');
              break;
            case 'OTA:SUCCESS':
              printLog('Estreptococo');
              navigatorKey.currentState?.pushReplacementNamed('/menu');
              showToast("OTA completada exitosamente");
              break;
            case 'OTA:FAIL':
              showToast("Fallo al enviar OTA");
              break;
            case 'OTA:OVERSIZE':
              showToast("El archivo es mayor al espacio reservado");
              break;
            case 'OTA:WIFI_LOST':
              showToast("Se perdió la conexión wifi");
              break;
            case 'OTA:HTTP_LOST':
              showToast("Se perdió la conexión HTTP durante la actualización");
              break;
            case 'OTA:STREAM_LOST':
              showToast("Excepción de stream durante la actualización");
              break;
            case 'OTA:NO_WIFI':
              showToast("Dispositivo no conectado a una red Wifi");
              break;
            case 'OTA:HTTP_FAIL':
              showToast("No se pudo iniciar una peticion HTTP");
              break;
            case 'OTA:NO_ROLLBACK':
              showToast("Imposible realizar un rollback");
              break;
            default:
              break;
          }
        }
      } catch (e, stackTrace) {
        printLog('Error malevolo: $e $stackTrace');
      }
    });
    bluetoothManager.device.cancelWhenDisconnected(otaSub);
  }

  /// ──────────────────────────────────────────────────────────────
  /// Consulta a GitHub
  /// ──────────────────────────────────────────────────────────────

  Map<String, String> get _ghHeaders => const {
        'Accept': 'application/vnd.github+json',
      };

  /// Lista las carpetas del root del repo que son códigos de producto.
  Future<void> _loadProductCodes({bool force = false}) async {
    if (_loadingPCs) return;
    if (_productCodes.isNotEmpty && !force) return;

    setState(() => _loadingPCs = true);
    try {
      final res = await http.get(
        Uri.parse(
            'https://api.github.com/repos/$_kOtaRepo/contents?ref=$_kOtaBranch'),
        headers: _ghHeaders,
      );

      if (res.statusCode == 403) {
        throw Exception('Rate limit de GitHub alcanzado, esperá un rato');
      }
      if (res.statusCode != 200) {
        throw Exception('GitHub respondió ${res.statusCode}');
      }

      final List<dynamic> data = jsonDecode(res.body);
      final codes = data
          .where((e) =>
              e['type'] == 'dir' &&
              (e['name'] as String).toUpperCase().endsWith('_IOT'))
          .map<String>((e) => e['name'] as String)
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _productCodes = codes;
        // Si el equipo conectado está en la lista, lo dejo preseleccionado.
        _selectedPC ??= codes.contains(pc) ? pc : null;
      });
      printLog('Códigos de producto encontrados: ${codes.length}');
    } catch (e) {
      printLog('Error al listar códigos de producto: $e');
      showToast('No se pudieron obtener los códigos de producto');
    } finally {
      if (mounted) setState(() => _loadingPCs = false);
    }
  }

  /// Lista los .bin de OTA_FW/W o OTA_FW/F para el código seleccionado.
  Future<void> _loadVersions() async {
    final code = _selectedPC;
    if (code == null) {
      showToast('Elegí un código de producto primero');
      return;
    }
    if (_loadingVersions) return;

    final branch = _factory ? 'F' : 'W';
    final key = '$code/$branch';

    setState(() {
      _loadingVersions = true;
      _versions = [];
      _selectedVersion = null;
    });

    try {
      List<FirmwareFile> files;

      if (_versionCache.containsKey(key)) {
        files = _versionCache[key]!;
        printLog('Versiones de $key traídas del cache');
      } else {
        final res = await http.get(
          Uri.parse('https://api.github.com/repos/$_kOtaRepo/contents/'
              '$code/OTA_FW/$branch?ref=$_kOtaBranch'),
          headers: _ghHeaders,
        );

        if (res.statusCode == 404) {
          throw Exception('No existe OTA_FW/$branch para $code');
        }
        if (res.statusCode == 403) {
          throw Exception('Rate limit de GitHub alcanzado, esperá un rato');
        }
        if (res.statusCode != 200) {
          throw Exception('GitHub respondió ${res.statusCode}');
        }

        final List<dynamic> data = jsonDecode(res.body);
        final exp = RegExp(r'^hv(.+?)sv(.+)\.bin$', caseSensitive: false);

        files = [];
        for (final e in data) {
          if (e['type'] != 'file') continue;
          final name = e['name'] as String;
          final m = exp.firstMatch(name);
          if (m == null) continue;
          files.add(FirmwareFile(
            name: name,
            hv: m.group(1)!,
            sv: m.group(2)!,
          ));
        }

        // Más nuevo primero: por HV desc y después SV desc.
        files.sort((a, b) {
          final c = _cmpVersion(b.hv, a.hv);
          return c != 0 ? c : _cmpVersion(b.sv, a.sv);
        });

        _versionCache[key] = files;
      }

      if (!mounted) return;

      if (files.isEmpty) {
        showToast('No se encontraron firmwares en $code/OTA_FW/$branch');
      }

      // Preselecciono la versión que matchea el HV del equipo conectado.
      FirmwareFile? pre;
      if (files.isNotEmpty) {
        pre = files.firstWhere(
          (f) => f.hv == hardwareVersion,
          orElse: () => files.first,
        );
      }

      setState(() {
        _versions = files;
        _selectedVersion = pre;
      });
    } catch (e) {
      printLog('Error al listar versiones: $e');
      showToast('$e');
    } finally {
      if (mounted) setState(() => _loadingVersions = false);
    }
  }

  /// Compara versiones tipo "2.10" contra "2.9" numéricamente.
  /// Ignora sufijos no numéricos (ej: el _F de factory).
  int _cmpVersion(String a, String b) {
    final pa = a.replaceAll(RegExp(r'[^0-9.]'), '').split('.');
    final pb = b.replaceAll(RegExp(r'[^0-9.]'), '').split('.');
    final len = max(pa.length, pb.length);
    for (int i = 0; i < len; i++) {
      final va = i < pa.length ? (int.tryParse(pa[i]) ?? 0) : 0;
      final vb = i < pb.length ? (int.tryParse(pb[i]) ?? 0) : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }

  /// ──────────────────────────────────────────────────────────────
  /// Envío de OTA
  /// ──────────────────────────────────────────────────────────────

  /// Único lugar donde se decide wifi vs BLE y se manda el firmware.
  Future<void> _dispatchOta(String url) async {
    printLog('URL del firmware: $url');
    try {
      if (isWifiConnected) {
        printLog('Si mandé ota Wifi');
        if (bluetoothManager.newGeneration) {
          Map<String, dynamic> command = {
            "ota_url": url,
          };
          List<int> messagePackData = serialize(command);
          await bluetoothManager.otaWifiUuid.write(messagePackData);
          return;
        } else {
          String data = '$pc[2]($url)';
          await bluetoothManager.toolsUuid.write(data.codeUnits);
        }
      } else {
        printLog('Arranca por la derecha la OTA BLE');
        String dir = (await getApplicationDocumentsDirectory()).path;
        File file = File('$dir/firmware.bin');

        if (await file.exists()) {
          await file.delete();
        }

        var req = await http.get(Uri.parse(url));

        var bytes = req.bodyBytes;

        await file.writeAsBytes(bytes);

        var firmware = await file.readAsBytes();

        if (bluetoothManager.newGeneration) {
          Map<String, dynamic> command = {
            "ota_size": bytes.length,
          };
          List<int> messagePackData = serialize(command);
          await bluetoothManager.otaBleUuid.write(messagePackData);
        } else {
          String data = '$pc[3](${bytes.length})';
          printLog(data);
          await bluetoothManager.toolsUuid.write(data.codeUnits);
        }

        printLog("Arranco OTA");
        try {
          int chunk = 255 - 3;
          for (int i = 0; i < firmware.length; i += chunk) {
            List<int> subvalue = firmware.sublist(
              i,
              min(i + chunk, firmware.length),
            );
            if (bluetoothManager.newGeneration) {
              Map<String, dynamic> command = {
                "ota_chunk": subvalue,
              };
              List<int> messagePackData = serialize(command);
              await bluetoothManager.otaBleUuid.write(messagePackData);
            } else {
              await bluetoothManager.infoUuid
                  .write(subvalue, withoutResponse: false);
            }
          }
          printLog('Acabe');
        } catch (e, stackTrace) {
          printLog('El error es: $e $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      printLog('Error al enviar la OTA $e $stackTrace');
    }
  }

  void sendAutoOTA({
    required bool factory,
  }) async {
    final fileName =
        await Versioner.fetchLatestFirmwareFile(pc, hardwareVersion, factory);
    String url = Versioner.buildFirmwareUrl(pc, fileName, factory);

    registerActivity(pc, sn, 'Envié OTA automatica con el file: $fileName');

    await _dispatchOta(url);
  }

  /// OTA manual asistida: el archivo salió del listado real de GitHub,
  /// así que se usa el nombre tal cual, sin recomponerlo.
  void sendSelectedOTA() async {
    final code = _selectedPC;
    final file = _selectedVersion;

    if (code == null || file == null) {
      showToast('Elegí código de producto y versión');
      return;
    }

    final branch = _factory ? 'F' : 'W';
    String url = 'https://raw.githubusercontent.com/$_kOtaRepo/$_kOtaBranch/'
        '$code/OTA_FW/$branch/${file.name}';

    registerActivity(
        pc, sn, 'Envié OTA manual $code con el file: ${file.name}');

    await _dispatchOta(url);
  }

  /// OTA 100% manual (modo lápiz), tal cual estaba antes.
  void sendManualOTA({
    required String productCode,
    required String hardwareVersion,
    required String softwareVersion,
    required bool factory,
  }) async {
    if (productCode.isEmpty ||
        hardwareVersion.isEmpty ||
        softwareVersion.isEmpty) {
      showToast('Por favor, completa todos los campos');
      return;
    }

    if (factory && !softwareVersion.contains('_F')) {
      softwareVersion = '${softwareVersion}_F';
    }

    final fileName = 'hv${hardwareVersion}sv$softwareVersion.bin';

    String url = 'https://raw.githubusercontent.com/$_kOtaRepo/$_kOtaBranch/'
        '$productCode/OTA_FW/${factory ? 'F' : 'W'}/$fileName';

    registerActivity(
        pc, sn, 'Envié OTA manual $productCode con el file: $fileName');

    await _dispatchOta(url);
  }

  /// ──────────────────────────────────────────────────────────────
  /// UI
  /// ──────────────────────────────────────────────────────────────

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: color0,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: color1),
            overflow: TextOverflow.ellipsis,
          ),
          dropdownColor: color0,
          iconEnabledColor: color1,
          iconDisabledColor: color1,
          style: const TextStyle(color: color1),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAssistedManual() {
    return Column(
      children: [
        // ─── Dropdown de códigos de producto ───
        if (_loadingPCs)
          const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: color1),
              ),
            ),
          )
        else if (_productCodes.isEmpty)
          buildButton(
            text: 'Reintentar códigos de producto',
            onPressed: () => _loadProductCodes(force: true),
          )
        else
          _buildDropdown<String>(
            hint: 'Código de Producto',
            value: _selectedPC,
            items: _productCodes
                .map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c == pc ? '$c  (Conectado)' : c,
                        style: const TextStyle(
                          color: color4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedPC = v;
              _versions = [];
              _selectedVersion = null;
            }),
          ),

        const SizedBox(height: 16),

        // ─── Work / Factory ───
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Work'),
              selected: !_factory,
              onSelected: (sel) => setState(() {
                _factory = false;
                _versions = [];
                _selectedVersion = null;
              }),
              selectedColor: color1,
              backgroundColor: color0,
              labelStyle: TextStyle(color: !_factory ? color4 : color1),
              checkmarkColor: color4,
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Factory'),
              selected: _factory,
              onSelected: (sel) => setState(() {
                _factory = true;
                _versions = [];
                _selectedVersion = null;
              }),
              selectedColor: color1,
              backgroundColor: color0,
              labelStyle: TextStyle(color: _factory ? color4 : color1),
              checkmarkColor: color4,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ─── Buscar versiones ───
        if (_loadingVersions)
          const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: color1),
              ),
            ),
          )
        else
          buildButton(
            text: 'Buscar versiones',
            onPressed: _loadVersions,
          ),

        // ─── Dropdown de versiones ───
        if (_versions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDropdown<FirmwareFile>(
            hint: 'Versión',
            value: _selectedVersion,
            items: _versions
                .map((f) => DropdownMenuItem<FirmwareFile>(
                      value: f,
                      child: Text(
                        f.hv == hardwareVersion ? '✓  ${f.label}' : f.label,
                        style: const TextStyle(
                          color: color4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedVersion = v),
          ),
          if (_selectedVersion != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 300,
              child: Text(
                _selectedVersion!.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: color0,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 16),
          buildButton(
            text: 'Iniciar OTA',
            onPressed: sendSelectedOTA,
          ),
        ],
      ],
    );
  }

  Widget _buildFullManual() {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                final text = otaPCController.text;
                if (text.isNotEmpty && !text.endsWith('_IOT')) {
                  otaPCController.text = '${text}_IOT';
                  otaPCController.selection = TextSelection.collapsed(
                    offset: otaPCController.text.length,
                  );
                  printLog('Appended _IOT to productCode', 'magenta');
                }
              }
            },
            child: buildTextField(
                label: 'Código de Producto',
                onSubmitted: (_) {},
                controller: otaPCController,
                keyboard: TextInputType.number),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 100,
          child: buildTextField(
              label: 'Versión de Hardware',
              onSubmitted: (_) {},
              controller: otaHVController),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 100,
          child: buildTextField(
              label: 'Versión de Software',
              onSubmitted: (_) {},
              controller: otaSVController),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Work'),
              selected: !_factory,
              onSelected: (sel) => setState(() => _factory = false),
              selectedColor: color1,
              backgroundColor: color0,
              labelStyle: TextStyle(color: !_factory ? color4 : color1),
              checkmarkColor: color4,
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Factory'),
              selected: _factory,
              onSelected: (sel) => setState(() => _factory = true),
              selectedColor: color1,
              backgroundColor: color0,
              labelStyle: TextStyle(color: _factory ? color4 : color1),
              checkmarkColor: color4,
            ),
          ],
        ),
        const SizedBox(height: 12),
        buildButton(
          text: 'Enviar OTA',
          onPressed: () => sendManualOTA(
            productCode: otaPCController.text.trim(),
            hardwareVersion: otaHVController.text.trim(),
            softwareVersion: otaSVController.text.trim(),
            factory: _factory,
          ),
        ),
      ],
    );
  }

  /// Al pasar al modo lápiz precargo lo que ya venía elegido.
  void _toggleManualEdit() {
    setState(() {
      _manualEdit = !_manualEdit;
      if (_manualEdit) {
        if (_selectedPC != null && otaPCController.text.trim().isEmpty) {
          otaPCController.text = _selectedPC!;
        }
        if (_selectedVersion != null) {
          if (otaHVController.text.trim().isEmpty) {
            otaHVController.text = _selectedVersion!.hv;
          }
          if (otaSVController.text.trim().isEmpty) {
            otaSVController.text = _selectedVersion!.sv;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: color4,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─────────── ChoiceChips Auto / Manual ───────────
              if (accessLevel > 2) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Auto'),
                      selected: _isAuto,
                      onSelected: (sel) => setState(() => _isAuto = true),
                      selectedColor: color1,
                      backgroundColor: color0,
                      labelStyle: TextStyle(color: _isAuto ? color4 : color1),
                      checkmarkColor: color4,
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Manual'),
                      selected: !_isAuto,
                      onSelected: (sel) {
                        setState(() => _isAuto = false);
                        if (!_manualEdit) _loadProductCodes();
                      },
                      selectedColor: color1,
                      backgroundColor: color0,
                      labelStyle: TextStyle(color: !_isAuto ? color4 : color1),
                      checkmarkColor: color4,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              // ─────────── Barra de progreso OTA ───────────
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 40,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: color0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: Colors.transparent,
                        color: color1,
                      ),
                    ),
                  ),
                  Text(
                    'Progreso descarga OTA: ${(progressValue * 100).toInt()}%',
                    style: const TextStyle(
                      color: color4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ─────────── UI Condicional según isAuto ───────────
              if (_isAuto) ...[
                buildButton(
                    text: 'Enviar OTA Work',
                    onPressed: () => sendAutoOTA(factory: false)),
                const SizedBox(height: 12),
                buildButton(
                    text: 'Enviar OTA Factory',
                    onPressed: () => sendAutoOTA(factory: true)),
              ] else ...[
                // ─── Header con toggle asistido / lápiz ───
                SizedBox(
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _manualEdit ? 'Manual total' : 'Asistido por GitHub',
                        style: const TextStyle(
                          color: color0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        tooltip: _manualEdit
                            ? 'Volver al modo asistido'
                            : 'Escribir todo a mano',
                        icon: Icon(
                          _manualEdit ? Icons.list_alt : Icons.edit,
                          color: color0,
                        ),
                        onPressed: _toggleManualEdit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_manualEdit) _buildFullManual() else _buildAssistedManual(),
              ],
              const SizedBox(height: 20),
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
