class KycDetailsModel {
  final String fullNameAsPerPan;
  final String panNumber;
  final String aadhaarNumber;
  final String panImageUrl;
  final String aadhaarImageUrl;
  final String dob;
  final String address;
  final String remarks;
  final String updatedAt;

  const KycDetailsModel({
    this.fullNameAsPerPan = '',
    this.panNumber = '',
    this.aadhaarNumber = '',
    this.panImageUrl = '',
    this.aadhaarImageUrl = '',
    this.dob = '',
    this.address = '',
    this.remarks = '',
    this.updatedAt = '',
  });

  bool get hasKycData =>
      panNumber.trim().isNotEmpty ||
      aadhaarNumber.trim().isNotEmpty ||
      panImageUrl.trim().isNotEmpty ||
      aadhaarImageUrl.trim().isNotEmpty;

  String get maskedPan {
    final String clean = panNumber.trim().toUpperCase();
    if (clean.isEmpty) return 'Not Added';
    if (clean.length <= 4) return clean;
    return '${clean.substring(0, 2)}XXXXX${clean.substring(clean.length - 3)}';
  }

  String get maskedAadhaar {
    final String clean = aadhaarNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (clean.isEmpty) return 'Not Added';
    if (clean.length <= 4) return clean;
    return 'XXXX XXXX ${clean.substring(clean.length - 4)}';
  }

  KycDetailsModel copyWith({
    String? fullNameAsPerPan,
    String? panNumber,
    String? aadhaarNumber,
    String? panImageUrl,
    String? aadhaarImageUrl,
    String? dob,
    String? address,
    String? remarks,
    String? updatedAt,
  }) {
    return KycDetailsModel(
      fullNameAsPerPan: fullNameAsPerPan ?? this.fullNameAsPerPan,
      panNumber: panNumber ?? this.panNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      panImageUrl: panImageUrl ?? this.panImageUrl,
      aadhaarImageUrl: aadhaarImageUrl ?? this.aadhaarImageUrl,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      remarks: remarks ?? this.remarks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory KycDetailsModel.fromJson(Map<String, dynamic> json) {
    return KycDetailsModel(
      fullNameAsPerPan: (json['fullNameAsPerPan'] ?? json['fullName'] ?? '')
          .toString(),
      panNumber: (json['panNumber'] ?? json['pan'] ?? '').toString(),
      aadhaarNumber: (json['aadhaarNumber'] ?? json['aadhaar'] ?? '')
          .toString(),
      panImageUrl:
          (json['panImageUrl'] ?? json['panPhoto'] ?? json['panImage'] ?? '')
              .toString(),
      aadhaarImageUrl:
          (json['aadhaarImageUrl'] ??
                  json['aadhaarPhoto'] ??
                  json['aadhaarImage'] ??
                  '')
              .toString(),
      dob: (json['dob'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      remarks: (json['remarks'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fullNameAsPerPan': fullNameAsPerPan,
    'panNumber': panNumber,
    'aadhaarNumber': aadhaarNumber,
    'panImageUrl': panImageUrl,
    'aadhaarImageUrl': aadhaarImageUrl,
    'dob': dob,
    'address': address,
    'remarks': remarks,
    'updatedAt': updatedAt,
  };

  static KycDetailsModel empty() => const KycDetailsModel();
}

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

  BankPayoutDetailsModel copyWith({
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? bankName,
    String? upiId,
    String? updatedAt,
  }) {
    return BankPayoutDetailsModel(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      upiId: upiId ?? this.upiId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'accountHolderName': accountHolderName,
    'accountNumber': accountNumber,
    'ifscCode': ifscCode,
    'bankName': bankName,
    'upiId': upiId,
    'updatedAt': updatedAt,
  };

  static BankPayoutDetailsModel empty() {
    return const BankPayoutDetailsModel(
      accountHolderName: '',
      accountNumber: '',
      ifscCode: '',
      bankName: '',
      upiId: '',
      updatedAt: '',
    );
  }
}

class InvestorProfileModel {
  final String investorId;
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String kycStatus;
  final KycDetailsModel kyc;
  final BankPayoutDetailsModel bankDetails;
  final List<String> investments;

  const InvestorProfileModel({
    required this.investorId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.kycStatus,
    this.kyc = const KycDetailsModel(),
    required this.bankDetails,
    this.investments = const <String>[],
  });

  InvestorProfileModel copyWith({
    String? investorId,
    String? fullName,
    String? phone,
    String? email,
    String? city,
    String? kycStatus,
    KycDetailsModel? kyc,
    BankPayoutDetailsModel? bankDetails,
    List<String>? investments,
  }) {
    return InvestorProfileModel(
      investorId: investorId ?? this.investorId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      kycStatus: kycStatus ?? this.kycStatus,
      kyc: kyc ?? this.kyc,
      bankDetails: bankDetails ?? this.bankDetails,
      investments: investments ?? this.investments,
    );
  }

  factory InvestorProfileModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawBank = json['bankDetails'];
    final Map<String, dynamic> bankMap = rawBank is Map
        ? Map<String, dynamic>.from(rawBank)
        : <String, dynamic>{};

    final dynamic rawKyc = json['kyc'] ?? json['kycDetails'];
    final Map<String, dynamic> kycMap = rawKyc is Map
        ? Map<String, dynamic>.from(rawKyc)
        : json;

    final dynamic rawInvestments = json['investments'];
    final List<String> parsedInvestments = rawInvestments is List
        ? rawInvestments
              .map((dynamic item) {
                if (item is Map) {
                  return (item['_id'] ??
                          item['investmentId'] ??
                          item['id'] ??
                          '')
                      .toString();
                }
                return item.toString();
              })
              .where((String id) => id.isNotEmpty)
              .toList()
        : const <String>[];

    return InvestorProfileModel(
      investorId: (json['investorId'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      phone: _normalizePhone((json['phone'] ?? '').toString()),
      email: (json['email'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      kycStatus: (json['kycStatus'] ?? 'Pending').toString(),
      kyc: KycDetailsModel.fromJson(kycMap),
      bankDetails: BankPayoutDetailsModel.fromJson(bankMap),
      investments: parsedInvestments,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'investorId': investorId,
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'city': city,
    'kycStatus': kycStatus,
    'kyc': kyc.toJson(),
    'bankDetails': bankDetails.toJson(),
    'investments': investments,
  };

  static String _normalizePhone(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('+91')) {
      clean = clean.substring(3).trim();
    } else if (clean.startsWith('91') && clean.length > 10) {
      clean = clean.substring(2).trim();
    }
    return clean;
  }

  static InvestorProfileModel empty() {
    return InvestorProfileModel(
      investorId: '',
      fullName: '',
      phone: '',
      email: '',
      city: '',
      kycStatus: 'Pending',
      kyc: KycDetailsModel.empty(),
      bankDetails: BankPayoutDetailsModel.empty(),
      investments: const <String>[],
    );
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

  factory PrivacyFeedbackModel.fromJson(Map<String, dynamic> json) {
    return PrivacyFeedbackModel(
      investorId: (json['investorId'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      submittedDate: (json['submittedDate'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'investorId': investorId,
    'topic': topic,
    'message': message,
    'submittedDate': submittedDate,
  };
}
