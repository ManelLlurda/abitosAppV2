import 'package:flutter/material.dart';
import '../services/preferencias_service.dart';

// Pantalla de ajustes: tema, tamaño de letra, ocultar completados y borrar datos.
class AjustesScreen extends StatefulWidget {
  final PreferenciasService service;
  // Avisa a main.dart de que cambió un ajuste para que redibuje la app
  final VoidCallback onAjustesCambiados;
  // Pide a main.dart que borre todo y vuelva a la bienvenida
  final Future<void> Function() onBorrarDatos;

  const AjustesScreen({
    super.key,
    required this.service,
    required this.onAjustesCambiados,
    required this.onBorrarDatos,
  });

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  late bool _oscuro;
  late bool _ocultar;
  late double _tamano;

  @override
  void initState() {
    super.initState();
    // Partimos de los valores guardados
    _oscuro = widget.service.temaOscuro;
    _ocultar = widget.service.ocultarCompletados;
    _tamano = widget.service.tamanoLetra;
  }

  // Pide confirmación y, si el usuario acepta, borra todos los datos
  Future<void> _confirmarBorrado() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            size: 40, color: Theme.of(context).colorScheme.error),
        title: const Text('Borrar todos los datos'),
        content: const Text(
          'Se eliminarán hábitos, estadísticas y ajustes. '
              'La app quedará como recién instalada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 44),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (ok != true) return; // si cancela, no hacemos nada

    // main.dart borra las preferencias y vuelve a cargar (saldrá la bienvenida)
    await widget.onBorrarDatos();
    if (!mounted) return;
    // Cerramos esta pantalla y volvemos a la primera de la pila
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // Tarjeta redondeada que agrupa varios ajustes
  Widget _tarjeta(List<Widget> hijos) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(children: hijos),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Apariencia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              _tarjeta([
                // Interruptor del tema claro/oscuro
                SwitchListTile(
                  secondary: Icon(_oscuro
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded),
                  title: const Text('Tema oscuro'),
                  value: _oscuro,
                  onChanged: (v) async {
                    setState(() => _oscuro = v);
                    // PERSISTENCIA: guardamos el bool
                    await widget.service.guardarTemaOscuro(v);
                    widget.onAjustesCambiados(); // main.dart cambia el tema
                  },
                ),
                const Divider(height: 1),
                // Control deslizante del tamaño de letra
                ListTile(
                  leading: const Icon(Icons.text_fields_rounded),
                  title: Text('Tamaño de letra: ${_tamano.round()}'),
                  subtitle: Slider(
                    min: 12,
                    max: 24,
                    divisions: 12,
                    value: _tamano,
                    label: _tamano.round().toString(),
                    // Mientras se arrastra solo actualizamos el número en pantalla
                    onChanged: (v) => setState(() => _tamano = v),
                    // Al soltar guardamos el double (así no escribimos en cada movimiento)
                    onChangeEnd: (v) async {
                      await widget.service.guardarTamanoLetra(v);
                      widget.onAjustesCambiados();
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Hábitos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              _tarjeta([
                // Interruptor para ocultar los hábitos ya hechos hoy
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Ocultar hábitos completados hoy'),
                  value: _ocultar,
                  onChanged: (v) async {
                    setState(() => _ocultar = v);
                    await widget.service.guardarOcultarCompletados(v);
                    widget.onAjustesCambiados();
                  },
                ),
              ]),
              const SizedBox(height: 32),
              // Botón rojo para borrar todo
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Borrar datos'),
                onPressed: _confirmarBorrado,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
