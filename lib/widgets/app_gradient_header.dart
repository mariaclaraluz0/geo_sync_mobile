import 'package:flutter/material.dart';

/// Cabeçalho com gradiente e cantos arredondados, no mesmo estilo já usado
/// na tela de Alertas e nos dashboards, para padronizar as telas que ainda
/// usavam um AppBar simples.
class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.local_shipping_outlined,
    this.showBackButton = true,
    this.onBack,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  static const _primary = Color(0xFF0C46FF);
  static const _primaryDark = Color(0xFF0B2A4A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryDark, _primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }
}
