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
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../master.dart';

class PatitoPage extends StatefulWidget {
  const PatitoPage({super.key});

  @override
  PatitoPageState createState() => PatitoPageState();
}

class PatitoPageState extends State<PatitoPage> {
  TextEditingController textController = TextEditingController();
  final PageController _pageController = PageController(initialPage: 0);
  int _selectedIndex = 0;

  List<double> aceleracionX = List<double>.filled(1000, 0.0, growable: true);
  List<double> aceleracionY = List<double>.filled(1000, 0.0, growable: true);
  List<double> aceleracionZ = List<double>.filled(1000, 0.0, growable: true);
  List<double> giroX = List<double>.filled(1000, 0.0, growable: true);
  List<double> giroY = List<double>.filled(1000, 0.0, growable: true);
  List<double> giroZ = List<double>.filled(1000, 0.0, growable: true);
  List<double> sumaAcc = List<double>.filled(1000, 0.0, growable: true);
  List<double> sumaGiro = List<double>.filled(1000, 0.0, growable: true);
  List<double> promAcc = List<double>.filled(1000, 0.0, growable: true);
  List<double> promGiro = List<double>.filled(1000, 0.0, growable: true);
  List<DateTime> dates =
      List<DateTime>.filled(1000, DateTime.now(), growable: true);
  bool recording = false;
  List<List<dynamic>> recordedData = [];

