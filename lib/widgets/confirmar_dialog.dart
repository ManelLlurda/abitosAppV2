import 'package:flutter/material.dart';

/// Diálogo de confirmación para acciones peligrosas (borrar...).
/// Devuelve true solo si el usuario pulsa el botón rojo.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  String textoBoton = 'Borrar',
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, size: 40, color: scheme.error),
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: Colors.white,
          ),
          child: Text(textoBoton),
        ),
      ],
    ),
  );
  return ok == true;
}
