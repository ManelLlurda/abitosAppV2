import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/estadistica.dart';
import '../models/habito.dart';
import '../models/usuario.dart';

// Formulario (solo administrador) para crear o editar una fila de "estadisticas".
// Devuelve la Estadistica o null si se cancela.
Future<Estadistica?> mostrarFormularioEstadistica(
  BuildContext context, {
  required List<Usuario> usuarios,
  required List<Habito> habitos,
  Estadistica? existente,
}) {
  return showDialog<Estadistica>(
    context: context,
    builder: (_) => EstadisticaFormDialog(
      usuarios: usuarios,
      habitos: habitos,
      existente: existente,
    ),
  );
}

class EstadisticaFormDialog extends StatefulWidget {
  final List<Usuario> usuarios;
  final List<Habito> habitos;
  final Estadistica? existente;

  const EstadisticaFormDialog({
    super.key,
    required this.usuarios,
    required this.habitos,
    this.existente,
  });

  @override
  State<EstadisticaFormDialog> createState() => _EstadisticaFormDialogState();
}

class _EstadisticaFormDialogState extends State<EstadisticaFormDialog> {
  static final DateFormat _formato = DateFormat('dd/MM/yyyy HH:mm');

  late int _usuarioId;
  late int _habitoId; // 0 = ninguno (estadística de la app); los ids reales empiezan en 1
  late final TextEditingController _rachaCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _aperturasCtrl;
  late final TextEditingController _ultimaCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _usuarioId = e?.usuarioId ?? widget.usuarios.first.id!;
    _habitoId = e?.habitoId ?? 0;
    _rachaCtrl = TextEditingController(text: '${e?.rachaActual ?? 0}');
    _totalCtrl = TextEditingController(text: '${e?.totalCompletados ?? 0}');
    _aperturasCtrl = TextEditingController(text: '${e?.numAperturas ?? 0}');
    _ultimaCtrl = TextEditingController(
      text: e?.ultimaApertura == null ? '' : _formato.format(e!.ultimaApertura!),
    );
  }

  @override
  void dispose() {
    _rachaCtrl.dispose();
    _totalCtrl.dispose();
    _aperturasCtrl.dispose();
    _ultimaCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final racha = int.tryParse(_rachaCtrl.text.trim());
    final total = int.tryParse(_totalCtrl.text.trim());
    final aperturas = int.tryParse(_aperturasCtrl.text.trim());
    if (racha == null || total == null || aperturas == null ||
        racha < 0 || total < 0 || aperturas < 0) {
      setState(() => _error = 'Racha, total y aperturas deben ser números (0 o más)');
      return;
    }

    DateTime? ultima;
    final texto = _ultimaCtrl.text.trim();
    if (texto.isNotEmpty) {
      try {
        ultima = _formato.parseStrict(texto);
      } on FormatException {
        setState(() => _error = 'Fecha no válida. Usa dd/mm/aaaa hh:mm');
        return;
      }
    }

    Navigator.pop(
      context,
      Estadistica(
        id: widget.existente?.id,
        usuarioId: _usuarioId,
        habitoId: _habitoId == 0 ? null : _habitoId,
        rachaActual: racha,
        totalCompletados: total,
        numAperturas: aperturas,
        ultimaApertura: ultima,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solo se pueden elegir hábitos del usuario seleccionado
    final habitosDelUsuario =
        widget.habitos.where((h) => h.usuarioId == _usuarioId).toList();

    return AlertDialog(
      title: Text(widget.existente == null ? 'Nueva estadística' : 'Editar estadística'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _usuarioId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Usuario'),
                items: [
                  for (final u in widget.usuarios)
                    DropdownMenuItem(value: u.id!, child: Text(u.usuario)),
                ],
                onChanged: (v) => setState(() {
                  _usuarioId = v ?? _usuarioId;
                  _habitoId = 0; // al cambiar de usuario se reinicia el hábito
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _habitoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Hábito'),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Ninguno (estadística de la app)'),
                  ),
                  for (final h in habitosDelUsuario)
                    DropdownMenuItem(
                      value: h.id!,
                      child: Text(h.nombre, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _habitoId = v ?? 0),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rachaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Racha actual (días)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total de días completados'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aperturasCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Veces que se ha abierto la app'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ultimaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Última apertura',
                  helperText: 'dd/mm/aaaa hh:mm (vacío = ninguna)',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
