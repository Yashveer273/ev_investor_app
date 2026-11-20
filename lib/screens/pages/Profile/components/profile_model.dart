class BankPayoutDetailsModel {
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String upiId;
  final String updatedAt;

  const BankPayoutDetailsModel({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    required this.upiId,
    this.updatedAt = '',
  });

  bool get hasBankDetails =>
      accountNumber.trim().isNotEmpty || upiId.trim().isNotEmpty;

  String get maskedAccountNumber {
    final String clean = accountNumber.trim();
    if (clean.isEmpty) return 'Not Added';
    if (clean.length <= 4) return clean;
    return '•••• •••• ${clean.substring(clean.length - 4)}';
  }

  factory BankPayoutDetailsModel.fromJson(Map<String, dynamic> json) {
    return BankPayoutDetailsModel(
      accountHolderName: (json['accountHolderName'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? '').toString(),
      ifscCode: (json['ifscCode'] ?? '').toString(),
      bankName: (json['bankName'] ?? '').toString(),
      upiId: (json['upiId'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'accountHolderName': accountHolderName,
    'accountNumber': accountNumber,
    'ifscCode': ifscCode,
    'bankName': bankName,
    'upiId': upiId,
    'updatedAt': updatedAt,
  };
}

class InvestorProfileModel {
  final String investorId;
  final String fullName;
  final String phone; // Stored without +91 prefix
  final String email;
  final String city;
  final String kycStatus; // "Verified", "Pending"
  final BankPayoutDetailsModel bankDetails;

  const InvestorProfileModel({
    required this.investorId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.kycStatus,
    required this.bankDetails,
  });

  factory InvestorProfileModel.fromJson(Map<String, dynamic> json) {
    return InvestorProfileModel(
      investorId: (json['investorId'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      phone: _normalizePhone((json['phone'] ?? '').toString()),
      email: (json['email'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      kycStatus: (json['kycStatus'] ?? 'Verified').toString(),
      bankDetails: BankPayoutDetailsModel.fromJson(
        Map<String, dynamic>.from(json['bankDetails'] ?? {}),
      ),
    );
  }

  static String _normalizePhone(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('+91')) {
      clean = clean.substring(3).trim();
    } else if (clean.startsWith('91') && clean.length == 12) {
      clean = clean.substring(2).trim();
    }
    return clean;
  }

  static InvestorProfileModel dummyProfile() {
    return InvestorProfileModel.fromJson({
      'investorId': '10018492',
      'fullName': 'Yashveer Verma',
      'phone': '9876543210',
      'email': 'investor@evfleet.in',
      'city': 'Aligarh, Uttar Pradesh',
      'kycStatus': 'Verified',
      'bankDetails': {
        'accountHolderName': 'Yashveer Verma',
        'accountNumber': '3891001500048291',
        'ifscCode': 'PUNB0389100',
        'bankName': 'Punjab National Bank',
        'upiId': 'yashveer@okicici',
        'updatedAt': '2026-11-15',
      },
    });
  }
}

class PrivacyFeedbackModel {
  final String investorId;
  final String topic;
  final String message;
  final String submittedDate;

  const PrivacyFeedbackModel({
    required this.investorId,
    required this.topic,
    required this.message,
    required this.submittedDate,
  });

  Map<String, dynamic> toJson() => {
    'investorId': investorId,
    'topic': topic,
    'message': message,
    'submittedDate': submittedDate,
  };
}
