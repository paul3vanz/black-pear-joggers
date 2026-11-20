import 'package:flutter/material.dart';

/// The icon that marks anything only committee members and admins can use.
/// The server allows both roles, so the app says "Admin only" for either.
const adminIcon = Icons.admin_panel_settings_outlined;

const _adminLabel = 'Admin only';

/// A small shield that says "Admin only". Put it at the end of a link, a button
/// label, a menu item or an app bar so the restriction is visible at a glance.
class AdminBadge extends StatelessWidget {
  const AdminBadge({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: _adminLabel,
    child: Icon(
      adminIcon,
      size: size,
      color: Theme.of(context).colorScheme.secondary,
      semanticLabel: _adminLabel,
    ),
  );
}

/// The trailing widget of an admin-only list tile: the badge, then (by default)
/// the usual chevron.
class AdminTrailing extends StatelessWidget {
  const AdminTrailing({super.key, this.chevron = true});

  final bool chevron;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const AdminBadge(),
      if (chevron) ...[
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right),
      ],
    ],
  );
}

/// A button or menu label followed by the admin badge.
class AdminLabel extends StatelessWidget {
  const AdminLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(text)),
      const SizedBox(width: 8),
      const AdminBadge(size: 18),
    ],
  );
}

/// Wraps a group of admin-only controls in a bordered, lightly shaded panel with
/// an "Admin only" tag, so it reads as a separate, restricted area.
class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: scheme.secondary, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(adminIcon, size: 18, color: scheme.secondary),
              const SizedBox(width: 6),
              Text(
                _adminLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// An app bar action marking the whole screen as admin only.
class AdminAppBarAction extends StatelessWidget {
  const AdminAppBarAction({super.key});

  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.only(right: 16), child: AdminBadge());
}
