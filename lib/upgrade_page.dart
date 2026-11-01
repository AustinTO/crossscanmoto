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
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
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
                  onPressed: () =>
                      unawaited(widget.controller.refreshEntitlement()),
                  child: const Text('Check purchase status'),
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
