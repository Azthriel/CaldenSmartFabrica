import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:caldensmartfabrica/devices/globales/credentials.dart';
import 'package:caldensmartfabrica/devices/globales/ota.dart';
import 'package:caldensmartfabrica/devices/globales/params.dart';
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
    printLog(fun);
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
    await myDevice.toolsUuid.setNotifyValue(true);

    final wifiSub =
        myDevice.toolsUuid.onValueReceived.listen((List<int> status) {
      updateWifiValues(status);
    });

    myDevice.device.cancelWhenDisconnected(wifiSub);
  }

  void subToPatito() {
    myDevice.patitoUuid.setNotifyValue(true);
    final patitoSub = myDevice.patitoUuid.onValueReceived.listen((event) {
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
    myDevice.device.cancelWhenDisconnected(patitoSub);
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
      if (accessLevel > 1) ...[
        //*- Página 1 TOOLS -*\\
        const ToolsPage(),

        //*- Página 2 PARAMS -*\\
        const ParamsTab(),
      ],

      //*- Página 3 CONTROL -*\\
      Scaffold(
        backgroundColor: color0,
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
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
                        size: 35,
                        color: color4,
                      )
                    : const Icon(
                        Icons.play_arrow,
                        size: 35,
                        color: color4,
                      ),
              ),
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
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.only(bottom: bottomBarHeight + 20),
              ),
            ],
          ),
        ),
      ),

      if (accessLevel > 1) ...[
        //*- Página 4 CREDENTIAL -*\\
        const CredsTab(),
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
                  Image.asset(EasterEggs.legajosMeme.contains(legajoConectado)
                          ? 'assets/eg/DSC.gif'
                          : 'assets/Loading.gif', width: 100, height: 100),
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
          await myDevice.device.disconnect();
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
                        Image.asset(EasterEggs.legajosMeme.contains(legajoConectado)
                          ? 'assets/eg/DSC.gif'
                          : 'assets/Loading.gif',
                            width: 100, height: 100),
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
                await myDevice.device.disconnect();
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
                  if (accessLevel > 1) ...[
                    const Icon(Icons.settings, size: 30, color: color4),
                    const Icon(Icons.star, size: 30, color: color4),
                  ],
                  const Icon(Icons.list, size: 30, color: color4),
                  if (accessLevel > 1) ...[
                    const Icon(Icons.person, size: 30, color: color4),
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
    double width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color4,
            ),
          ),
          SizedBox(
            height: 200,
            width: width - 20,
            child: LineChart(
              LineChartData(
                minY: -15.0,
                maxY: 15.0,
                borderData: FlBorderData(
                  border: const Border(
                    top: BorderSide(
                      color: color1,
                    ),
                    bottom: BorderSide(
                      color: color1,
                    ),
                    right: BorderSide(
                      color: color1,
                    ),
                    left: BorderSide(
                      color: color1,
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0.0 || value == 15.0 || value == -15.0) {
                          return Text(
                            value.round().toString(),
                            style: const TextStyle(
                              color: color4,
                              fontSize: 10,
                            ),
                          );
                        } else {
                          return const Text('');
                        }
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < dates.length) {
                          return Text(
                            '${dates[index].second}',
                            style: const TextStyle(
                              color: color4,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(
                  show: false,
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF522B5B),
                    spots: values
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(e.key.toDouble(), e.value),
                        )
                        .toList(),
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFFFFFF),
                    ),
                    aboveBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFFFFFF),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
