import 'package:flutter/material.dart';
// intl es un paquete para trabajar con fechas, números e idiomas.
// Aquí solo usamos DateFormat para enseñar la fecha de la última apertura
// de forma legible (dd/MM/yyyy HH:mm) en vez del texto ISO que guardamos.
import 'package:intl/intl.dart';
import '../models/habito.dart';
import '../services/preferencias_service.dart';

// Pantalla de estadísticas: aperturas de la app y datos de cada hábito.
class EstadisticasScreen extends StatefulWidget {
  final PreferenciasService service;

  const EstadisticasScreen({super.key, required this.service});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  List<Habito>? _habitos; // null mientras carga

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Lee los hábitos guardados en SharedPreferences
  Future<void> _cargar() async {
    final h = await widget.service.cargarHabitos();
    if (!mounted) return;
    setState(() => _habitos = h);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: _habitos == null
          ? const Center(child: CircularProgressIndicator())
          : _contenido(_habitos!),
    );
  }

  // Tarjeta pequeña con icono, valor y etiqueta
  Widget _datoApp(
      {required IconData icono,
        required String valor,
        required String etiqueta,
        required Color color}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _contenido(List<Habito> habitos) {
    final scheme = Theme.of(context).colorScheme;
    // La última apertura puede ser null si nunca se guardó
    final ultima = widget.service.ultimaApertura;
    final textoUltima =
    ultima == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(ultima);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Dos tarjetas con los datos generales de la app
            Row(
              children: [
                Expanded(
                  child: _datoApp(
                    icono: Icons.login_rounded,
                    valor: '${widget.service.numAperturas}',
                    etiqueta: 'Aperturas de la app',
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datoApp(
                    icono: Icons.schedule_rounded,
                    valor: textoUltima,
                    etiqueta: 'Última apertura',
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Por hábito',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            if (habitos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.insights_rounded,
                        size: 64, color: scheme.primary.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'Todavía no hay hábitos.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            // Una tarjeta por hábito con su racha y su total
            for (final h in habitos)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border(
                    left: BorderSide(color: Color(h.color), width: 6),
                    top: BorderSide(color: scheme.outlineVariant),
                    right: BorderSide(color: scheme.outlineVariant),
                    bottom: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.nombre,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.deepOrange, size: 20),
                        const SizedBox(width: 6),
                        Text('Racha actual: ${h.rachaActual} días'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.task_alt_rounded,
                            color: scheme.primary, size: 20),
                        const SizedBox(width: 6),
                        Text('Total completados: ${h.totalCompletados} días'),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
