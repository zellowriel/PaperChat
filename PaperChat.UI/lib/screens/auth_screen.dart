import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/app_theme.dart';
import '../widgets/common.dart';
import '../viewmodels/app_view_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AppViewModel controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.controller.login(
        _email.text,
        _password.text,
        remember: _remember,
      );
    } on AppException catch (error) {
      if (mounted) showAppMessage(context, error.message, isError: true);
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBlue,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.primary,
                                size: 25,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'PAPERCHAT AI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 6),
                              Text('Research Suite'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Chào mừng trở lại',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Truy cập kho tài liệu nghiên cứu và trợ lý AI học thuật của bạn',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0B172554),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Email trường đại học / Cơ quan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '.edu  /  .ac',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                                hintText: 'tencuaban@university.edu.vn',
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty || !text.contains('@')) {
                                  return 'Vui lòng nhập email hợp lệ.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Mật khẩu',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _password,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                hintText: 'Nhập mật khẩu',
                                suffixIcon: IconButton(
                                  tooltip: _showPassword
                                      ? 'Ẩn mật khẩu'
                                      : 'Hiện mật khẩu',
                                  onPressed: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) => (value?.isEmpty ?? true)
                                  ? 'Vui lòng nhập mật khẩu.'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  value: _remember,
                                  onChanged: (value) => setState(
                                    () => _remember = value ?? false,
                                  ),
                                  activeColor: AppColors.primary,
                                ),
                                const Expanded(
                                  child: Text('Ghi nhớ đăng nhập'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LoadingButton(
                              label: 'Đăng nhập',
                              icon: Icons.arrow_forward_rounded,
                              loading: _loading,
                              onPressed: _login,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.line)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'TẠO TÀI KHOẢN',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.line)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RegisterScreen(controller: widget.controller),
                          ),
                        ),
                        icon: const Icon(Icons.school_outlined),
                        label: const Text('Đăng ký tài khoản PaperChat'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Bằng việc đăng nhập, bạn đồng ý với điều khoản dịch vụ và chính sách bảo mật của PaperChat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          color: AppColors.muted,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 17,
                            color: AppColors.muted,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Kết nối bảo mật bằng HTTPS và xác thực JWT',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.controller});
  final AppViewModel controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.controller.register(
        email: _email.text,
        password: _password.text,
        fullName: _name.text,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        showAppMessage(
          context,
          'Tài khoản đã được tạo. Hãy xác minh email trước khi đăng nhập.',
        );
      }
    } on AppException catch (error) {
      if (mounted) showAppMessage(context, error.message, isError: true);
    } catch (error) {
      if (mounted) showAppMessage(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 46,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  'Tham gia PaperChat',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Vui lòng nhập họ tên.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (!text.contains('@')) return 'Email không hợp lệ.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu (ít nhất 8 ký tự)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) < 8
                      ? 'Mật khẩu phải có ít nhất 8 ký tự.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nhập lại mật khẩu',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) => value != _password.text
                      ? 'Mật khẩu xác nhận không khớp.'
                      : null,
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  label: 'Tạo tài khoản',
                  loading: _busy,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
