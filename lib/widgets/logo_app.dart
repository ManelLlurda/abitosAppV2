import 'package:flutter/material.dart';

// Logo circular con degradado (lo usan el login y el registro).
// StatelessWidget: no tiene estado, solo dibuja.
class LogoApp extends StatelessWidget {
  final double tamano;

  const LogoApp({super.key, this.tamano = 110});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, Color.lerp(scheme.primary, Colors.cyan, 0.5)!],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(Icons.check_rounded, size: tamano * 0.58, color: scheme.onPrimary),
    );
  }
}
