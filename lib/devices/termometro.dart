import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/loggerble.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
import 'package:caldensmartfabrica/devices/globales/resmon.dart';
import 'package:caldensmartfabrica/devices/globales/tools.dart';
import 'package:caldensmartfabrica/master.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TermometroPage extends StatefulWidget {
  const TermometroPage({super.key});

  @override
  TermometroPageState createState() => TermometroPageState();
}

class TermometroPageState extends State<TermometroPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);
  TextEditingController tempMaxController =
      TextEditingController(text: alertMaxTemp);
  TextEditingController tempMinController =
      TextEditingController(text: alertMinTemp);
  TextEditingController offsetController = TextEditingController();
  int _selectedIndex = 0;
  bool recording = false;
  List<List<dynamic>> recordedData = [];
  Timer? recordTimer;

  // Variables para el historial de temperatura
  late TabController _historyTabController;
  Map<String, String> _historicTempData = {};

  final String pc = DeviceManager.getProductCode(deviceName);
  final String sn = DeviceManager.extractSerialNumber(deviceName);
  final bool newGen = bluetoothManager.newGeneration;

  String _actualTemp = '';
  String _tempOffset = '';
  bool _alertMaxFlag = false;
  bool _alertMinFlag = false;
  bool _tempMap = false;

  // Obtener el índice correcto para cada página
  int _getPageIndex(String pageType) {
    int index = 0;

    // Tools page (siempre presente)
    if (pageType == 'tools') return index;
    index++;

    // Params page (solo si accessLevel > 1)
    if (accessLevel > 1) {
      if (pageType == 'params') return index;
      index++;
    }

    // Control page (siempre presente)
    if (pageType == 'control') return index;
    index++;

    // History page (siempre presente)
    if (pageType == 'history') return index;
    index++;

    // Creds page (solo si accessLevel > 1)
    if (accessLevel > 1) {
      if (pageType == 'creds') return index;
      index++;
    }

    // Logger BLE page (si disponible)
    if (bluetoothManager.hasLoggerBle) {
      if (pageType == 'logger') return index;
      index++;
    }

    // Resource Monitor page (si disponible)
    if (bluetoothManager.hasResourceMonitor) {
      if (pageType == 'monitor') return index;
      index++;
    }

    // OTA page (siempre presente)
    if (pageType == 'ota') return index;

    return 0; // fallback
  }

  void _showCompleteMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: color1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Permite controlar el tamaño del BottomSheet
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.8, // Máximo 80% de la pantalla
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Menú de navegación',
                  style: TextStyle(
                    color: color4,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Tools page (siempre disponible)
                ListTile(
                  leading: const Icon(Icons.settings, color: color4),
                  title: const Text('Herramientas',
                      style: TextStyle(color: color4)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTab(_getPageIndex('tools'));
                  },
                ),
                // Params page (solo si accessLevel > 1)
                if (accessLevel > 1)
                  ListTile(
                    leading: const Icon(Icons.star, color: color4),
                    title: const Text('Parámetros',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('params'));
                    },
                  ),
                // Control page (siempre disponible)
                ListTile(
                  leading: const Icon(Icons.thermostat, color: color4),
                  title: const Text('Control', style: TextStyle(color: color4)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTab(_getPageIndex('control'));
                  },
                ),
                // History page (siempre disponible)
                ListTile(
                  leading: const Icon(Icons.show_chart, color: color4),
                  title:
                      const Text('Historial', style: TextStyle(color: color4)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTab(_getPageIndex('history'));
                  },
                ),
                // Creds page (solo si accessLevel > 1)
                if (accessLevel > 1)
                  ListTile(
                    leading: const Icon(Icons.person, color: color4),
                    title: const Text('Credenciales',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('creds'));
                    },
                  ),
                // Logger BLE page (si disponible)
                if (bluetoothManager.hasLoggerBle)
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: color4),
                    title: const Text('Logger BLE',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('logger'));
                    },
                  ),
                // Resource Monitor page (si disponible)
                if (bluetoothManager.hasResourceMonitor)
                  ListTile(
                    leading: const Icon(Icons.monitor, color: color4),
                    title: const Text('Resource Monitor',
                        style: TextStyle(color: color4)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTab(_getPageIndex('monitor'));
                    },
                  ),
                // OTA page (siempre disponible)
                ListTile(
                  leading: const Icon(Icons.send, color: color4),
                  title: const Text('OTA', style: TextStyle(color: color4)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTab(_getPageIndex('ota'));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Navegar a una pestaña específica
  void _navigateToTab(int targetIndex) {
    printLog('=== NAVIGATING TO TAB: $targetIndex ===');
    if ((targetIndex - _selectedIndex).abs() > 1) {
      _pageController.jumpToPage(targetIndex);
    } else {
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _selectedIndex = targetIndex;
    });
  }

  void processValues() {
    if (newGen) {
      setState(() {
        bluetoothManager.data.containsKey('actual_temp')
            ? _actualTemp = bluetoothManager.data['actual_temp']!
            : null;
        bluetoothManager.data.containsKey('temp_offset')
            ? _tempOffset = bluetoothManager.data['temp_offset']!
            : null;
        bluetoothManager.data.containsKey('alertMaxFlag')
            ? _alertMaxFlag = bluetoothManager.data['alertMaxFlag']! == '1'
            : null;
        bluetoothManager.data.containsKey('alertMinFlag')
            ? _alertMinFlag = bluetoothManager.data['alertMinFlag']! == '1'
            : null;
        bluetoothManager.data.containsKey('tempMap')
            ? _tempMap = bluetoothManager.data['tempMap']! == true
            : null;
      });
    } else {
      setState(() {
        _actualTemp = actualTemp;
        _tempOffset = offsetTemp;
        _alertMaxFlag = alertMaxFlag;
        _alertMinFlag = alertMinFlag;
        _tempMap = tempMap;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _historyTabController = TabController(length: 3, vsync: this);
    _historicTempData = Map.from(historicTemp); // Copia estática de los datos
    processValues();
    if (newGen) {
      subToWifiData();
      subToAppData();
      subToTempData();
    } else {
      updateWifiValues(toolsValues);
      subscribeToWifiStatus();
      subscribeToVars();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _historyTabController.dispose();
    tempMaxController.dispose();
    tempMinController.dispose();
    offsetController.dispose();
    recordTimer?.cancel();
    super.dispose();
  }

  // NEW GEN

  void subToWifiData() {
    final wifiSub =
        bluetoothManager.wifiDataUuid.onValueReceived.listen((List<int> data) {
      var map = deserialize(Uint8List.fromList(data));
      Map<String, dynamic> appMap = Map<String, dynamic>.from(map);
      printLog('Datos WiFi recibidos: $map');

      setState(() {
        bluetoothManager.data.addAll(appMap);
        if (appMap['wcs'] == true) {
          nameOfWifi = appMap['ssid'] ?? '';
          isWifiConnected = true;

          setState(() {
            textState = 'CONECTADO';
            statusColor = Colors.green;
            wifiIcon = Icons.wifi;
          });
        } else if (appMap['wcs'] == false) {
          isWifiConnected = false;

          setState(() {
            textState = 'DESCONECTADO';
            statusColor = Colors.red;
            wifiIcon = Icons.wifi_off;
          });

          if (appMap['wcs'] == false && atemp == true) {
            //If comes from subscription, parts[1] = reason of error.
            setState(() {
              wifiIcon = Icons.warning_amber_rounded;
              werror = true;
            });

            if (appMap['wifi_codes'] == 202 || appMap['wifi_codes'] == 15) {
              errorMessage = 'Contraseña incorrecta';
            } else if (appMap['wifi_codes'] == 201) {
              errorMessage = 'La red especificada no existe';
            } else if (appMap['wifi_codes'] == 1) {
              errorMessage = 'Error desconocido';
            } else {
              errorMessage = appMap['wifi_codes'].toString();
            }

            if (appMap['wifi_codes'] != null) {
              errorSintax = getWifiErrorSintax(appMap['wifi_codes']);
            }
          }
        }
      });
    });

    bluetoothManager.wifiDataUuid.setNotifyValue(true);

    bluetoothManager.device.cancelWhenDisconnected(wifiSub);
  }

  void subToAppData() {
    final appDataSub =
        bluetoothManager.appDataUuid.onValueReceived.listen((List<int> data) {
      var map = deserialize(Uint8List.fromList(data));
      Map<String, dynamic> appMap = Map<String, dynamic>.from(map);
      printLog('Datos App recibidos: $map');
      setState(() {
        bluetoothManager.data.addAll(appMap);
      });
    });

    bluetoothManager.appDataUuid.setNotifyValue(true);

    bluetoothManager.device.cancelWhenDisconnected(appDataSub);
  }

  void subToTempData() {
    final tempDataSub = bluetoothManager.temperatureUuid.onValueReceived
        .listen((List<int> data) {
      var map = deserialize(Uint8List.fromList(data));
      Map<String, dynamic> appMap = Map<String, dynamic>.from(map);
      printLog('Datos Temperatura recibidos: $map');

      setState(() {
        appMap.containsKey('actual_temp')
            ? _actualTemp = appMap['actual_temp']!
            : null;
        appMap.containsKey('temp_offset')
            ? _tempOffset = appMap['temp_offset']!
            : null;
        appMap.containsKey('alertMaxFlag')
            ? _alertMaxFlag = appMap['alertMaxFlag']! == '1'
            : null;
        appMap.containsKey('alertMinFlag')
            ? _alertMinFlag = appMap['alertMinFlag']! == '1'
            : null;
        appMap.containsKey('tempMap')
            ? _tempMap = appMap['tempMap']! == true
            : null;
      });
    });

    bluetoothManager.temperatureUuid.setNotifyValue(true);

    bluetoothManager.device.cancelWhenDisconnected(tempDataSub);
  }

  // OLD GEN

  void subscribeToVars() async {
    printLog('Me subscribo a vars');
    await bluetoothManager.varsUuid.setNotifyValue(true);

    final trueStatusSub =
        bluetoothManager.varsUuid.onValueReceived.listen((List<int> status) {
      var parts = utf8.decode(status).split(':');

      if (parts.length == 4) {
        _actualTemp = parts[0];
        _tempOffset = parts[1];
        _alertMaxFlag = parts[2] == '1';
        _alertMinFlag = parts[3] == '1';
      }
    });

    bluetoothManager.device.cancelWhenDisconnected(trueStatusSub);
  }

  void updateWifiValues(List<int> data) {
    var fun =
        utf8.decode(data); //Wifi status | wifi ssid | ble status | nickname
    fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    // printLog(fun);
    var parts = fun.split(':');
    if (parts[0] == 'WCS_CONNECTED') {
      nameOfWifi = parts[1];
      isWifiConnected = true;
      // // printLog('sis $isWifiConnected');
      setState(() {
        textState = 'CONECTADO';
        statusColor = Colors.green;
        wifiIcon = Icons.wifi;
      });
    } else if (parts[0] == 'WCS_DISCONNECTED') {
      isWifiConnected = false;
      // // printLog('non $isWifiConnected');

      setState(() {
        textState = 'DESCONECTADO';
        statusColor = Colors.red;
        wifiIcon = Icons.wifi_off;
      });

      if (parts[0] == 'WCS_DISCONNECTED' && atemp == true) {
        //If comes from subscription, parts[1] = reason of error.
        setState(() {
          wifiIcon = Icons.warning_amber_rounded;
          werror = true;
        });

        if (parts[1] == '202' || parts[1] == '15') {
          errorMessage = 'Contraseña incorrecta';
        } else if (parts[1] == '201') {
          errorMessage = 'La red especificada no existe';
        } else if (parts[1] == '1') {
          errorMessage = 'Error desconocido';
        } else {
          errorMessage = parts[1];
        }

        if (int.tryParse(parts[1]) != null) {
          errorSintax = getWifiErrorSintax(int.parse(parts[1]));
        }
      }
    }

    setState(() {});
  }

  void subscribeToWifiStatus() async {
    printLog('Se subscribio a wifi');
    await bluetoothManager.toolsUuid.setNotifyValue(true);

    final wifiSub =
        bluetoothManager.toolsUuid.onValueReceived.listen((List<int> status) {
      updateWifiValues(status);
    });

    bluetoothManager.device.cancelWhenDisconnected(wifiSub);
  }

  // BOTH GEN

  void saveDataToCsv() async {
    List<List<dynamic>> rows = [
      [
        "Timestamp",
        "Temperatura",
        "Offset",
      ]
    ];
    rows.addAll(recordedData);

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFileToWrite = '${directory.path}/temp_data.csv';
    File file = File(pathOfTheFileToWrite);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)],
        text: 'CSV TEMPERATURA (Termómetro)');
  }

  // Funciones para procesar datos históricos
  List<FlSpot> _getHistoricDataPoints(String period) {
    List<FlSpot> spots = [];
    DateTime now = DateTime.now();

    // Convertir el mapa a una lista de pares fecha-temperatura
    List<MapEntry<DateTime, double>> dataPoints = [];

    _historicTempData.forEach((timestamp, temp) {
      try {
        // Parse como UTC y convertir a hora de Buenos Aires (UTC-3)
        DateTime dtUtc =
            DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp, true);
        DateTime dtLocal = dtUtc.subtract(const Duration(hours: 3));
        double temperature = double.parse(temp);
        dataPoints.add(MapEntry(dtLocal, temperature));
      } catch (e) {
        printLog('Error parsing data: $e');
      }
    });

    // Ordenar por fecha
    dataPoints.sort((a, b) => a.key.compareTo(b.key));

    // Filtrar según el período
    DateTime cutoffDate;
    switch (period) {
      case 'daily':
        cutoffDate = now.subtract(const Duration(hours: 24));
        break;
      case 'weekly':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      default:
        cutoffDate = now.subtract(const Duration(hours: 24));
    }

    List<MapEntry<DateTime, double>> filteredData =
        dataPoints.where((entry) => entry.key.isAfter(cutoffDate)).toList();

    // Para vista diaria: mostrar todos los datos
    if (period == 'daily') {
      for (int i = 0; i < filteredData.length; i++) {
        spots.add(FlSpot(i.toDouble(), filteredData[i].value));
      }
    } else {
      // Para semanal y mensual: calcular promedios por día
      Map<String, List<double>> dailyTemps = {};

      for (var entry in filteredData) {
        String dayKey = DateFormat('yyyy-MM-dd').format(entry.key);
        if (!dailyTemps.containsKey(dayKey)) {
          dailyTemps[dayKey] = [];
        }
        dailyTemps[dayKey]!.add(entry.value);
      }

      // Ordenar las fechas y calcular promedios
      List<String> sortedDays = dailyTemps.keys.toList()..sort();

      for (int i = 0; i < sortedDays.length; i++) {
        List<double> temps = dailyTemps[sortedDays[i]]!;
        double avgTemp = temps.reduce((a, b) => a + b) / temps.length;
        spots.add(FlSpot(i.toDouble(), avgTemp));
      }
    }

    return spots;
  }

  String _getBottomTitle(int index, String period) {
    List<MapEntry<DateTime, double>> dataPoints = [];
    DateTime now = DateTime.now();

    _historicTempData.forEach((timestamp, temp) {
      try {
        // Parse como UTC y convertir a hora de Buenos Aires (UTC-3)
        DateTime dtUtc =
            DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp, true);
        DateTime dtLocal = dtUtc.subtract(const Duration(hours: 3));
        double temperature = double.parse(temp);
        dataPoints.add(MapEntry(dtLocal, temperature));
      } catch (e) {
        printLog('Error parsing data: $e');
      }
    });

    dataPoints.sort((a, b) => a.key.compareTo(b.key));

    DateTime cutoffDate;
    switch (period) {
      case 'daily':
        cutoffDate = now.subtract(const Duration(hours: 24));
        break;
      case 'weekly':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      default:
        cutoffDate = now.subtract(const Duration(hours: 24));
    }

    List<MapEntry<DateTime, double>> filteredData =
        dataPoints.where((entry) => entry.key.isAfter(cutoffDate)).toList();

    // Para vista diaria: usar los datos directamente
    if (period == 'daily') {
      if (index >= filteredData.length) return '';
      DateTime date = filteredData[index].key;
      return DateFormat('HH:mm').format(date);
    } else {
      // Para semanal y mensual: obtener las fechas agrupadas por día
      Map<String, List<double>> dailyTemps = {};

      for (var entry in filteredData) {
        String dayKey = DateFormat('yyyy-MM-dd').format(entry.key);
        if (!dailyTemps.containsKey(dayKey)) {
          dailyTemps[dayKey] = [];
        }
        dailyTemps[dayKey]!.add(entry.value);
      }

      List<String> sortedDays = dailyTemps.keys.toList()..sort();

      if (index >= sortedDays.length) return '';

      DateTime date = DateFormat('yyyy-MM-dd').parse(sortedDays[index]);
      return DateFormat('dd/MM').format(date);
    }
  }

  Widget _buildHistoricChart(String period) {
    List<FlSpot> spots = _getHistoricDataPoints(period);

    if (spots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 80,
              color: color0.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay datos históricos disponibles',
              style: TextStyle(
                color: color0,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: Text(
              'Historial de Temperatura',
              style: TextStyle(
                color: color0,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color1.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
                    verticalInterval: spots.length > 10
                        ? (spots.length / 6).ceilToDouble()
                        : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: color1.withValues(alpha: 0.15),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: color1.withValues(alpha: 0.15),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: spots.length > 10
                            ? (spots.length / 6).ceilToDouble()
                            : 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= spots.length) {
                            return const Text('');
                          }
                          String label = _getBottomTitle(value.toInt(), period);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Transform.rotate(
                              angle: period == 'daily' ? 0 : -0.5,
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: color1,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${value.toInt()}°',
                              style: const TextStyle(
                                color: color1,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                        reservedSize: 44,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: color1.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: -55,
                  maxY: 125,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6A11CB),
                          Color(0xFF2575FC),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: const Color(0xFF2575FC),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6A11CB).withValues(alpha: 0.3),
                            const Color(0xFF2575FC).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => color1,
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          return LineTooltipItem(
                            '${barSpot.y.toStringAsFixed(1)}°C',
                            const TextStyle(
                              color: color4,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? response) {},
                    handleBuiltInTouches: true,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: color1, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    period == 'daily'
                        ? 'Lecturas cada 30 minutos'
                        : 'Promedio diario de temperaturas',
                    style: const TextStyle(
                      color: color1,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color1,
            boxShadow: [
              BoxShadow(
                color: color1.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _historyTabController,
            labelColor: color4,
            unselectedLabelColor: color4.withValues(alpha: 0.5),
            indicatorColor: color4,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.today, size: 20),
                text: 'Diaria',
              ),
              Tab(
                icon: Icon(Icons.calendar_view_week, size: 20),
                text: 'Semanal',
              ),
              Tab(
                icon: Icon(Icons.calendar_month, size: 20),
                text: 'Mensual',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _historyTabController,
            children: [
              _buildHistoricChart('daily'),
              _buildHistoricChart('weekly'),
              _buildHistoricChart('monthly'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;

    final List<Widget> pages = [
      //*- Página 1 TOOLS -*\\
      const ToolsPage(),
      if (accessLevel > 1) ...[
        //*- Página 2 PARAMS -*\\
        const ParamsTab(),
      ],

      //*- Página 3 CONTROL -*\\
      Scaffold(
        backgroundColor: color4,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                buildText(text: 'Temperatura Actual:\n$_actualTemp °C'),
                const SizedBox(height: 20),
                buildText(text: 'Temperatura ambiente:\n$_tempOffset °C'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      recording = !recording;
                    });
                    if (!recording) {
                      recordTimer?.cancel();
                      saveDataToCsv();
                      recordedData.clear();
                    } else {
                      recordTimer = Timer.periodic(
                        const Duration(seconds: 1),
                        (Timer t) {
                          if (recording) {
                            recordedData.add(
                                [DateTime.now(), _actualTemp, _tempOffset]);
                          }
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: color0,
                  ),
                  child: Icon(
                    recording ? Icons.pause : Icons.play_arrow,
                    size: 35,
                    color: color4,
                  ),
                ),
                const SizedBox(height: 20),
                buildTextField(
                  label: 'Temperatura ambiente',
                  controller: offsetController,
                  keyboard: TextInputType.number,
                  suffixIcon: IconButton(
                    onPressed: () {
                      String p0 = offsetController.text.trim();
                      setState(() {
                        _tempOffset = p0;
                      });
                      if (newGen) {
                        final map = {
                          "temp_offset": int.parse(p0),
                        };
                        List<int> messagePackData = serialize(map);
                        bluetoothManager.temperatureUuid.write(messagePackData);
                      } else {
                        String data = '$pc[9]($p0)';
                        printLog('Enviando: $data');
                        bluetoothManager.toolsUuid.write(data.codeUnits);
                      }
                      showToast(
                        'Temperatura ambiente enviada: $p0 °C',
                      );
                    },
                    icon: const Icon(
                      Icons.send,
                      color: color4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                buildText(
                    text:
                        'Alerta Temperatura Máxima:\n${_alertMaxFlag ? 'SI' : 'NO'}'),
                const SizedBox(height: 10),
                buildTextField(
                  label: 'Temperatura Máxima de alerta',
                  controller: tempMaxController,
                  keyboard: TextInputType.number,
                  suffixIcon: IconButton(
                      onPressed: () {
                        String p0 = tempMaxController.text.trim();
                        if (newGen) {
                          final map = {
                            "alert_max_temp": int.parse(p0),
                          };
                          List<int> messagePackData = serialize(map);
                          bluetoothManager.temperatureUuid
                              .write(messagePackData);
                        } else {
                          String data = '$pc[7]($p0)';
                          printLog('Enviando: $data');
                          bluetoothManager.toolsUuid.write(data.codeUnits);
                        }
                        showToast(
                          'Temperatura máxima de alerta enviada: $p0 °C',
                        );
                      },
                      icon: const Icon(
                        Icons.send,
                        color: color4,
                      )),
                ),
                const SizedBox(height: 10),
                buildText(
                    text:
                        'Alerta Temperatura Mínima:\n${_alertMinFlag ? 'SI' : 'NO'}'),
                const SizedBox(height: 10),
                buildTextField(
                  label: 'Temperatura Mínima de alerta',
                  controller: tempMinController,
                  keyboard: TextInputType.number,
                  suffixIcon: IconButton(
                      onPressed: () {
                        String p0 = tempMinController.text.trim();
                        if (newGen) {
                          final map = {
                            "alert_min_temp": int.parse(p0),
                          };
                          List<int> messagePackData = serialize(map);
                          bluetoothManager.temperatureUuid
                              .write(messagePackData);
                        } else {
                          String data = '$pc[8]($p0)';
                          printLog('Enviando: $data');
                          bluetoothManager.toolsUuid.write(data.codeUnits);
                        }
                        showToast(
                          'Temperatura mínima de alerta enviada: $p0 °C',
                        );
                      },
                      icon: const Icon(
                        Icons.send,
                        color: color4,
                      )),
                ),
                const SizedBox(height: 20),
                buildText(
                  text: '',
                  textSpans: [
                    const TextSpan(
                      text: 'Mapeo de temperatura:\n',
                      style:
                          TextStyle(color: color4, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: _tempMap ? 'REALIZADO' : 'NO REALIZADO',
                      style: TextStyle(
                          color: _tempMap ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  fontSize: 20.0,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                buildButton(
                  text: 'Iniciar mapeo temperatura',
                  onPressed: () {
                    registerActivity(pc, sn,
                        'Se inicio el mapeo de temperatura en el equipo');
                    if (newGen) {
                      final map = {
                        "init_temp_map": true,
                      };
                      List<int> messagePackData = serialize(map);
                      bluetoothManager.temperatureUuid.write(messagePackData);
                    } else {
                      String data = '$pc[10](0)';
                      bluetoothManager.toolsUuid.write(data.codeUnits);
                    }
                    showToast('Iniciando mapeo de temperatura');
                  },
                ),
                const SizedBox(height: 5),
                buildButton(
                  text: 'Borrar mapeo temperatura',
                  onPressed: () {
                    registerActivity(
                      pc,
                      sn,
                      'Se borro el mapeo de temperatura en el equipo',
                    );
                    if (newGen) {
                      final map = {
                        "clear_temp_map": true,
                      };
                      List<int> messagePackData = serialize(map);
                      bluetoothManager.temperatureUuid.write(messagePackData);
                    } else {
                      String data = '$pc[10](1)';
                      bluetoothManager.toolsUuid.write(data.codeUnits);
                    }
                    showToast('Borrando mapeo de temperatura');
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.only(bottom: bottomBarHeight + 20),
                ),
              ],
            ),
          ),
        ),
      ),

      //*- Página HISTORIAL -*\\
      Scaffold(
        backgroundColor: color4,
        body: _buildHistoryTab(),
      ),

      if (accessLevel > 1) ...[
        //*- Página 4 CREDENTIAL -*\\
        const CredsTab(),
      ],

      if (bluetoothManager.hasLoggerBle) ...[
        //*- Página LOGGER -*\\
        const LoggerBlePage(),
      ],

      if (bluetoothManager.hasResourceMonitor) ...[
        //*- Página RESOURCE MONITOR -*\\
        const ResourceMonitorPage(),
      ],

      //*- Página 5 OTA -*\\
      const OtaTab(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, A) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: color1,
              content: Row(
                children: [
                  Image.asset(
                      EasterEggs.legajosMeme.contains(legajoConectado)
                          ? 'assets/eg/DSC.gif'
                          : 'assets/Loading.gif',
                      width: 100,
                      height: 100),
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    child: const Text(
                      "Desconectando...",
                      style: TextStyle(color: color4),
                    ),
                  ),
                ],
              ),
            );
          },
        );
        Future.delayed(const Duration(seconds: 2), () async {
          await bluetoothManager.device.disconnect();
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/menu');
          }
        });
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: color1,
          title: Text(
            deviceName,
            style: const TextStyle(
              color: color4,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
            ),
            color: color4,
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: color1,
                    content: Row(
                      children: [
                        Image.asset(
                            EasterEggs.legajosMeme.contains(legajoConectado)
                                ? 'assets/eg/DSC.gif'
                                : 'assets/Loading.gif',
                            width: 100,
                            height: 100),
                        Container(
                          margin: const EdgeInsets.only(left: 15),
                          child: const Text(
                            "Desconectando...",
                            style: TextStyle(
                              color: color4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
              Future.delayed(const Duration(seconds: 2), () async {
                await bluetoothManager.device.disconnect();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/menu');
                }
              });
              return;
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                wifiIcon,
                color: color4,
              ),
              onPressed: () {
                wifiText(context);
              },
            ),
          ],
        ),
        backgroundColor: color4,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: pages,
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: _showCompleteMenu,
                backgroundColor: color2,
                child: const Icon(Icons.menu, color: color4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
