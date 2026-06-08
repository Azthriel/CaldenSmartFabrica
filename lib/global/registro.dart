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
        final y = int.parse(fechaRaw.substring(0, 4));
        final m = int.parse(fechaRaw.substring(4, 6));
        final d = int.parse(fechaRaw.substring(6, 8));
        final fecha = DateTime(y, m, d);
        final acciones = List<String>.from(e.value);
        return Registro(fecha: fecha, legajo: legajo, acciones: acciones);
      }).toList();

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

  Future<void> _agregarNota() async {
    final notaCtrl = TextEditingController();
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: color0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.note_add, color: color3),
                  SizedBox(width: 8),
                  Text(
                    'Agregar nota manual',
                    style: TextStyle(color: color3, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo nota
                  TextField(
                    controller: notaCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: color3),
                    decoration: InputDecoration(
                      labelText: 'Nota',
                      alignLabelWithHint: true,
                      labelStyle: const TextStyle(color: color3),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: color3),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: color1),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: color3),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color1,
                    foregroundColor: color4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: guardando
                      ? null
                      : () async {
                          final nota = notaCtrl.text.trim();

                          if (nota.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Completá la nota.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => guardando = true);

                          try {
                            registerActivity(pc.trim(), _serialCtrl.text.trim(),
                                '[Nota] $nota');

                            if (ctx.mounted) Navigator.pop(ctx);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nota guardada correctamente.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setStateDialog(() => guardando = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al guardar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: guardando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color4,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(guardando ? 'Guardando...' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double bottomBarHeight = kBottomNavigationBarHeight;
    return Scaffold(
      backgroundColor: color4,
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

              if (_loading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],

              if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              ],

              const Divider(
                color: color1,
                thickness: 1.5,
                height: 32,
              ),

              // Botón agregar nota — visible solo cuando hay resultados
              if (_registros.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: _agregarNota,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color1,
                      side: const BorderSide(color: color1, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.note_add),
                    label: const Text(
                      'Agregar nota manual',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],

              // Lista de registros
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _registros.length,
                itemBuilder: (_, i) {
                  final reg = _registros[i];
                  // Detectar si alguna acción es una nota manual
                  final esNota =
                      reg.acciones.any((a) => a.startsWith('[Nota]'));
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
                      leading: esNota
                          ? const Icon(Icons.sticky_note_2, color: Colors.amber)
                          : null,
                      title: Text(
                        '${DateFormat('dd/MM/yyyy').format(reg.fecha)} - Legajo ${reg.legajo}',
                        style: const TextStyle(
                            color: color4, fontWeight: FontWeight.w600),
                      ),
                      children: reg.acciones.map((a) {
                        final isNota = a.startsWith('[Nota]');
                        return ListTile(
                          leading: Icon(
                            isNota
                                ? Icons.sticky_note_2
                                : Icons.subdirectory_arrow_right,
                            color: isNota ? Colors.amber : color4,
                          ),
                          title: Text(
                            isNota ? a.replaceFirst('[Nota] ', '') : a,
                            style: TextStyle(
                              color: color4,
                              fontStyle:
                                  isNota ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
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
