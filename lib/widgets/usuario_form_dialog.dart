import 'package:flutter/material.dart';

import '../errores.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

// Formulario (solo administrador) para crear o editar un usuario.
// Devuelve el Usuario listo para guardar (con la contraseña ya cifrada)
// o null si se cancela.
//  - [existente]: si viene, estamos editando.
//  - [esYo]: el admin se está editando a sí mismo (no puede cambiarse el rol,
//    así nunca se deja la app sin administrador).
Future<Usuario?> mostrarFormularioUsuario(
  BuildContext context, {
  required AuthService auth,
  Usuario? existente,
  bool esYo = false,
}) {
  return showDialog<Usuario>(
    context: context,
    builder: (_) => UsuarioFormDialog(auth: auth, existente: existente, esYo: esYo),
  );
}

class UsuarioFormDialog extends StatefulWidget {
  final AuthService auth;
  final Usuario? existente;
  final bool esYo;

  const UsuarioFormDialog({
    super.key,
    required this.auth,
    this.existente,
    this.esYo = false,
  });

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  late final TextEditingController _usuarioCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _emailCtrl;
  final _passCtrl = TextEditingController();
  late String _rol;
  bool _verPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _usuarioCtrl = TextEditingController(text: e?.usuario ?? '');
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _apellidosCtrl = TextEditingController(text: e?.apellidos ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _rol = e?.rol ?? Usuario.rolUsuario;
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final e = widget.existente;
    try {
      AuthService.validarDatos(
        usuario: _usuarioCtrl.text,
        nombre: _nombreCtrl.text,
        apellidos: _apellidosCtrl.text,
        email: _emailCtrl.text,
      );

      // Contraseña: al crear es obligatoria; al editar, vacío = no cambiarla
      final pass = _passCtrl.text;
      final String contrasena;
      if (pass.isEmpty) {
        if (e == null) throw const ErrorApp('Escribe una contraseña');
        contrasena = e.contrasena;
      } else {
        AuthService.validarPassword(pass);
        contrasena = widget.auth.cifrar(pass);
      }

      Navigator.pop(
        context,
        Usuario(
          id: e?.id,
          usuario: _usuarioCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim(),
          apellidos: _apellidosCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          contrasena: contrasena,
          fechaCreacion: e?.fechaCreacion,
          rol: _rol,
        ),
      );
    } on ErrorApp catch (err) {
      setState(() => _error = err.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.existente != null;
    return AlertDialog(
      title: Text(editando ? 'Editar usuario' : 'Nuevo usuario'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usuarioCtrl,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apellidosCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: !_verPassword,
                decoration: InputDecoration(
                  labelText: editando ? 'Nueva contraseña' : 'Contraseña',
                  helperText: editando ? 'Déjala vacía para no cambiarla' : null,
                  suffixIcon: IconButton(
                    icon: Icon(_verPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _verPassword = !_verPassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _rol,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  helperText: widget.esYo ? 'No puedes cambiar tu propio rol' : null,
                ),
                items: const [
                  DropdownMenuItem(
                      value: Usuario.rolUsuario, child: Text('Usuario')),
                  DropdownMenuItem(
                      value: Usuario.rolAdmin, child: Text('Administrador')),
                ],
                // null desactiva el desplegable
                onChanged: widget.esYo
                    ? null
                    : (v) => setState(() => _rol = v ?? _rol),
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
