import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import '../../master.dart';

class OtaScheduleTab extends StatefulWidget {
  const OtaScheduleTab({super.key});

  @override
  OtaScheduleTabState createState() => OtaScheduleTabState();
}

class OtaScheduleTabState extends State<OtaScheduleTab> {
  TimeOfDay _startTime = const TimeOfDay(hour: 2, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);
  bool _isSending = false;

  final String _pc = DeviceManager.getProductCode(deviceName);
  final String _sn = DeviceManager.extractSerialNumber(deviceName);

  // ─────────────────────────────────────────────────────────────────────────────
  // Lógica
  // ─────────────────────────────────────────────────────────────────────────────

  /// Diferencia en minutos entre start y end (cruzando medianoche si hace falta).
  int get _durationMinutes {
    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    if (endMins > startMins) return endMins - startMins;
    return (24 * 60 - startMins) + endMins;
  }

  bool get _isRangeValid => _durationMinutes >= 60;

  bool get _crossesMidnight {
    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    return endMins <= startMins;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: color2,
              onPrimary: color4,
              surface: color0,
              onSurface: color4,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: color0,
              hourMinuteColor: color1,
              hourMinuteTextColor: color4,
              dayPeriodColor: color1,
              dayPeriodTextColor: color4,
              dialBackgroundColor: color1,
              dialHandColor: color2,
              dialTextColor: color4,
              entryModeIconColor: color3,
              helpTextStyle: const TextStyle(color: color3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: color2),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });

    // Si el rango quedó menor a 1h, avisa pero no bloquea (el botón Enviar sí bloquea)
    if (!_isRangeValid) {
      showToast('El rango mínimo es de 1 hora.');
    }
  }

  Future<void> _sendSchedule() async {
    if (!_isRangeValid) {
      showToast('El rango mínimo es de 1 hora.');
      return;
    }

    setState(() => _isSending = true);

    printLog(
      'Enviando ventana OTA: '
          '${_startTime.hour}:${_startTime.minute} – '
          '${_endTime.hour}:${_endTime.minute}',
      'cyan',
    );

    try {
      if (bluetoothManager.newGeneration) {
        final Map<String, dynamic> command = {
          'ota_window': {
            'hour_start': _startTime.hour,
            'min_start': _startTime.minute,
            'hour_end': _endTime.hour,
            'min_end': _endTime.minute,
          },
        };
        final List<int> packed = serialize(command);
        await bluetoothManager.appDataUuid.write(packed);
      } else {
        // Formato legado: PC[8](hourStart#minuteStart#hourEnd#minuteEnd)
        final String data =
            '$_pc[5](${_startTime.hour}#${_startTime.minute}#${_endTime.hour}#${_endTime.minute})';
        await bluetoothManager.toolsUuid
            .write(data.codeUnits, withoutResponse: false);
      }

      registerActivity(
        _pc,
        _sn,
        'Se configuró la ventana OTA: '
        '${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
      );

      showToast(
        'Ventana OTA configurada: ${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
      );
    } catch (e) {
      printLog('Error al enviar ventana OTA: $e', 'rojo');
      showToast('Error al enviar la configuración');
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} hs';

  String _formatDuration() {
    final total = _durationMinutes;
    final h = total ~/ 60;
    final m = total % 60;
    if (m == 0) return '$h h';
    return '$h h $m min';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // ── Card de selección de horario ───────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ventana horaria de OTA',
                    style: TextStyle(
                      color: color4,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: color1, height: 24),
                  const Text(
                    'Los equipos solo podrán descargar actualizaciones '
                    'dentro del rango horario configurado.',
                    style: TextStyle(color: color3, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // ── Pickers de hora ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(
                          label: 'Desde',
                          icon: Icons.play_arrow_rounded,
                          time: _startTime,
                          onTap: () => _pickTime(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward_rounded,
                          color: color2, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePicker(
                          label: 'Hasta',
                          icon: Icons.stop_rounded,
                          time: _endTime,
                          onTap: () => _pickTime(isStart: false),
                        ),
                      ),
                    ],
                  ),

                  // ── Advertencia de rango inválido ────────────────────────
                  if (!_isRangeValid) ...[
                    const SizedBox(height: 16),
                    _buildWarning(
                        '⚠ El rango mínimo es de 1 hora. Ajustá el horario.'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Card de resumen ────────────────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen',
                    style: TextStyle(
                      color: color4,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: color1, height: 24),
                  Center(
                    child: _ClockArc(
                      startTime: _startTime,
                      endTime: _endTime,
                      valid: _isRangeValid,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryRow(Icons.play_arrow_rounded, 'Inicio',
                      _formatTime(_startTime)),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      Icons.stop_rounded, 'Fin', _formatTime(_endTime)),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    Icons.schedule_rounded,
                    'Duración',
                    _formatDuration(),
                    valueColor: _isRangeValid ? color4 : Colors.redAccent,
                  ),
                  if (_crossesMidnight) ...[
                    const SizedBox(height: 12),
                    _buildInfoChip('La ventana cruza la medianoche.'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Botón de envío ─────────────────────────────────────────────
            _isSending
                ? const SizedBox(
                    height: 48,
                    child:
                        Center(child: CircularProgressIndicator(color: color1)),
                  )
                : buildButton(
                    text: 'Enviar configuración',
                    onPressed: _isRangeValid ? _sendSchedule : null,
                  ),

            const SizedBox(height: kBottomNavigationBarHeight + 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Sub-widgets
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color1, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTimePicker({
    required String label,
    required IconData icon,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color2.withValues(alpha: 0.4), width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color3, size: 15),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                      color: color3, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: color4,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Toca para editar',
              style: TextStyle(color: color2, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = color4,
  }) {
    return Row(
      children: [
        Icon(icon, color: color2, size: 20),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(
                color: color3, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14)),
      ],
    );
  }

  Widget _buildWarning(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: color3, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child:
                Text(text, style: const TextStyle(color: color3, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reloj de 24 h con arco de ventana OTA
// ─────────────────────────────────────────────────────────────────────────────

class _ClockArc extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool valid;

  const _ClockArc({
    required this.startTime,
    required this.endTime,
    required this.valid,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: CustomPaint(
        painter: _ClockArcPainter(
            startTime: startTime, endTime: endTime, valid: valid),
      ),
    );
  }
}

class _ClockArcPainter extends CustomPainter {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool valid;

  const _ClockArcPainter({
    required this.startTime,
    required this.endTime,
    required this.valid,
  });

  /// Convierte hora+minuto a ángulo canvas. 0:00 → arriba (−π/2).
  double _timeToAngle(TimeOfDay t) =>
      ((t.hour * 60 + t.minute) / (24 * 60)) * 2 * math.pi - math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 18;

    // Pista de fondo
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color1
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    // Arco activo
    final double startAngle = _timeToAngle(startTime);
    final double endAngle = _timeToAngle(endTime);

    final double sweepAngle = endAngle > startAngle
        ? endAngle - startAngle
        : (2 * math.pi) - (startAngle - endAngle);

    final Color arcColor = valid ? color2 : Colors.redAccent;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // Etiquetas cardinales: 0, 6, 12, 18
    final TextStyle labelStyle = TextStyle(
      color: color3,
      fontSize: size.width * 0.085,
      fontWeight: FontWeight.bold,
    );

    for (final int hour in [0, 6, 12, 18]) {
      final double angle = _timeToAngle(TimeOfDay(hour: hour, minute: 0));
      final double labelR = radius + 20;
      final double dx = center.dx + labelR * math.cos(angle);
      final double dy = center.dy + labelR * math.sin(angle);

      final TextPainter tp = TextPainter(
        text: TextSpan(text: '$hour', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(dx - tp.width / 2, dy - tp.height / 2));
    }

    // Punto central
    canvas.drawCircle(center, 5, Paint()..color = arcColor);
  }

  @override
  bool shouldRepaint(_ClockArcPainter old) =>
      old.startTime != startTime ||
      old.endTime != endTime ||
      old.valid != valid;
}
