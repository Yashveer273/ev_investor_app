import 'package:flutter/material.dart';

class PrivacyFeedbackSheet extends StatefulWidget {
  final Future<bool> Function({required String topic, required String message})
  onSubmit;

  const PrivacyFeedbackSheet({super.key, required this.onSubmit});

  @override
  State<PrivacyFeedbackSheet> createState() => _PrivacyFeedbackSheetState();
}

class _PrivacyFeedbackSheetState extends State<PrivacyFeedbackSheet> {
  static const Color _dark = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _bgSoft = Color(0xFFF8FAFC);

  final List<String> _topics = const [
    'Policy Clarity',
    'Payout Data',
    'Account Info',
    'Other',
  ];
  String _selectedTopic = 'Policy Clarity';
  final TextEditingController _msgCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double inset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Privacy Policy Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _dark,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Share feedback or questions regarding privacy',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topics.map((t) {
                final bool active = _selectedTopic == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTopic = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active ? _dark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : _muted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _msgCtrl,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _dark,
              ),
              decoration: InputDecoration(
                hintText: 'Write your feedback...',
                hintStyle: const TextStyle(fontSize: 12, color: _muted),
                filled: true,
                fillColor: _bgSoft,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _dark),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      final bool ok = await widget.onSubmit(
                        topic: _selectedTopic,
                        message: _msgCtrl.text,
                      );
                      if (!mounted) return;
                      setState(() => _submitting = false);
                      if (ok && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _submitting ? 'Submitting...' : 'Submit Feedback',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
