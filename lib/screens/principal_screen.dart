import 'package:flutter/material.dart';
import '../models/habito.dart';
import '../services/preferencias_service.dart';
import '../widgets/habito_tile.dart';
import 'ajustes_screen.dart';
import 'estadisticas_screen.dart';
import 'gestion_habitos_screen.dart';

// Pantalla principal: saluda, muestra el progreso del día y la lista de hábitos.
class PrincipalScreen extends StatefulWidget {
  final PreferenciasService service;
  // Estas dos funciones se las pasamos a Ajustes
  final VoidCallback onAjustesCambiados;
  final Future<void> Function() onBorrarDatos;

  const PrincipalScreen({
    super.key,
    required this.service,
    required this.onAjustesCambiados,
    required this.onBorrarDatos,
  });

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  // Es null mientras se cargan los datos; así sabemos cuándo enseñar la rueda de carga
  List<Habito>? _habitos;
  bool _ocultar = false; // ajuste de ocultar los completados

  // initState se ejecuta una vez al abrir la pantalla
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Lee los hábitos y el ajuste desde SharedPreferences
  Future<void> _cargar() async {
    final habitos = await widget.service.cargarHabitos();
    // Si la pantalla ya no existe tras esperar, no hacemos nada
    if (!mounted) return;
    setState(() {
      _habitos = habitos;
      _ocultar = widget.service.ocultarCompletados;
    });
  }

  // Marca o desmarca un hábito y lo guarda al momento
  Future<void> _alternar(Habito h) async {
    h.alternarHoy();
    // PERSISTENCIA: guardamos la lista entera con los cambios
    await widget.service.guardarHabitos(_habitos!);
    if (!mounted) return;
    setState(() {}); // redibuja la pantalla
  }

  // Abre otra pantalla y, al volver, recarga los datos por si han cambiado
  Future<void> _ir(Widget pantalla) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitosApp'),
        actions: [
          IconButton(
            tooltip: 'Gestionar hábitos',
            icon: const Icon(Icons.edit_note),
            onPressed: () => _ir(GestionHabitosScreen(service: widget.service)),
          ),
          IconButton(
            tooltip: 'Estadísticas',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => _ir(EstadisticasScreen(service: widget.service)),
          ),
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _ir(AjustesScreen(
              service: widget.service,
              onAjustesCambiados: widget.onAjustesCambiados,
              onBorrarDatos: widget.onBorrarDatos,
            )),
          ),
          const SizedBox(width: 4),
        ],
      ),
      // Si todavía no hay datos, mostramos el indicador de carga
      body: _habitos == null
          ? const Center(child: CircularProgressIndicator())
          : _contenido(_habitos!),
    );
  }

  // Tarjeta de cabecera con degradado, saludo y progreso circular
  Widget _cabecera(int hechos, int objetivo) {
    final scheme = Theme.of(context).colorScheme;
    final progreso = (hechos / objetivo).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.cyan, 0.45)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${widget.service.nombre} 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                // Progreso del día, por ejemplo "2 de 5 hábitos"
                Text(
                  '$hechos de $objetivo hábitos hoy',
                  style: TextStyle(
                    fontSize: 15,
                    color: scheme.onPrimary.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 14),
                // La barra va de 0 a 1; con clamp evitamos pasarnos de 1
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Círculo con el porcentaje
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progreso,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Text(
                  '${(progreso * 100).round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Parte de la pantalla cuando los datos ya están cargados
  Widget _contenido(List<Habito> habitos) {
    final scheme = Theme.of(context).colorScheme;
    final objetivo = widget.service.objetivoDiario;
    // Contamos cuántos hábitos están hechos hoy
    final hechos = habitos.where((h) => h.completadoHoy).length;
    // Si el ajuste está activado, quitamos de la lista los ya hechos
    final visibles =
    _ocultar ? habitos.where((h) => !h.completadoHoy).toList() : habitos;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _cabecera(hechos, objetivo),
            const SizedBox(height: 24),
            if (visibles.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Tus hábitos de hoy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),

            // Mensaje si no hay nada que mostrar
            if (visibles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      habitos.isEmpty
                          ? Icons.add_task_rounded
                          : Icons.emoji_events_rounded,
                      size: 72,
                      color: scheme.primary.withOpacity(0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      habitos.isEmpty
                          ? 'Aún no tienes hábitos. Crea uno con el icono de arriba.'
                          : '¡Todo hecho por hoy! 🎉',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // Un HabitoTile por cada hábito visible
            for (final h in visibles)
              HabitoTile(habito: h, onChanged: (_) => _alternar(h)),
          ],
        ),
      ),
    );
  }
}
