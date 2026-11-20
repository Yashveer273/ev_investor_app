import 'package:flutter/material.dart';
import '../components/profile_model.dart';

class ProfileBankCard extends StatelessWidget {
  final BankPayoutDetailsModel bankDetails;
  final VoidCallback onEditTap;

  const ProfileBankCard({
    super.key,
    required this.bankDetails,
    required this.onEditTap,
  });

  static const Color _dark = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _bgSoft = Color(0xFFF8FAFC);
  static const Color _emerald = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final bool hasDetails = bankDetails.hasBankDetails;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank & Payout Account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Used for monthly asset return payouts',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onEditTap,
                icon: Icon(
                  hasDetails ? Icons.edit_outlined : Icons.add,
                  size: 15,
                  color: _dark,
                ),
                label: Text(
                  hasDetails ? 'Update' : 'Add',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: _bgSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: _border),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: !hasDetails
                ? const Text(
                    'No bank account or UPI ID saved yet. Tap Update to add payout details.',
                    style: TextStyle(fontSize: 12, color: _muted),
                  )
                : Column(
                    children: [
                      _row('Account Holder', bankDetails.accountHolderName),
                      if (bankDetails.bankName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _row('Bank Name', bankDetails.bankName),
                      ],
                      if (bankDetails.accountNumber.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _row('Account Number', bankDetails.maskedAccountNumber),
                      ],
                      if (bankDetails.ifscCode.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _row('IFSC Code', bankDetails.ifscCode),
                      ],
                      if (bankDetails.upiId.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _row('UPI ID', bankDetails.upiId, accent: true),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool accent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accent ? _emerald : _dark,
          ),
        ),
      ],
    );
  }
}
