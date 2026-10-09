import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/domain/brand_mark.dart';
import '../../../shared/widgets/feedback/error_banner.dart';

enum AuthMode { signIn, signUp }

/// Entrada do app. E-mail e senha, nada mais.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthMode _mode = AuthMode.signIn;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  bool get _isSignUp => _mode == AuthMode.signUp;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _mode = _isSignUp ? AuthMode.signIn : AuthMode.signUp;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await (_isSignUp
          ? auth.signUp(
              email: _emailController.text,
              password: _passwordController.text,
              displayName: _nameController.text,
            )
          : auth.signIn(
              email: _emailController.text,
              password: _passwordController.text,
            ));

      // Daqui não navegamos: o router observa o Firebase Auth, e o
      // espelho em `users/{uid}` é criado por currentUserProvider.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Algo deu errado. Tente de novo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Digite seu e-mail para receber o link.');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        context.showSnack('Link de recuperação enviado para $email',
            icon: Icons.mark_email_read_rounded);
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _Backdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Gap.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Logo(),
                      Gap.vXl,
                      _Card(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isSignUp ? 'Criar conta' : 'Entrar',
                                style: context.text.headlineSmall,
                              ),
                              Gap.vXl,

                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Seu nome',
                                    hintText: 'Nome e sobrenome',
                                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                  ),
                                  validator: (v) => (v == null || v.trim().length < 2)
                                      ? 'Diga seu nome'
                                      : null,
                                ),
                                Gap.vLg,
                              ],

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  hintText: 'voce@email.com',
                                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                                ),
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return 'Informe seu e-mail';
                                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                                  return ok ? null : 'E-mail inválido';
                                },
                              ),
                              Gap.vLg,

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: [
                                  _isSignUp ? AutofillHints.newPassword : AutofillHints.password
                                ],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                    tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                                  ),
                                  helperText: _isSignUp ? 'Mínimo de 6 caracteres' : null,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Informe sua senha';
                                  if (_isSignUp && v.length < 6) {
                                    return 'A senha precisa ter ao menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),

                              if (!_isSignUp)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _loading ? null : _resetPassword,
                                    child: const Text('Esqueci minha senha'),
                                  ),
                                ),

                              if (_error != null) ...[
                                Gap.vMd,
                                ErrorBanner(message: _error!),
                              ],

                              Gap.vLg,
                              FilledButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.colors.onPrimary,
                                        ),
                                      )
                                    : Text(_isSignUp ? 'Criar conta' : 'Entrar'),
                              ),
                              Gap.vMd,
                              // `Wrap`, não `Row`: a pergunta e o botão passam
                              // dos 264px do cartão em tela estreita, e mais
                              // ainda com a fonte aumentada no navegador.
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _isSignUp ? 'Já tem conta?' : 'Ainda não tem conta?',
                                    style: context.text.bodySmall,
                                  ),
                                  TextButton(
                                    onPressed: _loading ? null : _switchMode,
                                    child: Text(_isSignUp ? 'Entrar' : 'Criar agora'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BrandMark(size: 32),
        Gap.vXs,
        Text(
          'Roteiro, contas e fotos da viagem',
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.brXl,
        border: Border.all(color: context.colors.outline),
        boxShadow: AppColors.glow(AppColors.coral, opacity: context.isDark ? 0 : 0.12, blur: 40, y: 16),
      ),
      child: child,
    );
  }
}

/// Fundo do login: um degradê bem suave de coral para pêssego, cruzando
/// a tela na diagonal.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF2A1A19), Color(0xFF171211), Color(0xFF2A2017)]
              : const [AppColors.coralSoft, AppColors.background, AppColors.sunsetSoft],
        ),
      ),
    );
  }
}
