import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/features/auth/providers/auth_provider.dart';
import 'package:couple_app/features/auth/providers/profile_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regNameController = TextEditingController();
  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _loading = false;

  String? _loginEmailErr;
  String? _loginPassErr;
  String? _regNameErr;
  String? _regEmailErr;
  String? _regPassErr;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _emailController.addListener(() => setState(() => _loginEmailErr = null));
    _passwordController.addListener(() => setState(() => _loginPassErr = null));
    _regNameController.addListener(() => setState(() => _regNameErr = null));
    _regEmailController.addListener(() => setState(() => _regEmailErr = null));
    _regPasswordController.addListener(
      () => setState(() => _regPassErr = null),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regNameController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String e) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);

  Future<void> _login() async {
    setState(() {
      _loginEmailErr = null;
      _loginPassErr = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    bool valid = true;

    if (email.isEmpty) {
      setState(() => _loginEmailErr = 'Введите email');
      valid = false;
    } else if (!_isValidEmail(email)) {
      setState(() => _loginEmailErr = 'Некорректный формат email');
      valid = false;
    }
    if (password.isEmpty) {
      setState(() => _loginPassErr = 'Введите пароль');
      valid = false;
    } else if (password.length < 6) {
      setState(() => _loginPassErr = 'Минимум 6 символов');
      valid = false;
    }
    if (!valid) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);

      // FIX 3: загружаем имя из Firebase после входа
      if (mounted) {
        final user = ref.read(authRepositoryProvider).currentUser;
        if (user != null) {
          final data = await ref
              .read(authRepositoryProvider)
              .getUserData(user.uid);
          if (data != null && data['name'] != null) {
            ref.read(profileProvider.notifier).setName(data['name'] as String);
          }
        }
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('user-not-found') ||
            msg.contains('INVALID_LOGIN_CREDENTIALS'))
          setState(() => _loginPassErr = 'Неверный email или пароль');
        else if (msg.contains('wrong-password'))
          setState(() => _loginPassErr = 'Неверный пароль');
        else
          setState(() => _loginEmailErr = 'Ошибка входа');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    setState(() {
      _regNameErr = null;
      _regEmailErr = null;
      _regPassErr = null;
    });
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text.trim();
    bool valid = true;

    if (name.isEmpty) {
      setState(() => _regNameErr = 'Введите имя');
      valid = false;
    } else if (name.length < 2) {
      setState(() => _regNameErr = 'Минимум 2 символа');
      valid = false;
    }
    if (email.isEmpty) {
      setState(() => _regEmailErr = 'Введите email');
      valid = false;
    } else if (!_isValidEmail(email)) {
      setState(() => _regEmailErr = 'Некорректный формат email');
      valid = false;
    }
    if (password.isEmpty) {
      setState(() => _regPassErr = 'Введите пароль');
      valid = false;
    } else if (password.length < 6) {
      setState(() => _regPassErr = 'Минимум 6 символов');
      valid = false;
    }
    if (!valid) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .register(name: name, email: email, password: password);

      // FIX 3: сразу устанавливаем имя и ждём сохранения
      await ref.read(profileProvider.notifier).setName(name);

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('email-already-in-use'))
          setState(() => _regEmailErr = 'Этот email уже зарегистрирован');
        else if (msg.contains('weak-password'))
          setState(() => _regPassErr = 'Пароль слишком простой');
        else
          setState(() => _regEmailErr = 'Не удалось зарегистрироваться');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final name = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (name != null && mounted) {
        await ref.read(profileProvider.notifier).setName(name);
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка входа через Google'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              TabBar(
                controller: _tabController,
                labelStyle: AppTextStyles.bodyL.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTextStyles.bodyL,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Авторизоваться'),
                  Tab(text: 'Зарегистрироваться'),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LoginTab(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      emailErr: _loginEmailErr,
                      passErr: _loginPassErr,
                      obscure: _obscureLogin,
                      onToggle: () =>
                          setState(() => _obscureLogin = !_obscureLogin),
                      onLogin: _login,
                      onGoogle: _loginWithGoogle,
                      loading: _loading,
                    ),
                    _RegisterTab(
                      nameController: _regNameController,
                      emailController: _regEmailController,
                      passwordController: _regPasswordController,
                      nameErr: _regNameErr,
                      emailErr: _regEmailErr,
                      passErr: _regPassErr,
                      obscure: _obscureReg,
                      onToggle: () =>
                          setState(() => _obscureReg = !_obscureReg),
                      onRegister: _register,
                      onGoogle: _loginWithGoogle,
                      loading: _loading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Таб входа ─────────────────────────────────────────────────────────
class _LoginTab extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? emailErr;
  final String? passErr;
  final bool obscure;
  final VoidCallback onToggle;
  final VoidCallback onLogin;
  final VoidCallback onGoogle;
  final bool loading;

  const _LoginTab({
    required this.emailController,
    required this.passwordController,
    this.emailErr,
    this.passErr,
    required this.obscure,
    required this.onToggle,
    required this.onLogin,
    required this.onGoogle,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(text: 'Ваш Email'),
          const SizedBox(height: 8),
          _InputField(
            controller: emailController,
            hint: 'Введите ваш Email',
            keyboardType: TextInputType.emailAddress,
            error: emailErr,
          ),
          const SizedBox(height: 20),
          const _Label(text: 'Пароль'),
          const SizedBox(height: 8),
          _InputField(
            controller: passwordController,
            hint: 'Введите ваш пароль',
            obscure: obscure,
            error: passErr,
            suffix: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _GradBtn(
            label: loading ? 'Загрузка...' : 'Войти',
            onTap: loading ? null : onLogin,
          ),
          const SizedBox(height: 24),
          const _OrDivider(),
          const SizedBox(height: 24),
          _GoogleBtn(onTap: onGoogle),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Таб регистрации ───────────────────────────────────────────────────
class _RegisterTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? nameErr;
  final String? emailErr;
  final String? passErr;
  final bool obscure;
  final VoidCallback onToggle;
  final VoidCallback onRegister;
  final VoidCallback onGoogle;
  final bool loading;

  const _RegisterTab({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    this.nameErr,
    this.emailErr,
    this.passErr,
    required this.obscure,
    required this.onToggle,
    required this.onRegister,
    required this.onGoogle,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(text: 'Ваше имя'),
          const SizedBox(height: 8),
          _InputField(
            controller: nameController,
            hint: 'Введите ваше имя',
            error: nameErr,
          ),
          const SizedBox(height: 20),
          const _Label(text: 'Ваш Email'),
          const SizedBox(height: 8),
          _InputField(
            controller: emailController,
            hint: 'Введите ваш Email',
            keyboardType: TextInputType.emailAddress,
            error: emailErr,
          ),
          const SizedBox(height: 20),
          const _Label(text: 'Пароль'),
          const SizedBox(height: 8),
          _InputField(
            controller: passwordController,
            hint: 'Придумайте пароль (мин. 6 символов)',
            obscure: obscure,
            error: passErr,
            suffix: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _GradBtn(
            label: loading ? 'Загрузка...' : 'Зарегистрироваться',
            onTap: loading ? null : onRegister,
          ),
          const SizedBox(height: 24),
          const _OrDivider(),
          const SizedBox(height: 24),
          _GoogleBtn(onTap: onGoogle),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Общие виджеты ─────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? error;

  const _InputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? const Color(0xFFFF4444) : AppColors.border,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: AppTextStyles.bodyL.copyWith(
              color: hasError ? const Color(0xFFFF4444) : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyL.copyWith(
                color: AppColors.textHint,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: suffix != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: suffix,
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFFF4444),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _GradBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GradBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  begin: Alignment(-0.00, 1.00),
                  end: Alignment(1.00, 0.04),
                  colors: [
                    Color(0xFFF16001),
                    Color(0xFFC10801),
                    Color(0xFF3A0000),
                  ],
                )
              : null,
          color: onTap == null ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: Text(label, style: AppTextStyles.button)),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'или',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _GoogleBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'G',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Войти через Google',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
