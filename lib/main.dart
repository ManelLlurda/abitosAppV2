import 'package:flutter/material.dart';
import 'screens/bienvenida_screen.dart';
import 'screens/principal_screen.dart';
import 'services/preferencias_service.dart';

void main() {
  runApp(const HabitosApp());
}

/// StatefulWidget: guarda el estado global (tema, tamaño de letra, carga inicial).
class HabitosApp extends StatefulWidget {
  const HabitosApp({super.key});

  @override
  State<HabitosApp> createState() => _HabitosAppState();
}

class _HabitosAppState extends State<HabitosApp> {
  final PreferenciasService _service = PreferenciasService();

  bool _cargando = true;
  bool _primeraVez = true;
  bool _oscuro = false;
  double _tamanoLetra = PreferenciasService.tamanoLetraPorDefecto;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Lectura asíncrona inicial de SharedPreferences.
  Future<void> _cargar({bool registrarApertura = true}) async {
    await _service.init();
    if (registrarApertura) await _service.registrarApertura();
    if (!mounted) return;
    setState(() {
      _primeraVez = _service.esPrimeraVez;
      _leerAjustes();
      _cargando = false;
    });
  }

  void _leerAjustes() {
    _oscuro = _service.temaOscuro;
    _tamanoLetra = _service.tamanoLetra;
  }

  Future<void> _recargar() async {
    setState(() => _cargando = true);
    await _cargar(registrarApertura: false);
  }

  Future<void> _borrarDatos() async {
    await _service.borrarTodo();
    // Tras borrar, reabrimos como instalación nueva (cuenta como primera apertura).
    setState(() => _cargando = true);
    await _cargar();
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
      scaffoldBackgroundColor: brillo == Brightness.light
          ? const Color(0xFFF3F8F6)
          : scheme.surface,
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
        fillColor: scheme.surfaceContainerHigh.withOpacity(0.5), // Actualizado para compatibilidad
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
          minimumSize: const Size.fromHeight(52),
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
      dialogTheme: DialogThemeData( // <-- SOLUCIÓN AL ERROR: Cambiado a DialogThemeData
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_cargando) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_primeraVez) {
      home = BienvenidaScreen(service: _service, onTerminar: _recargar);
    } else {
      home = PrincipalScreen(
        service: _service,
        onAjustesCambiados: () => setState(_leerAjustes),
        onBorrarDatos: _borrarDatos,
      );
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
