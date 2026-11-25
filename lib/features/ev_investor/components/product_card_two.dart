import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/ev_investor_controller.dart';
import '../models/ev_product_model.dart';

class ProductCardTwo extends StatelessWidget {
  final EvProductModel product;
  final EvInvestorController controller;
  final VoidCallback onViewDetails;
  final void Function(int delta, GlobalKey triggerKey) onUpdateCart;

  const ProductCardTwo({
    super.key,
    required this.product,
    required this.controller,
    required this.onViewDetails,
    required this.onUpdateCart,
  });

  @override
  Widget build(BuildContext context) {
    final monthlyAmount = product.monthlyReturnAmount;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xE6D1FAE5), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 176,
              width: double.infinity,
              child: ColoredBox(
                color: const Color(0xFFECFDF5),
                child: Image.network(
                  product.coverImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 176,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFECFDF5),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        product.type,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.type} • ${product.specs.brandModel}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SpecMiniTile(
                          label: 'Range',
                          value: product.specs.range,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SpecMiniTile(
                          label: 'Battery',
                          value: product.specs.battery,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SpecMiniTile(
                          label: 'Charging',
                          value: product.specs.chargingTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFA7F3D0).withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.factory_outlined,
                          size: 12,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.brand,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5).withValues(alpha: 0.4),
                      border: const Border(
                        top: BorderSide(color: Color(0xCCD1FAE5), width: 1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Investment / Unit',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF64748B),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                EvInvestorController.formatINR(
                                  product.unitPrice,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Monthly Return',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF64748B),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '+${EvInvestorController.formatINR(monthlyAmount)}/mo',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF059669),
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${product.monthlyReturnRate}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF065F46),
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CardActionRow(
                    productId: product.id,
                    controller: controller,
                    onViewDetails: onViewDetails,
                    onUpdateCart: onUpdateCart,
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

class _SpecMiniTile extends StatelessWidget {
  final String label;
  final String value;

  const _SpecMiniTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xB3E2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
              height: 1.2,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActionRow extends StatefulWidget {
  final String productId;
  final EvInvestorController controller;
  final VoidCallback onViewDetails;
  final void Function(int delta, GlobalKey triggerKey) onUpdateCart;

  const _CardActionRow({
    required this.productId,
    required this.controller,
    required this.onViewDetails,
    required this.onUpdateCart,
  });

  @override
  State<_CardActionRow> createState() => _CardActionRowState();
}

class _CardActionRowState extends State<_CardActionRow> {
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _plusButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: widget.onViewDetails,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                    height: 1.2,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
        Obx(() {
          final inCartUnits = widget.controller.getCartUnitsForProduct(
            widget.productId,
          );

          if (inCartUnits <= 0) {
            return InkWell(
              key: _addButtonKey,
              onTap: () => widget.onUpdateCart(1, _addButtonKey),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF047857),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF047857),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => widget.onUpdateCart(-1, _plusButtonKey),
                  borderRadius: BorderRadius.circular(6),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: Icon(
                        Icons.remove_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$inCartUnits',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                InkWell(
                  key: _plusButtonKey,
                  onTap: () => widget.onUpdateCart(1, _plusButtonKey),
                  borderRadius: BorderRadius.circular(6),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
