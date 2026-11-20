import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final VoidCallback onFeedbackTap;

  const PrivacyPolicyPage({super.key, required this.onFeedbackTap});

  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _dark = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _dark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Updated: 20 Nov 2026',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 14),
                  _item(
                    'Information We Collect',
                    'We store your account details, purchased EV asset records, and bank/UPI payout information required for monthly return settlements.',
                  ),
                  _item(
                    'How Information Is Used',
                    'Data is used to show active assets, process renewals, credit returns to your chosen bank or UPI account, and provide support.',
                  ),
                  _item(
                    'Payout & Data Security',
                    'Bank and UPI details are protected with encrypted connections. We never request your banking password, PIN, or OTP.',
                  ),
                  _item(
                    'Updates & Control',
                    'You can update your bank or UPI payout details anytime from your profile or share feedback below.',
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onFeedbackTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _dark,
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Privacy Policy Feedback',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String title, String body, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(fontSize: 12, height: 1.45, color: _muted),
          ),
        ],
      ),
    );
  }
}
