import 'package:flutter/material.dart';

import '../models/local_account.dart';
import '../services/nutrimate_api.dart';
import '../utils/app_colors.dart';

enum _AuthPage { landing, welcome, signIn, createAccount }

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({
    required this.api,
    required this.onAccountOpened,
    super.key,
  });

  final NutriMateApi api;
  final Future<void> Function(LocalAccount) onAccountOpened;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  _AuthPage _page = _AuthPage.landing;
  String? _error;
  bool _showPassword = false;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final account = _page == _AuthPage.signIn
          ? await widget.api.login(_email.text, _password.text)
          : await widget.api.register(
              name: _name.text,
              email: _email.text,
              password: _password.text,
            );
      await widget.onAccountOpened(account);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showPasswordRecovery() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot password?'),
        content: Text(
          _email.text.trim().isEmpty
              ? 'Enter your email in the sign-in form. Password recovery is not enabled on this server yet.'
              : 'Password recovery for ${_email.text.trim()} needs an email delivery service, which is not configured yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: null,
            child: const Text('Send reset link · unavailable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_page == _AuthPage.landing) return _buildLanding(context);
    if (_page == _AuthPage.welcome) return _buildWelcome(context);
    return _buildForm(context);
  }

  Widget _buildLanding(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6DDFF), Color(0xFFE9ECFF), Color(0xFFF7F8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size.width * .18,
              right: -size.width * .18,
              child: _GlowCircle(size: size.width * .62),
            ),
            Positioned(
              bottom: -size.width * .23,
              left: -size.width * .2,
              child: _GlowCircle(size: size.width * .72, blue: true),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      children: [
                        const _BrandMark(),
                        const SizedBox(height: 28),
                        _LandingArtwork(height: size.height * .38),
                        const SizedBox(height: 25),
                        const Text(
                          'Nourish your\nbest self.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF17296E),
                            fontSize: 38,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'A little more mindful with every meal.\nBuild healthy habits, one day at a time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF65719A),
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: () =>
                                setState(() => _page = _AuthPage.welcome),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF253BA2),
                              elevation: 5,
                              shadowColor: const Color(0xFF253BA2)
                                  .withValues(alpha: .23),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Get started',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        TextButton(
                          onPressed: () =>
                              setState(() => _page = _AuthPage.signIn),
                          child: const Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: Color(0xFF69749A),
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(
                                    color: Color(0xFF253BA2),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'PERSONAL NUTRITION · MADE SIMPLE',
                          style: TextStyle(
                            color: Color(0xFF8790B0),
                            fontSize: 9,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => setState(() => _page = _AuthPage.landing),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4E8FF), Color(0xFFF7F8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: wide
                    ? Row(
                        children: [
                          Expanded(child: _welcomeCopy()),
                          const SizedBox(width: 42),
                          SizedBox(width: 360, child: _welcomeActions()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _welcomeCopy(),
                          const SizedBox(height: 28),
                          _welcomeActions(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeCopy() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _BrandMark(),
      const SizedBox(height: 30),
      const _LocalDataPill(),
      const SizedBox(height: 19),
      const Text(
        'Healthy choices.\nA better tomorrow.',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 38,
          height: 1.1,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'Explore your meals, daily nutrients, hydration, and progress in one friendly nutrition workspace.',
        style: TextStyle(color: Color(0xFF5E7285), fontSize: 15, height: 1.55),
      ),
      const SizedBox(height: 22),
      const Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          _WelcomeFeature(icon: Icons.restaurant_menu, label: 'Meal journal'),
          _WelcomeFeature(icon: Icons.donut_large, label: 'Nutrient summary'),
          _WelcomeFeature(
            icon: Icons.water_drop_outlined,
            label: 'Water tracker',
          ),
        ],
      ),
    ],
  );

  Widget _welcomeActions() => Card(
    color: Colors.white,
    elevation: 2,
    shadowColor: AppColors.navy.withValues(alpha: .08),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get started',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Create a user account, or sign in. Administrators use the same sign-in.',
            style: TextStyle(
              color: Color(0xFF78869A),
              height: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: FilledButton(
              onPressed: () => setState(() => _page = _AuthPage.createAccount),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Create user account'),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: OutlinedButton(
              onPressed: () => setState(() => _page = _AuthPage.signIn),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: Color(0xFFD8E3E8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Sign in'),
            ),
          ),
          const SizedBox(height: 18),
          const SizedBox(height: 14),
          const _LocalStorageNotice(),
        ],
      ),
    ),
  );

  Widget _buildForm(BuildContext context) {
    final creating = _page == _AuthPage.createAccount;
    return Scaffold(
      backgroundColor: const Color(0xFFD5DDFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF253BA2),
        leading: IconButton(
          onPressed: () => setState(() {
            _page = _AuthPage.welcome;
            _error = null;
          }),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(''),
      ),
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFD5DDFB)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Card(
                  color: Colors.white,
                  elevation: 5,
                  shadowColor: const Color(0xFF253BA2).withValues(alpha: .1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 23, 24, 17),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(child: _FormBrandMark()),
                          const SizedBox(height: 22),
                          Text(
                            creating
                                ? 'Create a user account'
                                : 'Log in to your account',
                            style: const TextStyle(
                              color: Color(0xFF192B70),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            creating
                                ? 'New accounts are regular users. Administrator access is set up on the server.'
                                : 'Users and administrators sign in here with their NutriMate account.',
                            style: const TextStyle(
                              color: Color(0xFF7781A0),
                              height: 1.4,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (creating) ...[
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFFE1E4ED),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFF334BB5),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().length < 2
                                  ? 'Enter at least 2 characters'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFFE1E4ED),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFF334BB5),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty || !email.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFFE1E4ED),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFF334BB5),
                                  width: 1.2,
                                ),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.length < 8) {
                                return 'Use at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEEEE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFB33F42),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 49,
                            child: FilledButton(
                              onPressed: _submitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF253BA2),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      creating
                                          ? 'Create and continue'
                                          : 'Sign in',
                                    ),
                            ),
                          ),
                          if (!creating)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showPasswordRecovery,
                                child: const Text('Forgot password?'),
                              ),
                            )
                          else ...[
                            const SizedBox(height: 7),
                            const OutlinedButton(
                              onPressed: null,
                              child: Text('Verify email · backend required'),
                            ),
                            const TextButton(
                              onPressed: null,
                              child: Text('Resend verification · unavailable'),
                            ),
                          ],
                          const SizedBox(height: 14),
                          const _LocalStorageNotice(),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() {
                                _page = creating
                                    ? _AuthPage.signIn
                                    : _AuthPage.createAccount;
                                _error = null;
                              }),
                              child: Text(
                                creating
                                    ? 'May account ka na? Sign in'
                                    : 'Wala pang account? Create one',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.teal, AppColors.blue],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.eco_outlined, color: Colors.white, size: 27),
      ),
      const SizedBox(width: 11),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NutriMate',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'NUTRITION MONITORING',
            style: TextStyle(
              color: Color(0xFF74879A),
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ],
  );
}

