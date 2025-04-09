import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController snController = TextEditingController();
  final TextEditingController comController = TextEditingController();
  final TextEditingController pcController = TextEditingController();
  String serialNumber = '';
  String productCode = '';
  bool stateSell = false;
  bool isRegister = false;
  List<String> productos = [];

  void updateGoogleSheet() async {
    printLog('mande alguito');

    setState(() {
      isRegister = true;
    });

    String status = stateSell ? 'Si' : 'No';
    const String url =
        'https://script.google.com/macros/s/AKfycbyJw-peLVNGfSwb9vi9YWTbYysBR4oc2_Bz8cReB1oMOLrRrE4kK9lIb0hhRzriAHWs/exec';

    final Map<String, String> queryParams = {
      'productCode': productCode,
      'serialNumber': serialNumber,
      'status': status,
      'legajo': legajoConectado,
      'comment': comController.text,
    };

    final uri = Uri.parse(url).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      printLog('Si llego');
      comController.clear();
      isRegister = false;
      showToast('Equipo cargado');
      snController.clear();
      pcController.clear();
      setState(() {});
    } else {
      printLog('Unu');
    }
  }

  @override
  void initState() {
    super.initState();
    List<dynamic> lista = fbData['Productos'] ?? [];
    productos = lista.map((item) => item.toString()).toList();
  }

  @override
  void dispose() {
    snController.dispose();
    comController.dispose();
    pcController.dispose();
    super.dispose();
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: color4,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          backgroundColor: color4,
          foregroundColor: color4,
          title: const Align(
            alignment: Alignment.center,
            child: Text(
              'Registro de productos',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: color0,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color3.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.code, color: color4),
                    labelText: 'Código de producto',
                    labelStyle: const TextStyle(color: color3),
                    hintText: 'Seleccione un código',
                    hintStyle: TextStyle(color: color4.withValues(alpha: 0.7)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  dropdownColor: color0,
                  style: const TextStyle(color: color4),
                  items:
                      productos.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: color4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      productCode = value!;
                    });
                  },
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: color0,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color3.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: snController,
                onChanged: (value) {
                  setState(() {
                    serialNumber = value;
                  });
                },
                style: const TextStyle(color: color4),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.confirmation_number, color: color4),
                  border: InputBorder.none,
                  labelText: 'Número de serie',
                  labelStyle: const TextStyle(color: color3),
                  hintStyle: TextStyle(color: color3.withValues(alpha: 0.7)),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 24.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: color0,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color3.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.shopping_cart, color: color4),
                  const SizedBox(width: 8),
                  const Text(
                    '¿Listo para la venta?',
                    style: TextStyle(
                      color: color3,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    activeColor: color3,
                    activeTrackColor: color3.withValues(alpha: 0.3),
                    inactiveThumbColor: color4,
                    inactiveTrackColor: color3.withValues(alpha: 0.2),
                    value: stateSell,
                    onChanged: (value) {
                      setState(() {
                        stateSell = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 24.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: color0,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color3.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: comController,
                style: const TextStyle(color: color4),
                keyboardType: TextInputType.text,
                maxLines: 3,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.comment, color: color4),
                  border: InputBorder.none,
                  labelText: 'Comentario (opcional)',
                  labelStyle: const TextStyle(color: color3),
                  hintStyle: TextStyle(color: color3.withValues(alpha: 0.7)),
                ),
              ),
            ),
            isRegister
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color1,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          String accion =
                              'Se marcó el equipo como ${stateSell ? 'listo para la venta' : 'no listo para la venta'}';
                          registerActivity(productCode, serialNumber, accion);
                          updateGoogleSheet();
                        },
                        child: const Text(
                          'Subir',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color4,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
