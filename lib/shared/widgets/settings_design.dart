import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/cool_icons.dart';
import 'framer_toggle.dart';
import 'main_scaffold.dart';

class SettingsDesign {
  SettingsDesign._();

  static Color get background =>
      AppColors.isDarkMode ? const Color(0xFF161922) : const Color(0xFFF5F5F5);
  static Color get card =>
      AppColors.isDarkMode ? const Color(0xFF1E2330) : const Color(0xFFFFFFFF);
  static Color get title =>
      AppColors.isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111111);
  static Color get subtitle =>
      AppColors.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF8A8A8E);
  static Color get divider =>
      AppColors.isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFEFEFEF);
  static Color get chevron =>
      AppColors.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF9E9E9E);
  static const Color switchOn = Color(0xFF34C759);
  static Color get switchOff =>
      AppColors.isDarkMode ? const Color(0xFF3F4A5C) : const Color(0xFFE0E0E0);
  static Color get inputFill =>
      AppColors.isDarkMode ? const Color(0xFF283244) : const Color(0xFFEBEBEB);
  static Color get fieldLabel =>
      AppColors.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF7A7A7A);
  static Color get readOnlyText =>
      AppColors.isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF8A8A8E);
  static Color get iconDark =>
      AppColors.isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF222222);
  static Color get avatarFill =>
      AppColors.isDarkMode ? const Color(0xFF334155) : const Color(0xFFD9D9D9);
  static Color get avatarIcon =>
      AppColors.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF9A9A9A);

  static const double cardRadius = 12;
  static const double cardSpacing = 12;
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(16, 12, 16, 40);
  static const EdgeInsets rowPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  static TextStyle get titleStyle => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: title,
      );

  static TextStyle get subtitleStyle => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: subtitle,
        height: 1.4,
      );
}

class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : SettingsDesign.card,
        borderRadius: BorderRadius.circular(SettingsDesign.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? AppColors.darkBorder : AppColors.borderLight,
      ),
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  final String? title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchRow({
    super.key,
    this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleStyle = isDark
        ? SettingsDesign.titleStyle.copyWith(color: AppColors.darkTextPrimary)
        : SettingsDesign.titleStyle;
    final subtitleStyle = isDark
        ? SettingsDesign.subtitleStyle
            .copyWith(color: AppColors.darkTextSecondary)
        : SettingsDesign.subtitleStyle;
    return Padding(
      padding: SettingsDesign.rowPadding,
      child: Row(
        children: [
          Expanded(
            child: title != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title!, style: titleStyle),
                      const SizedBox(height: 4),
                      Text(subtitle, style: subtitleStyle),
                    ],
                  )
                : Text(subtitle, style: subtitleStyle),
          ),
          const SizedBox(width: 16),
          FramerToggle(
            value: value,
            onChanged: onChanged,
            activeColor: SettingsDesign.switchOn,
          ),
        ],
      ),
    );
  }
}

class SettingsScaffold extends StatelessWidget {
  final String titel;
  final List<Widget> children;
  final VoidCallback? onSave;
  final bool bezig;

  const SettingsScaffold({
    super.key,
    required this.titel,
    required this.children,
    this.onSave,
    this.bezig = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : SettingsDesign.background;
    final fg = isDark ? AppColors.darkTextPrimary : SettingsDesign.title;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(CoolIcons.chevronLeft, color: fg, size: 28),
          onPressed: () => terugNavigeren(context),
        ),
        title: Text(
          titel,
          style:
              TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: onSave == null
            ? null
            : [
                IconButton(
                  onPressed: bezig ? null : onSave,
                  icon: bezig
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(CoolIcons.check,
                          color: SettingsDesign.switchOn, size: 28),
                ),
              ],
      ),
      body: ListView(
        padding: SettingsDesign.screenPadding.copyWith(
          bottom: SettingsDesign.screenPadding.bottom +
              NavBarOverlayInset.of(context),
        ),
        children: children,
      ),
    );
  }
}

