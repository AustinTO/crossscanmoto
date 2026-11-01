import 'package:flutter/material.dart';
import 'diagnostic_session.dart';

const _ink = Color(0xFF080A0B);
const _panel = Color(0xFF13181B);
const _lime = Color(0xFFBCEB58);
const _muted = Color(0xFF929B9B);
const _edge = Color(0xFF293133);

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  bool _useMetric = true;
  String? _activeModal;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpCodeSent = false;
  bool _otpBusy = false;
  String? _otpStatusMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_activeModal != null) {
      setState(() => _activeModal = null);
      return;
    }
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
      backgroundColor: _ink,
      appBar: AppBar(
        backgroundColor: _panel,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Preferences & Legal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _handleBack,
        ),
      ),
      body: Stack(
        children: [
          _buildPreferencesBody(context),
          if (_activeModal != null) _buildModalOverlay(context),
        ],
      ),
    ));
  }

  Widget _buildPreferencesBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('WORKSHOP & DISPLAY'),
          _buildCard(
            children: [
              _buildRow(
                icon: Icons.language,
                title: 'Diagnostic Language',
                subtitle: 'English (US) • BMW Factory DTC Catalog',
              ),
              const Divider(height: 1, color: _edge, indent: 16, endIndent: 16),
              _buildRow(
                icon: Icons.straighten,
                title: 'Measurement Units',
                subtitle: _useMetric
                    ? 'Metric (km, °C, bar, km/h)'
                    : 'Imperial (mi, °F, psi, mph)',
                trailing: Switch(
                  value: _useMetric,
                  activeThumbColor: _lime,
                  onChanged: (val) => setState(() => _useMetric = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('CLOUD ACCOUNT & SYNC'),
          _buildCard(
            children: [
              _buildRow(
                icon: Icons.cloud_sync_outlined,
                title: 'Link Account & Cloud Sync',
                subtitle: 'Sync purchases & vehicle backups across devices (Optional)',
                trailing: GestureDetector(
                  onTap: () => setState(() {
                    _activeModal = 'otp';
                    _otpStatusMessage = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E282A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _lime.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'Sign In / Link',
                      style: TextStyle(color: _lime, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('LEGAL, PRIVACY & SAFETY'),
          _buildCard(
            children: [
              _buildRow(
                icon: Icons.info_outline,
                title: 'About CrossScan Moto',
                subtitle: 'CrossScan Moto v2.0.0-PRO • Puphr LLC',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.white54),
                onTap: () => setState(() => _activeModal = 'about'),
              ),
              const Divider(height: 1, color: _edge, indent: 16, endIndent: 16),
              _buildRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Puphr LLC • Zero Telemetry Tracking',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.white54),
                onTap: () => setState(() => _activeModal = 'privacy'),
              ),
              const Divider(height: 1, color: _edge, indent: 16, endIndent: 16),
              _buildRow(
                icon: Icons.description_outlined,
                title: 'Terms of Service & Safety',
                subtitle: 'Workshop stationary safety rules',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.white54),
                onTap: () => setState(() => _activeModal = 'terms'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('ACCOUNT & DATA MANAGEMENT'),
          _buildCard(
            children: [
              _buildRow(
                icon: Icons.delete_forever_outlined,
                iconColor: const Color(0xFFF85149),
                title: 'Delete Account & Stored Data',
                titleColor: const Color(0xFFF85149),
                subtitle: 'Purge server UUID, entitlements, and local diagnostic records',
                trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFF85149)),
                onTap: () => setState(() => _activeModal = 'delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _edge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? _lime, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          color: _muted,
        ),
      ),
    );
  }

  Widget _buildModalOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _activeModal = null),
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: GestureDetector(
          onTap: () {}, // Prevent dismissal when tapping inside dialog card
          child: Material(
            color: _panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: _edge),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: _buildModalContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalContent(BuildContext context) {
    switch (_activeModal) {
      case 'about':
        return _buildAboutModal();
      case 'privacy':
        return _buildPrivacyModal();
      case 'terms':
        return _buildTermsModal();
      case 'delete':
        return _buildDeleteModal();
      case 'otp':
        return _buildOtpModal();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAboutModal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.two_wheeler, color: _lime, size: 26),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CrossScan Moto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'CrossScan Moto v2.0.0-PRO • Puphr LLC',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => setState(() => _activeModal = null),
            ),
          ],
        ),
        const Divider(height: 24, color: _edge),
        const Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CrossScan Moto is an independent professional diagnostics, service reset, live telemetry, and vehicle coding solution developed by Puphr LLC for BMW Motorrad enthusiasts and technicians.',
                  style: TextStyle(fontSize: 13, height: 1.45, color: Colors.white70),
                ),
                SizedBox(height: 14),
                Text(
                  'Supported Subsystems:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
                SizedBox(height: 6),
                Text(
                  '• ISO 14229 UDS over D-CAN / CAN Bus (500 kbps)\n'
                  '• ISO 14230 KWP2000 over K-Line (Fast & 5-Baud Init)\n'
                  '• 24-bit BMW Factory DTC Database & Status Mask Decoding\n'
                  '• High-Speed Multi-Parameter Live Telemetry Registry\n'
                  '• Service Resets, Brake Fluid & Adaptation Calibrations\n'
                  '• Bi-Directional Actuator Output Testing\n'
                  '• Vehicle Order & Coding Option Customization',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _lime,
            foregroundColor: Colors.black,
          ),
          onPressed: () => setState(() => _activeModal = null),
          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPrivacyModal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.privacy_tip_outlined, color: _lime, size: 26),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Puphr LLC • Privacy Commitment',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => setState(() => _activeModal = null),
            ),
          ],
        ),
        const Divider(height: 24, color: _edge),
        const Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Zero Vehicle Telemetry: CrossScan Moto processes all ECU readings, trouble codes, and sensor data locally on your device. Puphr LLC never logs, collects, or sells vehicle diagnostics.\n\n'
                  '• Anonymous In-App Purchases: Digital purchases use an anonymous random UUID stored securely in device Keychain/EncryptedStorage. No passwords, emails, or personal identities are required.\n\n'
                  '• Cloudflare D1 Backend: Server-stored receipt verification hashes are protected with TLS 1.3 and SHA-256 replay prevention.\n\n'
                  '• Instant Deletion: You can delete your anonymous account token and all backend entitlement records at any time.\n\n'
                  'Contact: privacy@puphr.com • support@puphr.com',
                  style: TextStyle(fontSize: 12.5, height: 1.45, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _lime,
            foregroundColor: Colors.black,
          ),
          onPressed: () => setState(() => _activeModal = null),
          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTermsModal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, color: _lime, size: 26),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms of Service',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Puphr LLC • Workshop Operating Agreement',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => setState(() => _activeModal = null),
            ),
          ],
        ),
        const Divider(height: 24, color: _edge),
        const Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRITICAL WORKSHOP SAFETY RULES:\n\n'
                  '1. Stationary Interlock: Diagnostic actuations (fuel pump, cooling fan, ABS valve cycling, exhaust flap) must ONLY be triggered when the motorcycle is parked, stationary on a secure stand (center stand or paddock stand), in a well-ventilated workshop.\n\n'
                  '2. Riding Prohibition: NEVER operate or interact with the diagnostic interface while riding.\n\n'
                  '3. Limitation of Liability: CrossScan Moto is provided "AS IS". Puphr LLC is not responsible for vehicle damage, mechanical wear, or voided warranties resulting from improper workshop maintenance or unauthorized coding.',
                  style: TextStyle(fontSize: 12.5, height: 1.45, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _lime,
            foregroundColor: Colors.black,
          ),
          onPressed: () => setState(() => _activeModal = null),
          child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDeleteModal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.delete_forever_outlined, color: Color(0xFFF85149), size: 26),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Account & Data?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => setState(() => _activeModal = null),
            ),
          ],
        ),
        const Divider(height: 24, color: _edge),
        const Text(
          'This action permanently purges your anonymous account UUID, purchase verification records, and feature entitlements from Puphr LLC\'s Cloudflare database and wipes all local cached diagnostic data.\n\n'
          'This action is irreversible.',
          style: TextStyle(fontSize: 13, height: 1.45, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: _edge),
                ),
                onPressed: () => setState(() => _activeModal = null),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF85149),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  setState(() => _activeModal = null);
                  await DiagnosticSession.instance.purchases.deleteAccountAndData();
                  DiagnosticSession.instance.record('Account and stored diagnostic records purged');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account data successfully deleted from Puphr LLC servers and local storage.'),
                        backgroundColor: Color(0xFF1E2628),
                      ),
                    );
                  }
                },
                child: const Text('Delete Permanently'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpModal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.mail_lock_outlined, color: _lime, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _otpCodeSent ? 'Enter Verification Code' : 'Link Workshop Account',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => setState(() => _activeModal = null),
            ),
          ],
        ),
        const Divider(height: 24, color: _edge),
        Text(
          _otpCodeSent
              ? 'Enter the 6-digit verification code sent from noreply@auth.trusthentic.com to ${_emailController.text}:'
              : 'Enter your email address to receive a secure 6-digit login code. This optionally links your account for cross-platform purchases and cloud backups.',
          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
        ),
        const SizedBox(height: 16),
        if (!_otpCodeSent)
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'rider@email.com',
              prefixIcon: const Icon(Icons.email_outlined, color: _lime),
              filled: true,
              fillColor: const Color(0xFF101518),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            autofocus: true,
            maxLength: 6,
            style: const TextStyle(
              color: _lime,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '123456',
              counterText: '',
              filled: true,
              fillColor: const Color(0xFF101518),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        if (_otpStatusMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _otpStatusMessage!,
            style: TextStyle(
              fontSize: 12.5,
              color: _otpStatusMessage!.contains('Error') || _otpStatusMessage!.contains('failed')
                  ? const Color(0xFFF85149)
                  : _lime,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: _edge),
                ),
                onPressed: _otpBusy ? null : () => setState(() => _activeModal = null),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: Colors.black,
                ),
                onPressed: _otpBusy
                    ? null
                    : () async {
                        if (!_otpCodeSent) {
                          final email = _emailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            setState(() => _otpStatusMessage = 'Please enter a valid email address.');
                            return;
                          }
                          setState(() {
                            _otpBusy = true;
                            _otpStatusMessage = 'Sending verification code via auth.trusthentic.com…';
                          });
                          try {
                            await DiagnosticSession.instance.purchases.requestEmailOtp(email);
                            setState(() {
                              _otpBusy = false;
                              _otpCodeSent = true;
                              _otpStatusMessage = null;
                            });
                          } catch (e) {
                            setState(() {
                              _otpBusy = false;
                              _otpStatusMessage = 'Request failed: ${e.toString().replaceAll('PurchaseBackendException', '')}';
                            });
                          }
                        } else {
                          final otp = _otpController.text.trim();
                          if (otp.length != 6) {
                            setState(() => _otpStatusMessage = 'Enter the full 6-digit code.');
                            return;
                          }
                          setState(() {
                            _otpBusy = true;
                            _otpStatusMessage = 'Verifying code…';
                          });
                          try {
                            await DiagnosticSession.instance.purchases.verifyEmailOtp(
                              _emailController.text.trim(),
                              otp,
                            );
                            setState(() {
                              _otpBusy = false;
                              _activeModal = null;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Linked account: ${_emailController.text.trim()}'),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              _otpBusy = false;
                              _otpStatusMessage = 'Verification failed: ${e.toString().replaceAll('PurchaseBackendException', '')}';
                            });
                          }
                        }
                      },
                child: Text(
                  _otpCodeSent ? 'Verify & Link' : 'Send Code',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
