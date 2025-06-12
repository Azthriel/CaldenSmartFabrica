import 'package:caldensmartfabrica/master.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Registro {
  final DateTime fecha;
  final String legajo;
  final List<String> acciones;
  Registro({required this.fecha, required this.legajo, required this.acciones});
}

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  RegistroScreenState createState() => RegistroScreenState();
}

class RegistroScreenState extends State<RegistroScreen> {
  final _serialCtrl = TextEditingController();
  List<Registro> _registros = [];
  bool _loading = false;
  String? _error;
  List<String> productos = [];
  String pc = '';

  @override
  void initState() {
    super.initState();
    List<dynamic> lista = fbData['Productos'] ?? [];
    productos = lista.map((item) => item.toString()).toList();
  }

  Future<void> _buscar() async {
    final code = pc.trim();
    final serial = _serialCtrl.text.trim();
    if (code.isEmpty ||
        serial.isEmpty ||
        code == 'Seleccione un código' ||
        code == '') {
      setState(() {
        _error = 'Por favor, complete todos los campos.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _registros = [];
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Registro')
          .doc('$code:$serial')
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'No existe registro para ese equipo.';
          _loading = false;
        });
        return;
      }

      final data = doc.data()!;
      final lista = data.entries.map((e) {
        final partes = e.key.split(':');
        final fechaRaw = partes[0];
        final legajo = partes[1];
        // Parsear AAAAMMDD a DateTime
        final y = int.parse(fechaRaw.substring(0, 4));
        final m = int.parse(fechaRaw.substring(4, 6));
        final d = int.parse(fechaRaw.substring(6, 8));
        final fecha = DateTime(y, m, d);
        final acciones = List<String>.from(e.value);
        return Registro(fecha: fecha, legajo: legajo, acciones: acciones);
      }).toList();

      // Orden descendente por fecha
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));

      setState(() {
        _registros = lista;
        _loading = false;
      });
    } catch (err) {
      setState(() {
        _error = 'Error al leer Firestore: $err';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;
    return Scaffold(
      backgroundColor: color4,
      // Permite que el cuerpo se redimensione al aparecer el teclado
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          backgroundColor: color4,
          foregroundColor: color4,
          title: const Align(
            alignment: Alignment.center,
            child: Text(
              'Registro de equipos',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: color0,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: color4,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Ingrese el código de producto',
                    labelStyle: TextStyle(
                      color: color3,
                    ),
                    border: InputBorder.none,
                  ),
                  hint: const Text(
                    'Seleccione un código',
                    style: TextStyle(color: color3),
                  ),
                  dropdownColor: color0,
                  items:
                      productos.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: color3,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      pc = value ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(height: 6),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: color0,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: color4,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    style: const TextStyle(color: color3),
                    controller: _serialCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ingrese el número de serie',
                      labelStyle: const TextStyle(color: color3),
                      hintStyle: const TextStyle(color: color3),
                      hintText: 'Número de serie',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _serialCtrl.clear();
                            _registros.clear();
                            _error = null;
                            _loading = false;
                          });
                        },
                        icon: const Icon(
                          Icons.delete_forever,
                          color: color3,
                        ),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              buildButton(
                text: 'Buscar',
                onPressed: _loading ? null : _buscar,
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              const Divider(
                color: color1,
                thickness: 1.5,
                height: 32,
              ),

              // La lista de registros dentro del mismo scroll
              ListView.builder(
                // para que se expanda sólo al contenido y no intente ocupar todo el espacio
                shrinkWrap: true,
                // evita el scroll interno duplicado
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _registros.length,
                itemBuilder: (_, i) {
                  final reg = _registros[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: color1,
                    child: ExpansionTile(
                      iconColor: color4,
                      collapsedIconColor: color4,
                      // Título con fecha y legajo
                      title: Text(
                        '${DateFormat('dd/MM/yyyy').format(reg.fecha)} - Legajo ${reg.legajo}',
                        style: const TextStyle(
                            color: color4, fontWeight: FontWeight.w600),
                      ),
                      children: reg.acciones.map((a) {
                        return ListTile(
                          leading: const Icon(
                            Icons.subdirectory_arrow_right,
                            color: color4,
                          ),
                          title: Text(a, style: const TextStyle(color: color4)),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
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
