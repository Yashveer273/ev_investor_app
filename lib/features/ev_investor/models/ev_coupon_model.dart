class EvCouponModel {
  final String code;
  final String assignedUserId;
  final String discountType; // 'fixed' or 'percentage'
  final double discountValue;
  final int discountAmount;
  final int minInvestmentAmount;
  final String expiryDate;
  final String description;

  const EvCouponModel({
    required this.code,
    this.assignedUserId = '',
    this.discountType = 'fixed',
    this.discountValue = 0,
    required this.discountAmount,
    this.minInvestmentAmount = 0,
    this.expiryDate = '',
    this.description = '',
  });

  /// Computes rupee discount for a given cart/gross amount
  int computeDiscount(int grossAmount) {
    if (grossAmount <= 0) return 0;

    int calculated;
    if (discountType.trim().toLowerCase() == 'percentage') {
      calculated = (grossAmount * (discountValue / 100)).round();
    } else if (discountValue > 0) {
      calculated = discountValue.round();
    } else {
      calculated = discountAmount;
    }

    if (calculated < 0) return 0;
    return calculated > grossAmount ? grossAmount : calculated;
  }

  factory EvCouponModel.fromJson(Map<String, dynamic> json) {
    final parsedCode = (json['code'] ?? '').toString().trim().toUpperCase();
    final parsedUserId = (json['userId'] ?? json['assignedUserId'] ?? '')
        .toString()
        .trim();
    final parsedType = (json['discountType'] ?? 'fixed')
        .toString()
        .trim()
        .toLowerCase();

    double parsedValue = 0;
    final rawVal = json['discountValue'] ?? json['discountAmount'] ?? 0;
    if (rawVal is num) {
      parsedValue = rawVal.toDouble();
    } else {
      parsedValue = double.tryParse(rawVal.toString().trim()) ?? 0;
    }

    final int resolvedAmount = parsedType == 'percentage'
        ? 0
        : parsedValue.round();

    int parsedMinAmt = 0;
    final rawMin = json['minInvestmentAmount'];
    if (rawMin is num) {
      parsedMinAmt = rawMin.round();
    } else if (rawMin != null) {
      parsedMinAmt = int.tryParse(rawMin.toString().trim()) ?? 0;
    }

    return EvCouponModel(
      code: parsedCode,
      assignedUserId: parsedUserId,
      discountType: parsedType,
      discountValue: parsedValue,
      discountAmount: resolvedAmount,
      minInvestmentAmount: parsedMinAmt,
      expiryDate: (json['expiryDate'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'userId': assignedUserId,
      'discountType': discountType,
      'discountValue': discountValue,
      'discountAmount': discountAmount,
      'minInvestmentAmount': minInvestmentAmount,
      'expiryDate': expiryDate,
      'description': description,
    };
  }
}
