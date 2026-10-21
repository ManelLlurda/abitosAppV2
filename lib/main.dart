import 'package:flutter/material.dart';

import 'models/usuario.dart';
import 'screens/login_screen.dart';
import 'screens/principal_screen.dart';
import 'screens/registro_screen.dart';
import 'services/db_helper.dart';
import 'services/preferencias_service.dart';
import 'services/servicios.dart';

void main() {
  runApp(const HabitosApp());
}

/// StatefulWidget: guarda el estado global (sesión, tema, tamaño de letra, carga inicial).
class HabitosApp extends StatefulWidget {
  const HabitosApp({super.key});

  @override
  State<HabitosApp> createState() => _HabitosAppState();
}

class _HabitosAppState extends State<HabitosApp> {
  final Servicios _s = Servicios();

  bool _cargando = true;
  String? _errorInicio; // si la BD no se puede abrir, se enseña aquí
  bool _hayUsuarios = false; // false = primera vez: toca registrarse
  Usuario? _usuario; // null = nadie con la sesión abierta
  bool _oscuro = false;
  double _tamanoLetra = PreferenciasService.tamanoLetraPorDefecto;

  @override
  void initState() {
    super.initState();
    _arrancar();
  }

  /// Lectura asíncrona inicial: preferencias, sesión guardada y base de datos.
  Future<void> _arrancar() async {
    try {
      await _s.prefs.init();

      // ¿Había una sesión abierta de la última vez?
      Usuario? usuario;
      final id = _s.prefs.usuarioSesion;
      if (id != null) {
        usuario = await _s.usuarios.porId(id);
        if (usuario == null) {
          // El usuario ya no existe (se borró): cerramos la sesión
          await _s.prefs.cerrarSesion();
        } else {
          // Abrir la app con la sesión guardada cuenta como una apertura
          await _s.estadisticas.registrarApertura(usuario.id!);
        }
      }

      final hay = usuario != null || await _s.usuarios.contar() > 0;
      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _hayUsuarios = hay;
        _leerAjustes();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorInicio = '$e';
        _cargando = false;
      });
    }
  }

  void _leerAjustes() {
    _oscuro = _s.prefs.temaOscuro;
    _tamanoLetra = _s.prefs.tamanoLetra;
  }

  /// Login o registro correctos: guardamos la sesión y pasamos a la principal.
  Future<void> _iniciarSesion(Usuario u) async {
    await _s.prefs.guardarSesion(u.id!);
    await _s.estadisticas.registrarApertura(u.id!);
    if (!mounted) return;
    setState(() {
      _usuario = u;
      _hayUsuarios = true;
    });
  }

  Future<void> _cerrarSesion() async {
    await _s.prefs.cerrarSesion();
    if (!mounted) return;
    setState(() => _usuario = null);
  }

  /// Solo admin: vacía la BD y las preferencias. La app queda como recién instalada.
  Future<void> _borrarTodo() async {
    await DbHelper.instancia.borrarTodo();
    await _s.prefs.borrarTodo();
    if (!mounted) return;
    setState(() {
      _usuario = null;
      _hayUsuarios = false;
      _leerAjustes();
    });
  }

  // Tema compartido (claro y oscuro) con bordes redondeados y botones pill.
  ThemeData _tema(Brightness brillo) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00897B),
      brightness: brillo,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
      brillo == Brightness.light ? const Color(0xFFF3F8F6) : scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          // Ancho mínimo normal: si queremos un botón a todo el ancho lo
          // envolvemos en un SizedBox(width: double.infinity). Así los botones
          // también caben dentro de los diálogos.
          minimumSize: const Size(88, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _pantallaError() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo abrir la base de datos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(_errorInicio!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text(
                  'Si estás en web, ejecuta una vez en la terminal:\n'
                      'dart run sqflite_common_ffi_web:setup\n'
                      'y vuelve a lanzar la app.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_cargando) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_errorInicio != null) {
      home = _pantallaError();
    } else if (_usuario != null) {
      home = PrincipalScreen(
        // La key hace que, si entra otro usuario, la pantalla se cree de cero
        key: ValueKey(_usuario!.id),
        servicios: _s,
        usuario: _usuario!,
        onAjustesCambiados: () => setState(_leerAjustes),
        onCerrarSesion: _cerrarSesion,
        onBorrarTodo: _borrarTodo,
      );
    } else if (!_hayUsuarios) {
      // Primera vez que se abre la app: no hay ningún usuario
      home = RegistroScreen(
        servicios: _s,
        onAutenticado: _iniciarSesion,
        primeraVez: true,
      );
    } else {
      home = LoginScreen(servicios: _s, onAutenticado: _iniciarSesion);
    }

    return MaterialApp(
      title: 'HabitosApp',
      debugShowCheckedModeBanner: false,
      themeMode: _oscuro ? ThemeMode.dark : ThemeMode.light,
      theme: _tema(Brightness.light),
      darkTheme: _tema(Brightness.dark),
      // El tamaño de letra del ajuste escala todos los textos de la app.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_tamanoLetra / 16)),
        child: child!,
      ),
      home: home,
    );
  }
}
