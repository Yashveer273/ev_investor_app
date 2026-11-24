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
  static const Color _logoutFill = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                title: 'Feedback',
                subtitle: 'Share questions or feedback',
                onTap: onPrivacyFeedbackTap,
              ),
              const Divider(height: 1, color: _border),
              _tile(
                title: 'Help & Support',
                subtitle: 'WhatsApp & Email assistance',
                onTap: onSupportTap,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: onLogoutTap,
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _logoutFill,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              minimumSize: const Size(0, 42),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
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
