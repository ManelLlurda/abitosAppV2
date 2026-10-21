import 'package:flutter/material.dart';
import '../models/habito.dart';

// Widget de una fila de hábito. No tiene estado propio (StatelessWidget):
// solo dibuja lo que le pasan y avisa cuando se pulsa la casilla.
class HabitoTile extends StatelessWidget {
  final Habito habito;
  final ValueChanged<bool?> onChanged; // función que se ejecuta al marcar/desmarcar

  const HabitoTile({
    super.key,
    required this.habito,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(habito.color);
    final hecho = habito.completadoHoy;
    final racha = habito.rachaActual;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Si está hecho, la tarjeta se tiñe del color del hábito
        color: hecho ? color.withOpacity(0.14) : scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hecho ? color : scheme.outlineVariant,
          width: hecho ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(!hecho),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Círculo con el color del hábito
                CircleAvatar(
                  backgroundColor: color,
                  radius: 20,
                  child: Icon(
                    hecho ? Icons.check_rounded : Icons.circle_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habito.nombre,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          // Si está hecho, tachamos el texto
                          decoration:
                              hecho ? TextDecoration.lineThrough : null,
                          color: hecho
                              ? scheme.onSurface.withOpacity(0.6)
                              : scheme.onSurface,
                        ),
                      ),
                      if (racha > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                size: 16, color: Colors.deepOrange),
                            const SizedBox(width: 4),
                            Text(
                              '$racha ${racha == 1 ? 'día' : 'días'} de racha',
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Checkbox(
                  value: hecho,
                  onChanged: onChanged,
                  activeColor: color,
                  shape: const CircleBorder(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
