import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../master.dart';

class DeviceLogsViewer extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> logs;
  final String deviceName;

  const DeviceLogsViewer({
    super.key,
    required this.logs,
    required this.deviceName,
  });

  @override
  State<DeviceLogsViewer> createState() => _DeviceLogsViewerState();
}

class _DeviceLogsViewerState extends State<DeviceLogsViewer> {
  Map<String, bool> expandedSessions = {};

  @override
  void initState() {
    super.initState();
    // Inicializar todas las sesiones como expandidas por defecto
    for (var key in widget.logs.keys) {
      expandedSessions[key] = true;
    }
  }

  String _formatTimestamp(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
    } catch (e) {
      return timestamp.toString();
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return Colors.blue;
      case 'INFO':
        return Colors.green;
      case 'WARNING':
        return Colors.orange;
      case 'ERROR':
        return Colors.red;
      default:
        return color0;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
        return Icons.bug_report;
      case 'INFO':
        return Icons.info_outline;
      case 'WARNING':
        return Icons.warning_amber;
      case 'ERROR':
        return Icons.error_outline;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ordenar las sesiones por timestamp (más reciente primero)
    var sortedSessions = widget.logs.keys.toList()
      ..sort((a, b) {
        int timestampA = int.tryParse(a) ?? 0;
        int timestampB = int.tryParse(b) ?? 0;
        return timestampB.compareTo(timestampA); // Orden descendente
      });

    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color1,
        foregroundColor: color4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Logs del Equipo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.deviceName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: widget.logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: color0.withValues(alpha:0.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No hay logs disponibles',
                    style: TextStyle(
                      fontSize: 20,
                      color: color0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedSessions.length,
              itemBuilder: (context, index) {
                String sessionKey = sortedSessions[index];
                List<Map<String, dynamic>> sessionLogs =
                    widget.logs[sessionKey] ?? [];

                // Ordenar logs de la sesión por timestamp
                sessionLogs.sort((a, b) {
                  int timestampA = a['timestamp'] as int? ?? 0;
                  int timestampB = b['timestamp'] as int? ?? 0;
                  return timestampA.compareTo(timestampB);
                });

                int sessionTimestamp = int.tryParse(sessionKey) ?? 0;
                bool isExpanded = expandedSessions[sessionKey] ?? false;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            expandedSessions[sessionKey] = !isExpanded;
                          });
                        },
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color1.withValues(alpha:0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: color1,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sesión de Registro',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: color1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(sessionTimestamp),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: color0.withValues(alpha:0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color1,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${sessionLogs.length} logs',
                                  style: const TextStyle(
                                    color: color4,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: sessionLogs.length,
                            itemBuilder: (context, logIndex) {
                              var log = sessionLogs[logIndex];
                              String content = log['content'] ?? 'Sin contenido';
                              String level = log['level'] ?? 'INFO';
                              int timestamp = log['timestamp'] as int? ?? 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getLevelColor(level).withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getLevelColor(level).withValues(alpha:0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      _getLevelIcon(level),
                                      color: _getLevelColor(level),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getLevelColor(level),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  level.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: color4,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _formatTimestamp(timestamp),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: color0.withValues(alpha:0.6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            content,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: color0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
