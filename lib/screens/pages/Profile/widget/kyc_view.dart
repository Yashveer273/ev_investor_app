import 'dart:io';
import 'dart:typed_data';
import 'package:ev_investors_app/screens/pages/Profile/components/profile_controller.dart';
import 'package:ev_investors_app/screens/pages/Profile/components/profile_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../components/app_button.dart';

class ProfileKycSheet extends StatefulWidget {
  final InvestorProfileModel initialProfile;
  final Future<bool> Function({
    required String fullNameAsPerPan,
    required String panNumber,
    required String aadhaarNumber,
    required String dob,
    required String address,
    File? panImage,
    File? aadhaarImage,
    XFile? panXFile,
    XFile? aadhaarXFile,
  })
  onSubmit;

  const ProfileKycSheet({
    super.key,
    required this.initialProfile,
    required this.onSubmit,
  });

  static Future<void> show({
    required BuildContext context,
    required InvestorProfileModel initialProfile,
    required Future<bool> Function({
      required String fullNameAsPerPan,
      required String panNumber,
      required String aadhaarNumber,
      required String dob,
      required String address,
      File? panImage,
      File? aadhaarImage,
      XFile? panXFile,
      XFile? aadhaarXFile,
    })
    onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return ProfileKycSheet(
          initialProfile: initialProfile,
          onSubmit: onSubmit,
        );
      },
    );
  }

  @override
  State<ProfileKycSheet> createState() => _ProfileKycSheetState();
}

class _ProfileKycSheetState extends State<ProfileKycSheet> {
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _dark = Color(0xFF0F172A);

  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _panCtrl;
  late final TextEditingController _aadhaarCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _addressCtrl;

