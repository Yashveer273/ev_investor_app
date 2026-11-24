import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/profile_model.dart';

class ProfileHeaderCard extends StatelessWidget {
  final InvestorProfileModel profile;
  final Future<void> Function(String value, String label)? onCopy;

  const ProfileHeaderCard({super.key, required this.profile, this.onCopy});

  static const Color _dark = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _emeraldBg = Color(0xFFD1FAE5);
  static const Color _emeraldText = Color(0xFF065F46);

  Future<void> _handleCopy(
    BuildContext context,
    String value,
    String label,
  ) async {
    final String cleanValue = value.trim();
    if (cleanValue.isEmpty) return;

    if (onCopy != null) {
      await onCopy!(cleanValue, label);
      return;
    }

    await Clipboard.setData(ClipboardData(text: cleanValue));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String rawStatus = profile.kycStatus.trim();
    final String displayStatus = rawStatus.isEmpty ? 'Pending' : rawStatus;
    final String lower = displayStatus.toLowerCase();
    final bool verified = lower == 'verified';
    final bool rejected = lower == 'rejected';

    final Color badgeBg = verified
        ? _emeraldBg
        : rejected
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);
    final Color badgeFg = verified
        ? _emeraldText
        : rejected
        ? const Color(0xFFB91C1C)
        : const Color(0xFF92400E);

    final String formattedPhone = profile.phone.trim().isEmpty
        ? ''
        : '+91 ${profile.phone.trim()}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investor Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Account details & payout settings',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoField('Full Name', profile.fullName)),
              const SizedBox(width: 12),
              Expanded(child: _infoField('Phone Number', formattedPhone)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _infoField('Email Address', profile.email)),
              const SizedBox(width: 12),
              Expanded(child: _investorIdField(context, profile.investorId)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _dark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _investorIdField(BuildContext context, String value) {
    final bool canCopy = value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Investor ID',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _handleCopy(context, value, 'Investor ID'),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.copy_rounded, size: 14, color: _dark),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
