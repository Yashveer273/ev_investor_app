import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../components/app_button.dart';
import '../components/profile_model.dart';

class ProfileBankEditSheet extends StatefulWidget {
  final BankPayoutDetailsModel initialDetails;
  final Future<bool> Function({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    required String upiId,
  })
  onSave;

  const ProfileBankEditSheet({
    super.key,
    required this.initialDetails,
    required this.onSave,
  });

  @override
  State<ProfileBankEditSheet> createState() => _ProfileBankEditSheetState();
}

class _ProfileBankEditSheetState extends State<ProfileBankEditSheet> {
  late final TextEditingController _holderCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountCtrl;
  late final TextEditingController _ifscCtrl;
  late final TextEditingController _upiCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _holderCtrl = TextEditingController(
      text: widget.initialDetails.accountHolderName,
    );
    _bankNameCtrl = TextEditingController(text: widget.initialDetails.bankName);
    _accountCtrl = TextEditingController(
      text: widget.initialDetails.accountNumber,
    );
    _ifscCtrl = TextEditingController(text: widget.initialDetails.ifscCode);
    _upiCtrl = TextEditingController(text: widget.initialDetails.upiId);
  }

  @override
  void dispose() {
    _holderCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputStyle(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update Bank & Payout Details', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(
              'Enter your bank account or UPI ID to receive monthly asset returns.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _holderCtrl,
              maxLength: 30,
              decoration: _inputStyle(
                'Account Holder Name',
                'Enter full name as per bank',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bankNameCtrl,
              maxLength: 30,
              decoration: _inputStyle('Bank Name', 'e.g. State Bank of India'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accountCtrl,
              keyboardType: TextInputType.number,
              maxLength: 30,
              decoration: _inputStyle(
                'Account Number',
                'Enter bank account number',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ifscCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 30,
              decoration: _inputStyle('IFSC Code', 'e.g. SBIN0001234'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _upiCtrl,
              maxLength: 30,
              decoration: _inputStyle('UPI ID (Optional)', 'e.g. name@upi'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    type: AppButtonType.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: _saving ? 'Saving...' : 'Save Details',
                    type: AppButtonType.primary,
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            final bool ok = await widget.onSave(
                              accountHolderName: _holderCtrl.text,
                              accountNumber: _accountCtrl.text,
                              ifscCode: _ifscCtrl.text,
                              bankName: _bankNameCtrl.text,
                              upiId: _upiCtrl.text,
                            );
                            if (!mounted) return;
                            setState(() => _saving = false);
                            if (ok && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
