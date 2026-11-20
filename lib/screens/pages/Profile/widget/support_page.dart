import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  final String whatsAppDisplay;
  final String email;
  final String investorId;
  final VoidCallback onOpenWhatsApp;
  final VoidCallback onOpenEmail;
  final VoidCallback onCopyWhatsApp;
  final VoidCallback onCopyEmail;

  const SupportPage({
    super.key,
    required this.whatsAppDisplay,
    required this.email,
    required this.investorId,
    required this.onOpenWhatsApp,
    required this.onOpenEmail,
    required this.onCopyWhatsApp,
    required this.onCopyEmail,
  });

  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _dark = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _bgSoft = Color(0xFFF8FAFC);
  static const Color _emerald = Color(0xFF059669);

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
          'Help & Support',
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Support Channels',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Connect directly via WhatsApp or Email',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp Channel Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bgSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'WhatsApp',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  whatsAppDisplay,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _emerald,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: onCopyWhatsApp,
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 17,
                                color: _muted,
                              ),
                              tooltip: 'Copy WhatsApp number',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: onOpenWhatsApp,
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text(
                            'Chat on WhatsApp',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Email Channel Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bgSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email Support',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _dark,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: onCopyEmail,
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 17,
                                color: _muted,
                              ),
                              tooltip: 'Copy email',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: onOpenEmail,
                          icon: const Icon(Icons.mail_outline, size: 16),
                          label: const Text(
                            'Send Email',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
