import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import 'auth_design.dart';

class VerificatieScreen extends StatefulWidget {
  final String email;

  const VerificatieScreen({super.key, required this.email});

  @override
  State<VerificatieScreen> createState() => _VerificatieScreenState();
}

class _VerificatieScreenState extends State<VerificatieScreen> {
  static const _codeLength = 8;

  final _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_codeLength, (_) => FocusNode());

  bool _laden = false;
  bool _kanHerversturen = false;
  int _countdown = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 59;
      _kanHerversturen = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _kanHerversturen = true);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _handleCodeChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (var offset = 0; offset < digits.length; offset++) {
        final target = index + offset;
        if (target >= _codeLength) break;
        _controllers[target].text = digits[offset];
      }
      final nextIndex = (index + digits.length).clamp(0, _codeLength - 1);
      if (index + digits.length >= _codeLength) {
        _focusNodes[_codeLength - 1].unfocus();
      } else {
        _focusNodes[nextIndex].requestFocus();
      }
      return;
    }
    if (digits.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (digits.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifieer() async {
    if (_laden) return;
    final code = _otpCode;
    if (code.length < _codeLength) {
      _toonFout('Vul alle $_codeLength cijfers in');
      return;
    }
    setState(() => _laden = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.signup,
      );
      if (mounted) context.go('/koppelcode');
    } on AuthException catch (e) {
      _toonFout(e.message.contains('invalid')
          ? 'Ongeldige code. Controleer je e-mail.'
          : 'Verificatie mislukt. Probeer opnieuw.');
    } catch (_) {
      _toonFout('Verificatie mislukt. Probeer opnieuw.');
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }

  Future<void> _herverstuur() async {
    if (!_kanHerversturen || _laden) return;
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
        emailRedirectTo: AppConfig.authConfirmRedirectUrl,
      );
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nieuwe code verstuurd')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) _toonFout(_vriendelijkeFout(e.message));
    } catch (_) {
      if (mounted) _toonFout('Herversturen mislukt. Probeer opnieuw.');
    }
  }

  String _vriendelijkeFout(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('only request this after') ||
        m.contains('security purposes') ||
        m.contains('rate limit') ||
        m.contains('too many requests')) {
      return 'Wacht even voordat je opnieuw een code aanvraagt.';
    }
    return msg;
  }

  void _toonFout(String bericht) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bericht,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AuthDesign.error,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/registreer'),
          ),
          title: const Text('E-mail bevestigen'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bijna klaar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Voer de 8-cijferige verificatiecode in die naar\n${widget.email} is verzonden',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = constraints.maxWidth < 340 ? 4.0 : 6.0;
                    final boxWidth =
                        ((constraints.maxWidth - (gap * (_codeLength - 1))) /
                                _codeLength)
                            .clamp(30.0, 46.0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_codeLength, (i) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: i == _codeLength - 1 ? 0 : gap,
                          ),
                          child: _OtpVeld(
                            width: boxWidth,
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (val) => _handleCodeChanged(i, val),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  height: 52,
                  child: ElevatedButton(
                    style: AuthDesign.primaryButtonStyle(),
                    onPressed: _laden ? null : _verifieer,
                    child: _laden
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Verifieer',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Geen code ontvangen? ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _kanHerversturen ? _herverstuur : null,
                      child: Text(
                        'Opnieuw sturen',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kanHerversturen
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!_kanHerversturen)
                  Text(
                    'Nieuwe code aanvragen over 00:${_countdown.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpVeld extends StatefulWidget {
  final double width;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpVeld({
    required this.width,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_OtpVeld> createState() => _OtpVeldState();
}

class _OtpVeldState extends State<_OtpVeld> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _OtpVeld oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final heeftFocus = widget.focusNode.hasFocus;

    return SizedBox(
      width: widget.width,
      height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: heeftFocus ? AuthDesign.focusBorder : AuthDesign.border,
            width: heeftFocus ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: _VerificatieScreenState._codeLength,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                  _VerificatieScreenState._codeLength),
            ],
            cursorColor: AppColors.primary,
            cursorHeight: 22,
            cursorWidth: 2,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.0,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            strutStyle: const StrutStyle(
              fontSize: 20,
              height: 1,
              forceStrutHeight: true,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}