  void _onItemTapped(int index) {
    if ((index - _selectedIndex).abs() > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
    subToPatito();
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
      printLog('sis $isWifiConnected');
      setState(() {
        textState = 'CONECTADO';
        statusColor = Colors.green;
        wifiIcon = Icons.wifi;
      });
    } else if (parts[0] == 'WCS_DISCONNECTED') {
      isWifiConnected = false;
      printLog('non $isWifiConnected');

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

  void subToPatito() {
    bluetoothManager.patitoUuid.setNotifyValue(true);
    final patitoSub =
        bluetoothManager.patitoUuid.onValueReceived.listen((event) {
      if (context.mounted) {
        setState(() {
          addData(aceleracionX, transformToDouble(event.sublist(0, 4)),
              windowSize: 5);
          addData(aceleracionY, transformToDouble(event.sublist(4, 8)),
              windowSize: 5);
          addData(aceleracionZ, transformToDouble(event.sublist(8, 12)),
              windowSize: 5);
          addData(giroX, transformToDouble(event.sublist(12, 16)),
              windowSize: 5);
          addData(giroY, transformToDouble(event.sublist(16, 20)),
              windowSize: 5);
          addData(giroZ, transformToDouble(event.sublist(20)), windowSize: 5);
          addDate(dates, DateTime.now());

          addData(sumaAcc,
              (aceleracionX.last + aceleracionY.last + aceleracionZ.last));
          addData(promAcc,
              (aceleracionX.last + aceleracionY.last + aceleracionZ.last) / 3);
          addData(sumaGiro, (giroX.last + giroY.last + giroZ.last));
          addData(promGiro, (giroX.last + giroY.last + giroZ.last) / 3);
        });
      }
      if (recording) {
        recordedData.add([
          DateTime.now(),
          transformToDouble(event.sublist(0, 4)),
          transformToDouble(event.sublist(4, 8)),
          transformToDouble(event.sublist(8, 12)),
          transformToDouble(event.sublist(12, 16)),
          transformToDouble(event.sublist(16, 20)),
          transformToDouble(event.sublist(20)),
          (transformToDouble(event.sublist(0, 4)) +
              transformToDouble(event.sublist(4, 8)) +
              transformToDouble(event.sublist(8, 12))),
          ((transformToDouble(event.sublist(0, 4)) +
                  transformToDouble(event.sublist(4, 8)) +
                  transformToDouble(event.sublist(8, 12))) /
              3),
          (transformToDouble(event.sublist(12, 16)) +
              transformToDouble(event.sublist(16, 20)) +
              transformToDouble(event.sublist(20))),
          ((transformToDouble(event.sublist(12, 16)) +
                  transformToDouble(event.sublist(16, 20)) +
                  transformToDouble(event.sublist(20))) /
              3)
        ]);
      }
    });
    bluetoothManager.device.cancelWhenDisconnected(patitoSub);
  }

  void addData(List<double> list, double value, {int windowSize = 5}) {
    if (list.length >= 1000) {
      list.removeAt(0);
    }
    list.add(value);
    if (list.length > windowSize) {
      list[list.length - 1] = movingAverage(list, windowSize);
    }
  }

  void addDate(List<DateTime> list, DateTime date) {
    if (list.length >= 1000) {
      list.removeAt(0);
    }
    list.add(date);
  }

  double transformToDouble(List<int> data) {
    ByteData byteData = ByteData(4);
    for (int i = 0; i < data.length; i++) {
      byteData.setInt8(i, data[i]);
    }

    double value =
        double.parse(byteData.getFloat32(0, Endian.little).toStringAsFixed(4));

    if (value < -15.0) {
      return -15.0;
    } else if (value > 15.0) {
      return 15.0;
    } else {
      return value;
    }
  }

  void saveDataToCsv() async {
    List<List<dynamic>> rows = [
      [
        "Timestamp",
        "AccX",
        "AccY",
        "AccZ",
        "GiroX",
        "GiroY",
        "GiroZ",
        "SumaAcc",
        "PromAcc",
        "SumaGiro",
        "PromGiro"
      ]
    ];
    rows.addAll(recordedData);

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFileToWrite = '${directory.path}/recorded_data.csv';
    File file = File(pathOfTheFileToWrite);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'CSV PATITO');
  }

  double movingAverage(List<double> data, int windowSize) {
    int n = data.length;
    if (n < windowSize) return data.last;
    double sum = 0.0;
    for (int i = n - windowSize; i < n; i++) {
      sum += data[i];
    }
    return sum / windowSize;
  }

  //! VISUAL
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
        body: SafeArea(
          child: Column(
            children: [
              // Header con botón de grabación
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: color1,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: recording
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: recording ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            recording = !recording;
                          });
                          if (!recording) {
                            saveDataToCsv();
                            recordedData.clear();
                          }
                        },
                        icon: recording
                            ? const Icon(
                                Icons.pause,
                                size: 30,
                                color: Colors.red,
                              )
                            : const Icon(
                                Icons.play_arrow,
                                size: 30,
                                color: Colors.green,
                              ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recording ? 'Grabando...' : 'Presiona para grabar',
                      style: TextStyle(
                        fontSize: 12,
                        color: color4.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de gráficos
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: [
                    const SizedBox(height: 10),
                    createChart('Aceleración X', dates, aceleracionX),
                    createChart('Giro X', dates, giroX),
                    createChart('Aceleración Y', dates, aceleracionY),
                    createChart('Giro Y', dates, giroY),
                    createChart('Aceleración Z', dates, aceleracionZ),
                    createChart('Giro Z', dates, giroZ),
                    createChart('Suma Aceleración', dates, sumaAcc),
                    createChart('Promedio Aceleración', dates, promAcc),
                    createChart('Suma Giro', dates, sumaGiro),
                    createChart('Promedio Giro', dates, promGiro),
                    SizedBox(height: bottomBarHeight + 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      if (accessLevel > 1) ...[
        //*- Página 4 CREDENTIAL -*\\
        const CredsTab(),
      ],

      if (hasLoggerBle) ...[
        //*- Página LOGGER -*\\
        const LoggerBlePage(),
      ],

      if (hasResourceMonitor) ...[
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                deviceName,
                style: const TextStyle(color: color4),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
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
          ),
          actions: [
            IconButton(
              icon: Icon(wifiIcon, color: color4),
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
              left: 0,
              right: 0,
              bottom: 0,
              child: CurvedNavigationBar(
                index: _selectedIndex,
                height: 75.0,
                items: <Widget>[
                  const Icon(Icons.settings, size: 30, color: color4),
                  if (accessLevel > 1) ...[
                    const Icon(Icons.star, size: 30, color: color4),
                  ],
                  const Icon(Icons.list, size: 30, color: color4),
                  if (accessLevel > 1) ...[
                    const Icon(Icons.person, size: 30, color: color4),
                  ],
                  if (hasLoggerBle) ...[
                    const Icon(Icons.receipt_long, size: 30, color: color4),
                  ],
                  if (hasResourceMonitor) ...[
                    const Icon(Icons.monitor, size: 30, color: color4),
                  ],
                  const Icon(Icons.send, size: 30, color: color4),
                ],
                color: color1,
                buttonBackgroundColor: color1,
                backgroundColor: Colors.transparent,
                animationCurve: Curves.easeInOut,
                animationDuration: const Duration(milliseconds: 600),
                onTap: (index) {
                  _onItemTapped(index);
                },
                letIndexChange: (index) => true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget createChart(String title, List<DateTime> dates, List<double> values) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color1,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF522B5B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color4,
                  ),
                ),
              ),
              // Indicador del valor actual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF522B5B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  values.isNotEmpty ? values.last.toStringAsFixed(2) : '0.00',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LineChart(
                  LineChartData(
                    minY: -30.0,
                    maxY: 30.0,
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.round().toString(),
                                style: TextStyle(
                                  color: color4.withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      drawHorizontalLine: true,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFF522B5B),
                        spots: values
                            .asMap()
                            .entries
                            .map(
                              (e) => FlSpot(e.key.toDouble(), e.value),
                            )
                            .toList(),
                        barWidth: 2.5,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF522B5B).withValues(alpha: 0.3),
                              const Color(0xFF522B5B).withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        dotData: FlDotData(
                          show: values.isNotEmpty,
                          checkToShowDot: (spot, barData) {
                            return spot.x == values.length - 1;
                          },
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF522B5B),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
