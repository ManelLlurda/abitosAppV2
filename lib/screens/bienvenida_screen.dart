import 'package:flutter/material.dart';
import '../services/preferencias_service.dart';

// Pantalla de bienvenida: solo sale la primera vez.
// Es StatefulWidget porque el texto de error cambia mientras el usuario escribe.
class BienvenidaScreen extends StatefulWidget {
  // El servicio lo recibimos de main.dart para guardar los datos
  final PreferenciasService service;
  // Función que main.dart nos pasa para avisarle de que ya hemos terminado
  final Future<void> Function() onTerminar;

  const BienvenidaScreen({
    super.key,
    required this.service,
    required this.onTerminar,
  });

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  // Los controllers sirven para leer lo que el usuario escribe en cada campo
  final _nombreCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController(text: '5'); // 5 por defecto

  // Si es null no hay error; si tiene texto, se muestra en rojo
  String? _error;

  // Se ejecuta al pulsar el botón "Empezar"
  Future<void> _empezar() async {
    final nombre = _nombreCtrl.text.trim(); // trim quita espacios sobrantes
    // tryParse devuelve null si el texto no es un número válido
    final objetivo = int.tryParse(_objetivoCtrl.text.trim());

    // Validamos: nombre no vacío y objetivo número mayor que 0
    if (nombre.isEmpty || objetivo == null || objetivo < 1) {
      setState(() => _error = 'Escribe tu nombre y un objetivo mayor que 0');
      return; // paramos aquí, no guardamos nada
    }

    // PERSISTENCIA: guardamos nombre, objetivo y marcamos que ya vimos la bienvenida
    await widget.service.guardarBienvenida(nombre, objetivo);
    // Avisamos a main.dart para que cambie a la pantalla principal
    await widget.onTerminar();
  }

  // Liberamos los controllers cuando la pantalla se destruye
  @override
  void dispose() {
    _nombreCtrl.dispose();
    _objetivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          // ConstrainedBox: en pantallas anchas (web) el formulario no se estira
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            // SingleChildScrollView evita errores cuando sale el teclado
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo con degradado
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary,
                          Color.lerp(scheme.primary, Colors.cyan, 0.5)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 64, color: scheme.onPrimary),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '¡Bienvenido a HabitosApp!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pequeños hábitos, grandes cambios.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  // Campo del nombre
                  TextField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Tu nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo del objetivo, solo acepta teclado numérico
                  TextField(
                    controller: _objetivoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Objetivo diario de hábitos',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),

                  // Si hay error, lo mostramos en rojo
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 28),

                  ElevatedButton.icon(
                    onPressed: _empezar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    ),
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: const Text('Empezar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
