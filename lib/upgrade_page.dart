import 'dart:async';

import 'package:flutter/material.dart';

import 'purchases/purchase_controller.dart';

/// Store purchase screen. App-wide feature gating is intentionally left to the
/// caller so the controller can be integrated with the navigation flow.
class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key, required this.controller});

  final PurchaseController controller;

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _authBusy = false;
  String? _authMessage;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Unlock full diagnostics')),
    body: SafeArea(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  size: 68,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'One-time unlock',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlock advanced motorcycle diagnostics with a single purchase through your device’s app store.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                _accountPanel(context),
                const SizedBox(height: 12),
                if (widget.controller.product case final product?)
                  Card(
                    child: ListTile(
                      title: Text(product.title),
                      subtitle: Text(product.description),
                      trailing: Text(
                        product.price,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                if (widget.controller.hasUnlock)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.verified_outlined),
                      title: Text('Purchase verified'),
                      subtitle: Text(
                        'The store and server confirmed this unlock.',
                      ),
                    ),
                  ),
                if (widget.controller.message case final message?) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                      onPressed: widget.controller.canPurchase
                      ? () => unawaited(widget.controller.buy())
                      : null,
                  icon: _progressIcon(widget.controller.phase),
                  label: Text(
                    _purchaseLabel(
                      widget.controller.phase,
                      widget.controller.product?.price,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed:
                          widget.controller.isAuthenticated &&
                              widget.controller.isConfigured &&
                          widget.controller.storeAvailable &&
                          widget.controller.phase != PurchasePhase.verifying
                      ? () => unawaited(widget.controller.restorePurchases())
                      : null,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore purchases'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => unawaited(widget.controller.retry()),
                  child: const Text('Retry store and server check'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Purchases are verified with the app store and this app’s secure server. You need an internet connection to restore or verify access.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _accountPanel(BuildContext context) {
    if (widget.controller.isAuthenticated) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Signed in'),
          subtitle: Text(widget.controller.userEmail ?? ''),
          trailing: TextButton(
            onPressed: _authBusy
                ? null
                : () async {
                    setState(() => _authBusy = true);
                    try {
                      await widget.controller.signOut();
                      _codeSent = false;
                      _authMessage = 'Signed out.';
                    } catch (_) {
                      _authMessage = 'Could not sign out from the server. Try again online.';
                    } finally {
                      if (mounted) setState(() => _authBusy = false);
                    }
                  },
            child: const Text('Sign out'),
          ),
        ),
      );
    }
    if (!widget.controller.canAuthenticate) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Account sign-in unavailable'),
          subtitle: Text('This build has no configured secure account service.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sign in to purchase or restore',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'A verified email links your purchase to a recoverable account. Your store purchase is still verified separately.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (!_codeSent)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  border: OutlineInputBorder(),
                ),
              )
            else ...[
              Text('Enter the code sent to ${_emailController.text.trim()}.'),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Six-digit code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_authMessage != null) ...[
              const SizedBox(height: 8),
              Text(_authMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _authBusy
                  ? null
                  : () => unawaited(_sendOrVerifyCode()),
              child: Text(_authBusy
                  ? 'Please wait…'
                  : _codeSent
                      ? 'Verify email'
                      : 'Send sign-in code'),
            ),
            if (_codeSent)
              TextButton(
                onPressed: _authBusy
                    ? null
                    : () => setState(() {
                          _codeSent = false;
                          _codeController.clear();
                          _authMessage = null;
                        }),
                child: const Text('Use a different email'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOrVerifyCode() async {
    setState(() {
      _authBusy = true;
      _authMessage = null;
    });
    try {
      if (!_codeSent) {
        final email = _emailController.text.trim();
        if (!email.contains('@')) {
          setState(() => _authMessage = 'Enter a valid email address.');
          return;
        }
        await widget.controller.requestEmailOtp(email);
        setState(() => _codeSent = true);
      } else {
        await widget.controller.verifyEmailOtp(
          _emailController.text.trim(),
          _codeController.text.trim(),
        );
        setState(() {
          _codeSent = false;
          _codeController.clear();
          _authMessage = 'Account verified.';
        });
      }
    } catch (_) {
      setState(() => _authMessage = 'Account verification failed. Check the email or code and try again.');
    } finally {
      if (mounted) setState(() => _authBusy = false);
    }
  }

  Widget _progressIcon(PurchasePhase phase) => switch (phase) {
    PurchasePhase.purchasing ||
    PurchasePhase.pending ||
    PurchasePhase.verifying ||
    PurchasePhase.checking => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    _ => const Icon(Icons.lock_open),
  };

  String _purchaseLabel(PurchasePhase phase, String? price) => switch (phase) {
    PurchasePhase.purchasing => 'Opening store…',
    PurchasePhase.pending => 'Payment pending',
    PurchasePhase.verifying || PurchasePhase.checking => 'Verifying…',
    PurchasePhase.unlocked => 'Unlocked',
    _ when price != null => 'Unlock for $price',
    _ => 'Purchase unavailable',
  };
}
