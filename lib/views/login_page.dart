// lib/views/login_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

/// Full-page login screen for the Institution Management Portal.
///
/// Renders a centred [Card] (max-width 480 px) containing:
/// - An email [TextFormField] (maxLength 254, emailAddress keyboard)
/// - An Institution ID [TextFormField] (maxLength 128, obscured)
/// - A submit [ElevatedButton] that is disabled while [AuthController.isLoading]
///   and shows a [CircularProgressIndicator] in place of its label
/// - Inline error text below the form driven by [AuthController.errorMessage]
///
/// The form does NOT clear on validation error — [TextEditingController]s are
/// kept alive in [State] so field values survive reactive rebuilds.
///
/// Pressing Enter in either field triggers the login action via
/// [TextInputAction.done] / [onFieldSubmitted].
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ---------------------------------------------------------------------------
  // Controllers & focus nodes
  // ---------------------------------------------------------------------------

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _institutionIdController = TextEditingController();

  final _emailFocus = FocusNode();
  final _institutionIdFocus = FocusNode();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _emailController.dispose();
    _institutionIdController.dispose();
    _emailFocus.dispose();
    _institutionIdFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  AuthController get _controller => Get.find<AuthController>();

  /// Validates the form and, if valid, delegates to [AuthController.login].
  /// Field values are intentionally NOT cleared here — the controller sets
  /// [errorMessage] on failure and the fields remain populated.
  void _submit() {
    // Trigger Flutter form validation (shows inline validator messages)
    _formKey.currentState?.validate();

    // Delegate to AuthController regardless — it performs its own validation
    // and sets errorMessage reactively.
    _controller.login(
      _emailController.text,
      _institutionIdController.text,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // -------------------------------------------------------
                      // Title
                      // -------------------------------------------------------
                      Text(
                        'Institution Portal',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to your institution account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // -------------------------------------------------------
                      // Email field
                      // -------------------------------------------------------
                      TextFormField(
                        key: const Key('emailField'),
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 254,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@institution.edu',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                          counterText: '', // hide the built-in counter
                        ),
                        onFieldSubmitted: (_) {
                          // Move focus to Institution ID field on Enter
                          FocusScope.of(context)
                              .requestFocus(_institutionIdFocus);
                        },
                        // Validator is intentionally lenient here — the
                        // AuthController performs the authoritative check and
                        // surfaces errors via errorMessage.
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // -------------------------------------------------------
                      // Institution ID field
                      // -------------------------------------------------------
                      TextFormField(
                        key: const Key('institutionIdField'),
                        controller: _institutionIdController,
                        focusNode: _institutionIdFocus,
                        maxLength: 128,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Institution ID',
                          hintText: 'Enter your Institution ID',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                          counterText: '', // hide the built-in counter
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Institution ID cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // -------------------------------------------------------
                      // Submit button (reactive to isLoading)
                      // -------------------------------------------------------
                      Obx(() {
                        final loading = _controller.isLoading.value;
                        return ElevatedButton(
                          key: const Key('submitButton'),
                          onPressed: loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Sign In'),
                        );
                      }),

                      // -------------------------------------------------------
                      // Inline error message (reactive to errorMessage)
                      // -------------------------------------------------------
                      Obx(() {
                        final error = _controller.errorMessage.value;
                        if (error == null || error.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            error,
                            key: const Key('errorText'),
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }),
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