class SettingsBodyScaffold extends StatelessWidget {
  final String titel;
  final Widget body;
  final List<Widget>? actions;

  const SettingsBodyScaffold({
    super.key,
    required this.titel,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : SettingsDesign.background;
    final fg = isDark ? AppColors.darkTextPrimary : SettingsDesign.title;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(CoolIcons.chevronLeft, color: fg, size: 28),
          onPressed: () => terugNavigeren(context),
        ),
        title: Text(
          titel,
          style:
              TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: actions,
      ),
      body: body,
    );
  }
}

void terugNavigeren(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/profiel');
  }
}

// ── Velden (1-op-1 uit de Instructeur-app, profiel_screen.dart) ──────────────
//
// Opbouw: label (13px, w600) BOVEN het veld, daaronder een wit veld van 56px
// met 16px radius en 18px tekst. Alleen-lezen velden (enabled: false) tonen
// dezelfde vorm in het grijs ([SettingsDesign.readOnlyText]). Een scherm met
// bewerkbare velden toont rechtsboven het groene vinkje van [SettingsScaffold]
// (onSave); een scherm met alleen-lezen velden toont geen vinkje.

/// Sectielabel boven een veld.
class SettingsSectieLabel extends StatelessWidget {
  final String tekst;
  const SettingsSectieLabel(this.tekst, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      tekst,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }
}

/// Het veld zelf (56px, wit, 16px radius, 18px tekst).
class SettingsEditVeld extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboard;
  final String? hint;
  final bool obscure;
  final Widget? suffix;
  final int maxLines;

  const SettingsEditVeld({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.keyboard,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? AppColors.darkCard : Colors.white;
    final hintColor =
        isDark ? AppColors.darkTextSecondary : SettingsDesign.fieldLabel;
    final textColor = enabled
        ? (isDark ? AppColors.darkTextPrimary : SettingsDesign.title)
        : (isDark ? const Color(0xFFCBD5E1) : SettingsDesign.readOnlyText);

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboard,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        minLines: 1,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: SettingsDesign.switchOn,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: hint ?? label,
          suffixIcon: suffix,
          hintStyle: TextStyle(fontSize: 15, color: hintColor),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          contentPadding: maxLines > 1
              ? const EdgeInsets.symmetric(vertical: 13)
              : EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Label + veld, zoals `_veld(...)` in de Instructeur-app.
class SettingsVeld extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final TextInputType? keyboard;
  final String? hint;
  final bool obscure;
  final Widget? suffix;
  final int maxLines;

  const SettingsVeld({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.keyboard,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectieLabel(label),
        const SizedBox(height: 6),
        SettingsEditVeld(
          label: label,
          controller: controller,
          enabled: enabled,
          keyboard: keyboard,
          hint: hint,
          obscure: obscure,
          suffix: suffix,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

/// Alleen-lezen waarde in dezelfde vorm als een veld: handig voor gegevens die
/// niet uit een tekstveld komen (hoeft geen controller bij de aanroeper).
class SettingsWaarde extends StatefulWidget {
  final String label;
  final String waarde;
  final int maxLines;

  const SettingsWaarde({
    super.key,
    required this.label,
    required this.waarde,
    this.maxLines = 1,
  });

  @override
  State<SettingsWaarde> createState() => _SettingsWaardeState();
}

class _SettingsWaardeState extends State<SettingsWaarde> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.waarde);

  @override
  void didUpdateWidget(covariant SettingsWaarde oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waarde != widget.waarde) _ctrl.text = widget.waarde;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsVeld(
      controller: _ctrl,
      label: widget.label,
      enabled: false,
      maxLines: widget.maxLines,
    );
  }
}

/// Sectiekop boven een groep kaarten -- 1-op-1 uit de Instructeur-app
/// (juridisch_screen.dart `_SectieLabel`): 11px, w700, letterspatiëring 0.7.
class SettingsKop extends StatelessWidget {
  const SettingsKop(this.tekst, {super.key});
  final String tekst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        tekst.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkTextHint
              : AppColors.textHint,
        ),
      ),
    );
  }
}
