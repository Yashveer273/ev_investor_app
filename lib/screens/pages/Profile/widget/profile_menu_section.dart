import 'package:flutter/material.dart';

class ProfileMenuSection extends StatelessWidget {
  final VoidCallback onPrivacyPolicyTap;
  final VoidCallback onPrivacyFeedbackTap;
  final VoidCallback onSupportTap;
  final VoidCallback onLogoutTap;

  const ProfileMenuSection({
    super.key,
    required this.onPrivacyPolicyTap,
    required this.onPrivacyFeedbackTap,
    required this.onSupportTap,
    required this.onLogoutTap,
  });

  static const Color _dark = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _tile(
            title: 'Privacy Policy',
            subtitle: 'Data & payout privacy terms',
            onTap: onPrivacyPolicyTap,
          ),
          const Divider(height: 1, color: _border),
          _tile(
            title: 'Privacy Policy Feedback',
            subtitle: 'Share questions or privacy feedback',
            onTap: onPrivacyFeedbackTap,
          ),
          const Divider(height: 1, color: _border),
          _tile(
            title: 'Help & Support',
            subtitle: 'WhatsApp & Email assistance',
            onTap: onSupportTap,
          ),
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLogoutTap,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text(
                  'Secure Logout',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFB91C1C),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, size: 18, color: _muted),
          ],
        ),
      ),
    );
  }
}
