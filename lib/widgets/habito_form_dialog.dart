import 'package:flutter/material.dart';

import '../models/habito.dart';
import '../models/usuario.dart';

// Colores entre los que se puede elegir (guardados como int, igual que en el modelo)
const List<int> paletaColores = [
  0xFFE53935, // rojo
  0xFFFFB300, // naranja
  0xFFFDD835, // amarillo
  0xFF43A047, // verde
  0xFF1E88E5, // azul
  0xFF8E24AA, // morado
  0xFF00ACC1, // turquesa
  0xFF6D4C41, // marrón
];

// Función para abrir el formulario desde otras pantallas.
// Devuelve el hábito creado/editado, o null si se cancela.
//  - [usuarioIdPorDefecto]: dueño del hábito si se crea uno nuevo.
//  - [usuarios]: SOLO lo pasa el administrador. Si viene, el formulario deja
//    elegir el propietario y editar las fechas completadas.
Future<Habito?> mostrarFormularioHabito(
  BuildContext context, {
  Habito? existente,
  required int usuarioIdPorDefecto,
  List<Usuario>? usuarios,
}) {
  return showDialog<Habito>(
    context: context,
    builder: (_) => HabitoFormDialog(
      existente: existente,
      usuarioIdPorDefecto: usuarioIdPorDefecto,
      usuarios: usuarios,
    ),
  );
}

// Formulario para crear o editar un hábito.
// Si "existente" es null estamos creando; si no, estamos editando.
class HabitoFormDialog extends StatefulWidget {
  final Habito? existente;
  final int usuarioIdPorDefecto;
  final List<Usuario>? usuarios;

  const HabitoFormDialog({
    super.key,
    this.existente,
    required this.usuarioIdPorDefecto,
    this.usuarios,
  });

  @override
  State<HabitoFormDialog> createState() => _HabitoFormDialogState();
}

class _HabitoFormDialogState extends State<HabitoFormDialog> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _fechasCtrl;
  late int _color; // color elegido en este momento
  late int _usuarioId; // propietario elegido
  String? _error;
  String? _errorFechas;

  bool get _esAdmin => widget.usuarios != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _fechasCtrl = TextEditingController(
      text: e == null ? '' : (List<String>.from(e.fechasCompletadas)..sort()).join(', '),
    );
    _color = e?.color ?? paletaColores.first;
    _usuarioId = e?.usuarioId ?? widget.usuarioIdPorDefecto;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fechasCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe un nombre');
      return;
    }

    final e = widget.existente;
    // Al editar conservamos las fechas ya completadas
    List<String> fechas = List<String>.from(e?.fechasCompletadas ?? const []);

    // Solo el admin puede escribir las fechas a mano
    if (_esAdmin) {
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      final partes = _fechasCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      for (final p in partes) {
        if (!regex.hasMatch(p) || DateTime.tryParse(p) == null) {
          setState(() {
            _error = null;
            _errorFechas = '"$p" no es una fecha válida (aaaa-mm-dd)';
          });
          return;
        }
      }
      fechas = partes.toSet().toList()..sort();
    }

    // Cerramos el diálogo devolviendo el hábito nuevo o editado.
    // El id lo pone SQLite al insertar; al editar mantenemos el que ya tenía.
    Navigator.pop(
      context,
      Habito(
        id: e?.id,
        usuarioId: _usuarioId,
        nombre: nombre,
        color: _color,
        fechasCompletadas: fechas,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existente == null ? 'Nuevo hábito' : 'Editar hábito'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nombreCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: 'Nombre', errorText: _error),
              ),
              const SizedBox(height: 16),

              // Solo administrador: elegir de quién es el hábito
              if (_esAdmin) ...[
                DropdownButtonFormField<int>(
                  value: _usuarioId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Propietario'),
                  items: [
                    for (final u in widget.usuarios!)
                      DropdownMenuItem(
                        value: u.id!,
                        child: Text('${u.usuario} (${u.rol})',
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _usuarioId = v ?? _usuarioId),
                ),
                const SizedBox(height: 16),
              ],

              const Text('Color'),
              const SizedBox(height: 8),
              // Wrap coloca los círculos en filas y salta de línea si no caben
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in paletaColores)
                    GestureDetector(
                      onTap: () => setState(() => _color = c), // elegir color
                      child: CircleAvatar(
                        backgroundColor: Color(c),
                        radius: 18,
                        // El elegido muestra un tick
                        child: _color == c
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                ],
              ),

              // Solo administrador: editar las fechas completadas
              if (_esAdmin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _fechasCtrl,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Fechas completadas',
                    helperText: 'aaaa-mm-dd separadas por comas',
                    errorText: _errorFechas,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // cancelar devuelve null
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
