import 'dart:convert';
import 'package:caldensmartfabrica/aws/dynamo/dynamo.dart';
import 'package:caldensmartfabrica/master.dart';
import 'package:caldensmartfabrica/secret.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ClimaPage extends StatefulWidget {
  const ClimaPage({super.key});

  @override
  ClimaPageState createState() => ClimaPageState();
}

class ClimaPageState extends State<ClimaPage> {
  final TextEditingController serialNumberController = TextEditingController();
  String productCode = '';
  List<String> productos = [];
  Map<String, dynamic>? weatherData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    List<dynamic> lista = fbData['Productos'] ?? [];
    productos = lista.map((item) => item.toString()).toList();
  }

  // Función para extraer latitud y longitud del string
  Map<String, double>? extractCoordinates(String locationString) {
    try {
      // Formato esperado: "Latitude: -34.6233784, Longitude: -58.5565867"
      final latMatch =
          RegExp(r'Latitude:\s*([-+]?\d+\.?\d*)').firstMatch(locationString);
      final lonMatch =
          RegExp(r'Longitude:\s*([-+]?\d+\.?\d*)').firstMatch(locationString);

      if (latMatch != null && lonMatch != null) {
        final lat = double.parse(latMatch.group(1)!);
        final lon = double.parse(lonMatch.group(1)!);
        return {'lat': lat, 'lon': lon};
      }
      return null;
    } catch (e) {
      printLog('Error extrayendo coordenadas: $e');
      return null;
    }
  }

  // Función para convertir timestamp Unix a hora legible
  String formatUnixTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Función para hacer la request a OpenWeather API
  Future<void> fetchWeatherData(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&appid=$climaAPI&units=metric&lang=es');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        printLog('=== RESPUESTA DE LA API DE CLIMA ===', 'verde');
        printLog(data, 'verde');
        printLog('===================================', 'verde');

        setState(() {
          weatherData = data;
        });
      } else {
        printLog('Error en la API: ${response.statusCode}', 'rojo');
        printLog('Respuesta: ${response.body}', 'rojo');
      }
    } catch (e) {
      printLog('Error haciendo request a la API: $e', 'rojo');
    }
  }

  void loadEquipmentData() async {
    if (productCode.isNotEmpty && serialNumberController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
        weatherData = null;
      });

      registerActivity(productCode, serialNumberController.text.trim(),
          'Se consulto el clima del equipo.');

      await queryItems(productCode, serialNumberController.text.trim());

      // Extraer latitud y longitud de deviceLocation
      if (deviceLocation.isNotEmpty && deviceLocation != 'unknown') {
        final coordinates = extractCoordinates(deviceLocation);

        if (coordinates != null) {
          printLog(
              'Coordenadas extraídas: Lat: ${coordinates['lat']}, Lon: ${coordinates['lon']}');

          // Hacer la request a la API de clima
          await fetchWeatherData(coordinates['lat']!, coordinates['lon']!);
        } else {
          printLog(
              'No se pudieron extraer las coordenadas de: $deviceLocation');
          showToast('No se pudieron extraer las coordenadas del equipo');
        }
      } else {
        printLog('deviceLocation no disponible o desconocida');
      }

      setState(() {
        isLoading = false;
      });
    }
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
              'Clima del Equipo',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dropdown para seleccionar producto
              Container(
                decoration: BoxDecoration(
                  color: color1,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: color1,
                  value: productCode.isEmpty ? null : productCode,
                  hint: const Text(
                    'Selecciona un producto',
                    style: TextStyle(color: color3),
                  ),
                  style: const TextStyle(color: color4),
                  underline: Container(),
                  items: productos.map((String product) {
                    return DropdownMenuItem<String>(
                      value: product,
                      child: Text(product),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      productCode = newValue ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // TextField para el número de serie
              TextField(
                controller: serialNumberController,
                style: const TextStyle(color: color4),
                decoration: InputDecoration(
                  hintText: 'Número de serie',
                  hintStyle: const TextStyle(color: color3),
                  filled: true,
                  fillColor: color1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        serialNumberController.clear();
                        weatherData = null;
                      });
                    },
                    icon: const Icon(
                      Icons.delete_forever,
                      color: color3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Botón para cargar datos
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loadEquipmentData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color1,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: color4)
                      : const Text(
                          'Cargar Datos',
                          style: TextStyle(color: color4, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Mostrar datos del clima
              if (weatherData != null) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Clima Actual',
                    style: TextStyle(
                      color: color1,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildWeatherItem('Amanecer',
                    formatUnixTime(weatherData!['current']['sunrise'])),
                _buildWeatherItem('Anochecer',
                    formatUnixTime(weatherData!['current']['sunset'])),
                const SizedBox(height: 8),
                _buildWeatherItem(
                    'Temperatura', '${weatherData!['current']['temp']}°C'),
                _buildWeatherItem('Sensación térmica',
                    '${weatherData!['current']['feels_like']}°C'),
                _buildWeatherItem(
                    'Humedad', '${weatherData!['current']['humidity']}%'),
                _buildWeatherItem(
                    'Presión', '${weatherData!['current']['pressure']} hPa'),
                _buildWeatherItem('Punto de rocío',
                    '${weatherData!['current']['dew_point']}°C'),
                _buildWeatherItem(
                    'Índice UV', '${weatherData!['current']['uvi']}'),
                _buildWeatherItem(
                    'Nubosidad', '${weatherData!['current']['clouds']}%'),
                _buildWeatherItem('Visibilidad',
                    '${weatherData!['current']['visibility']} m'),
                _buildWeatherItem('Velocidad del viento',
                    '${weatherData!['current']['wind_speed']} m/s'),
                _buildWeatherItem(
                    'Tipo de viento',
                    weatherData!['current']['wind_speed'] > 10
                        ? 'Viento fuerte'
                        : weatherData!['current']['wind_speed'] > 5
                            ? 'Viento moderado'
                            : weatherData!['current']['wind_speed'] > 1
                                ? 'Viento suave'
                                : 'Sin viento'),
                _buildWeatherItem('Dirección del viento',
                    '${weatherData!['current']['wind_deg']}°'),
                if (weatherData!['current']['weather'] != null &&
                    weatherData!['current']['weather'].isNotEmpty) ...[
                  _buildWeatherItem('Condición',
                      '${weatherData!['current']['weather'][0]['description']}'),
                  _buildWeatherItem('Tipo principal',
                      '${weatherData!['current']['weather'][0]['main']}'),
                ],
              ] else ...[
                Center(
                  child: Text(
                    isLoading
                        ? 'Cargando...'
                        : 'Selecciona un equipo para ver el clima',
                    style: const TextStyle(color: color1, fontSize: 16),
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

  Widget _buildWeatherItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: color1,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: const TextStyle(
                color: color1,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