  XFile? _panXFile;
  XFile? _aadhaarXFile;
  Uint8List? _panBytes;
  Uint8List? _aadhaarBytes;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final KycDetailsModel kyc = widget.initialProfile.kyc;
    _nameCtrl = TextEditingController(
      text: kyc.fullNameAsPerPan.isNotEmpty
          ? kyc.fullNameAsPerPan
          : widget.initialProfile.fullName,
    );
    _panCtrl = TextEditingController(text: kyc.panNumber);
    _aadhaarCtrl = TextEditingController(text: kyc.aadhaarNumber);
    _dobCtrl = TextEditingController(text: kyc.dob);
    _addressCtrl = TextEditingController(
      text: kyc.address.isNotEmpty ? kyc.address : widget.initialProfile.city,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _panCtrl.dispose();
    _aadhaarCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool _pickingImage = false;

  Future<void> _pickDocImage({required bool isPan}) async {
    if (_pickingImage) return;
    _pickingImage = true;

    try {
      final ImageSource? source = kIsWeb
          ? ImageSource.gallery
          : await showModalBottomSheet<ImageSource>(
              context: context,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (BuildContext ctx) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.photo_camera_rounded,
                          color: _dark,
                        ),
                        title: const Text('Take Photo'),
                        onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.photo_library_rounded,
                          color: _dark,
                        ),
                        title: const Text('Choose from Gallery'),
                        onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                      ),
                    ],
                  ),
                );
              },
            );

      if (source == null || !mounted) return;

      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 82,
      );
      if (picked == null || !mounted) return;

      final Uint8List bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        if (isPan) {
          _panXFile = picked;
          _panBytes = bytes;
        } else {
          _aadhaarXFile = picked;
          _aadhaarBytes = bytes;
        }
      });
    } catch (e) {
      debugPrint('Image pick error: $e');
    } finally {
      _pickingImage = false;
    }
  }

  InputDecoration _inputStyle(String label, String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  Widget _buildPickedPreview(XFile xFile, Uint8List? bytes, String title) {
    if (bytes != null && bytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _placeholder(title),
        ),
      );
    }

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          xFile.path,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _placeholder(title),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(xFile.path),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(title),
      ),
    );
  }

  Widget _photoUploadBox({
    required String title,
    required XFile? pickedFile,
    required Uint8List? pickedBytes,
    required String existingUrl,
    required VoidCallback onTap,
  }) {
    final bool hasPicked = pickedFile != null;
    final bool hasRemote = existingUrl.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: hasPicked
            ? _buildPickedPreview(pickedFile, pickedBytes, title)
            : hasRemote
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  existingUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => _placeholder(title),
                ),
              )
            : _placeholder(title),
      ),
    );
  }

  Widget _placeholder(String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.upload_file_rounded, size: 22, color: _dark),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _dark,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Tap to upload',
          style: TextStyle(fontSize: 10, color: _muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final KycDetailsModel existingKyc = widget.initialProfile.kyc;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KYC Verification', style: AppTextStyles.h3),
                _KycStatusBadge(status: widget.initialProfile.kycStatus),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enter PAN & Aadhaar numbers and upload clear document photos.',
              style: AppTextStyles.caption,
            ),
            if (existingKyc.remarks.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  'Remarks: ${existingKyc.remarks.trim()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              maxLength: 80,
              decoration: _inputStyle(
                'Full Name (as per PAN)',
                'Enter full name',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _panCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                _UpperCaseInputFormatter(),
              ],
              decoration: _inputStyle('PAN Number', 'e.g. ABCDE1234F'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _aadhaarCtrl,
              keyboardType: TextInputType.number,
              maxLength: 12,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputStyle(
                'Aadhaar Number',
                '12-digit Aadhaar number',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _photoUploadBox(
                    title: 'PAN Card Photo',
                    pickedFile: _panXFile,
                    pickedBytes: _panBytes,
                    existingUrl: existingKyc.panImageUrl,
                    onTap: () => _pickDocImage(isPan: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _photoUploadBox(
                    title: 'Aadhaar Card Photo',
                    pickedFile: _aadhaarXFile,
                    pickedBytes: _aadhaarBytes,
                    existingUrl: existingKyc.aadhaarImageUrl,
                    onTap: () => _pickDocImage(isPan: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dobCtrl,
              readOnly: true,
              onTap: () async {
                final DateTime now = DateTime.now();
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(now.year - 22, now.month, now.day),
                  firstDate: DateTime(1950, 1, 1),
                  lastDate: DateTime(now.year - 18, now.month, now.day),
                );
                if (picked != null) {
                  final String mm = picked.month.toString().padLeft(2, '0');
                  final String dd = picked.day.toString().padLeft(2, '0');
                  _dobCtrl.text = '${picked.year}-$mm-$dd';
                }
              },
              decoration: _inputStyle(
                'Date of Birth',
                'YYYY-MM-DD',
                suffixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: _muted,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: _inputStyle(
                'Residential Address',
                'House/Street, Locality, City, State, PIN',
              ),
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
                    label: _submitting ? 'Submitting...' : 'Submit KYC',
                    type: AppButtonType.primary,
                    onPressed: _submitting
                        ? null
                        : () async {
                            setState(() => _submitting = true);
                            final bool ok = await widget.onSubmit(
                              fullNameAsPerPan: _nameCtrl.text,
                              panNumber: _panCtrl.text,
                              aadhaarNumber: _aadhaarCtrl.text,
                              dob: _dobCtrl.text,
                              address: _addressCtrl.text,
                              panImage: (!kIsWeb && _panXFile != null)
                                  ? File(_panXFile!.path)
                                  : null,
                              aadhaarImage: (!kIsWeb && _aadhaarXFile != null)
                                  ? File(_aadhaarXFile!.path)
                                  : null,
                              panXFile: _panXFile,
                              aadhaarXFile: _aadhaarXFile,
                            );
                            if (!mounted) return;
                            setState(() => _submitting = false);
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

class KycView extends StatelessWidget {
  const KycView({super.key});

  static const Color _dark = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'KYC Verification',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _dark,
          ),
        ),
        actions: [
          IconButton(
            onPressed: controller.refreshKycStatus,
            icon: const Icon(Icons.refresh_rounded, color: _dark, size: 20),
          ),
        ],
      ),
      body: Obx(() {
        final InvestorProfileModel user = controller.profile.value;
        final KycDetailsModel kyc = user.kyc;
        final bool isVerified =
            user.kycStatus.trim().toLowerCase() == 'verified';

        return RefreshIndicator(
          onRefresh: controller.refreshKycStatus,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'KYC Status',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _dark,
                            ),
                          ),
                          _KycStatusBadge(status: user.kycStatus),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _detailRow(
                        'Full Name',
                        kyc.fullNameAsPerPan.isNotEmpty
                            ? kyc.fullNameAsPerPan
                            : user.fullName,
                      ),
                      _detailRow('PAN Number', kyc.maskedPan),
                      _detailRow('Aadhaar Number', kyc.maskedAadhaar),
                      _detailRow('Date of Birth', kyc.dob),
                      _detailRow(
                        'Address',
                        kyc.address.isNotEmpty ? kyc.address : user.city,
                      ),
                      if (kyc.updatedAt.trim().isNotEmpty)
                        _detailRow('Last Updated', kyc.updatedAt),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!isVerified)
                  AppButton(
                    label: kyc.hasKycData
                        ? 'Update / Resubmit KYC'
                        : 'Complete KYC',
                    type: AppButtonType.primary,
                    onPressed: () {
                      ProfileKycSheet.show(
                        context: context,
                        initialProfile: user,
                        onSubmit:
                            ({
                              required String fullNameAsPerPan,
                              required String panNumber,
                              required String aadhaarNumber,
                              required String dob,
                              required String address,
                              File? panImage,
                              File? aadhaarImage,
                              XFile? panXFile,
                              XFile? aadhaarXFile,
                            }) {
                              return controller.submitKycDetails(
                                fullNameAsPerPan: fullNameAsPerPan,
                                panNumber: panNumber,
                                aadhaarNumber: aadhaarNumber,
                                dob: dob,
                                address: address,
                                panImage: panImage,
                                aadhaarImage: aadhaarImage,
                                panXFile: panXFile,
                                aadhaarXFile: aadhaarXFile,
                              );
                            },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KycStatusBadge extends StatelessWidget {
  final String status;

  const _KycStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final String lower = status.trim().toLowerCase();
    final bool verified = lower == 'verified';
    final bool rejected = lower == 'rejected';

    final Color bg = verified
        ? const Color(0xFFD1FAE5)
        : rejected
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);
    final Color fg = verified
        ? const Color(0xFF065F46)
        : rejected
        ? const Color(0xFFB91C1C)
        : const Color(0xFF92400E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.trim().isEmpty ? 'Pending' : status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