class _FormBrandMark extends StatelessWidget {
  const _FormBrandMark();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF273FA9), Color(0xFF536BE0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF273FA9).withValues(alpha: .2),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 29),
      ),
      const SizedBox(height: 9),
      const Text(
        'NutriMate',
        style: TextStyle(
          color: Color(0xFF192B70),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
        ),
      ),
    ],
  );
}

class _LandingArtwork extends StatelessWidget {
  const _LandingArtwork({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height.clamp(190, 300),
    width: 330,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 226,
          height: 226,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: .82),
                const Color(0xFFCAD3FF).withValues(alpha: .6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Container(
          width: 174,
          height: 174,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF263DA4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF273FA9).withValues(alpha: .22),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 76,
            ),
          ),
        ),
        Positioned(
          top: 23,
          right: 8,
          child: _ArtworkBadge(
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF4C76D8),
            label: 'Stay hydrated',
          ),
        ),
        Positioned(
          bottom: 25,
          left: 0,
          child: _ArtworkBadge(
            icon: Icons.favorite_rounded,
            color: const Color(0xFF31A58F),
            label: 'Feel your best',
          ),
        ),
        Positioned(
          top: 33,
          left: 22,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD76A),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B7A30).withValues(alpha: .16),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: Color(0xFF7C682B),
              size: 27,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ArtworkBadge extends StatelessWidget {
  const _ArtworkBadge({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF293C86).withValues(alpha: .11),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF283568),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, this.blue = false});

  final double size;
  final bool blue;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: blue
            ? [
                const Color(0xFFBFCBFF).withValues(alpha: .8),
                const Color(0xFFBFCBFF).withValues(alpha: 0),
              ]
            : [
                Colors.white.withValues(alpha: .9),
                Colors.white.withValues(alpha: 0),
              ],
      ),
    ),
  );
}

class _LocalDataPill extends StatelessWidget {
  const _LocalDataPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3DD),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'CONNECTED TO NUTRIMATE API',
      style: TextStyle(
        color: Color(0xFF93641B),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: .6,
      ),
    ),
  );
}

class _WelcomeFeature extends StatelessWidget {
  const _WelcomeFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE0EBE8)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.teal),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _LocalStorageNotice extends StatelessWidget {
  const _LocalStorageNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF2E3C5)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: Color(0xFFAA7417)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Account authentication uses the NutriMate API. Your session token is saved on this device; protect your device and never share your password.',
            style: TextStyle(
              color: Color(0xFF805D1A),
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
