import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import 'auth_design.dart';

class WachtwoordResetCodeScreen extends StatefulWidget {
  const WachtwoordResetCodeScreen({super.key, required this.email});

  final String email;

  @override
  State<WachtwoordResetCodeScreen> createState() =>
      _WachtwoordResetCodeScreenState();
}

class _WachtwoordResetCodeScreenState extends State<WachtwoordResetCodeScreen> {
  static const _codeLength = 8;

  final _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_codeLength, (_) => FocusNode());

  bool _laden = false;
  bool _kanHerversturen = false;
  int _countdown = 59;
  Timer? _timer;

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

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _kanHerversturen = true);
      } else {
        setState(() => _countdown--);
      }
    });
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
      await StudentService.client.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.recovery,
      );
      if (mounted) context.go('/reset-password');
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = e.message.toLowerCase();
      _toonFout(message.contains('invalid') || message.contains('expired')
          ? 'Ongeldige of verlopen code. Vraag een nieuwe aan.'
          : e.message);
    } catch (e) {
      debugPrint('[reset-code] onverwachte fout: $e');
      if (mounted) _toonFout('Verificatie mislukt. Probeer opnieuw.');
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }

  Future<void> _herverstuur() async {
    if (!_kanHerversturen || _laden) return;
    try {
      await StudentService.stuurWachtwoordReset(widget.email);
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nieuwe code verstuurd naar ${widget.email}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.dark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) _toonFout(_vriendelijkeFout(e.message));
    } catch (e) {
      debugPrint('[reset-code] herverstuur fout: $e');
      if (mounted) _toonFout('Opnieuw sturen mislukt. Probeer opnieuw.');
    }
  }

  String _vriendelijkeFout(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('rate limit') ||
        lower.contains('too many') ||
        lower.contains('security purposes')) {
      return 'Wacht even voordat je een nieuwe code aanvraagt.';
    }
    return message;
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
            onPressed: () => context.go('/wachtwoord-vergeten'),
          ),
          title: const Text('Verificatiecode'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.dark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                Text(
                  'Herstelcode invoeren',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Voer de 8-cijferige code in die naar\n${widget.email} is gestuurd',
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
                      children: List.generate(_codeLength, (index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == _codeLength - 1 ? 0 : gap,
                          ),
                          child: _OtpVeld(
                            width: boxWidth,
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            onChanged: (value) =>
                                _handleCodeChanged(index, value),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
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
                            'Code bevestigen',
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
  const _OtpVeld({
    required this.width,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final double width;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

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
          borderRadius: BorderRadius.circular(12),
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
            maxLength: _WachtwoordResetCodeScreenState._codeLength,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                  _WachtwoordResetCodeScreenState._codeLength),
            ],
            cursorColor: AppColors.primary,
            cursorHeight: 22,
            cursorWidth: 2,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: AppColors.dark,
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
