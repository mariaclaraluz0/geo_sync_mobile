import 'package:flutter/material.dart';

/// Componentes visuais compartilhados pelas telas de configurações do
/// cliente e do motorista, para manter as duas experiências consistentes.

const _primary = Color(0xFF0C46FF);
const _primaryDark = Color(0xFF0B2A4A);

/// Paleta de acentos usada nos ícones de cada opção.
class SettingsColors {
  SettingsColors._();

  static const blue = Color(0xFF2563EB);
  static const indigo = Color(0xFF6366F1);
  static const violet = Color(0xFF8B5CF6);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF10B981);
  static const teal = Color(0xFF14B8A6);
  static const rose = Color(0xFFF43F5E);
  static const orange = Color(0xFFF97316);
  static const slate = Color(0xFF64748B);
}

/// Ícone dentro de um bloco arredondado com fundo suave da cor de acento.
class SettingsIconBadge extends StatelessWidget {
  const SettingsIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.11),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Título de uma seção com um pequeno rótulo em caixa alta.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 22, 6, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: scheme.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cartão que agrupa várias opções separadas por divisórias finas.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 70,
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        );
      }
      items.add(children[i]);
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: _primaryDark.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: items),
        ),
      ),
    );
  }
}

/// Estrutura base de uma linha de configuração.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(
            children: [
              SettingsIconBadge(icon: icon, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          subtitle!,
                          key: ValueKey(subtitle),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha com interruptor. Toda a linha é tocável para facilitar o uso.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: _SettingsRow(
        icon: icon,
        color: color,
        title: title,
        subtitle: subtitle,
        enabled: enabled,
        onTap: () => onChanged(!value),
        trailing: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: Colors.white,
          activeTrackColor: _primary,
          thumbIcon: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Icon(Icons.check_rounded, size: 16, color: _primary)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Linha de navegação/ação com seta à direita.
class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.loading = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  /// Texto curto exibido como selo à direita (ex.: "3 pendentes").
  final String? value;

  /// Mostra um indicador de progresso no lugar da seta e bloqueia o toque.
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsRow(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      onTap: loading ? null : onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value!,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (loading)
            Padding(
              padding: const EdgeInsets.all(3),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: color,
                ),
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
              size: 22,
            ),
        ],
      ),
    );
  }
}

/// Linha apenas informativa (ex.: versão do app).
class SettingsInfoTile extends StatelessWidget {
  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsRow(
      icon: icon,
      color: color,
      title: title,
      trailing: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(
          value,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Cartão de resumo da conta exibido no topo das configurações.
class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.initial,
    required this.role,
    required this.roleIcon,
    this.onTap,
  });

  final String name;
  final String email;
  final String initial;
  final String role;
  final IconData roleIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: _primaryDark.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primary, Color(0xFF6366F1)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, size: 13, color: scheme.primary),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              role,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seletor visual de tema com pré-visualização Claro/Escuro.
class SettingsThemeSelector extends StatelessWidget {
  const SettingsThemeSelector({
    super.key,
    required this.darkMode,
    required this.onChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SettingsIconBadge(
                icon: Icons.palette_rounded,
                color: SettingsColors.violet,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema do aplicativo',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Aplicado imediatamente',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  label: 'Claro',
                  icon: Icons.light_mode_rounded,
                  selected: !darkMode,
                  dark: false,
                  onTap: () => onChanged(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeOption(
                  label: 'Escuro',
                  icon: Icons.dark_mode_rounded,
                  selected: darkMode,
                  dark: true,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final previewBg = dark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB);
    final previewCard = dark ? const Color(0xFF202D42) : Colors.white;
    final previewLine = dark
        ? const Color(0xFF40516A)
        : const Color(0xFFE2E8F0);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Miniatura da interface no tema correspondente.
              Container(
                height: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: previewBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryDark, _primary],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: previewCard,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FractionallySizedBox(
                              widthFactor: 0.8,
                              child: Container(height: 4, color: previewLine),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.5,
                              child: Container(height: 4, color: previewLine),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    size: 16,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? scheme.primary : scheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alça e título padrão para bottom sheets das configurações.
class SettingsSheetHeader extends StatelessWidget {
  const SettingsSheetHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 42,
          height: 5,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: scheme.outlineVariant,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Row(
          children: [
            SettingsIconBadge(icon: icon, color: color, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// SnackBar flutuante padronizado com ícone.
void showSettingsMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFB91C1C) : _primaryDark,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
}
