import 'package:ev_investors_app/features/ev_investor/controllers/ev_investor_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EvSearchBar extends StatefulWidget {
  final EvInvestorController controller;
  final String hintText;

  const EvSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search by ID, company, model, year, type...',
  });

  @override
  State<EvSearchBar> createState() => _EvSearchBarState();
}

class _EvSearchBarState extends State<EvSearchBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.searchText.value,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleClear() {
    _textController.clear();
    widget.controller.clearSearchEvProducts();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasText =
          _textController.text.trim().isNotEmpty ||
          widget.controller.searchText.value.isNotEmpty;
      final isLoading = widget.controller.isLoadingProducts.value;

      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1FAE5), width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 20,
              color: Color(0xFF047857),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                onChanged: (val) {
                  setState(() {});
                  widget.controller.onSearchInputChanged(val);
                },
                onSubmitted: (val) {
                  widget.controller.searchEvProducts(val);
                },
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF047857),
                ),
              )
            else if (hasText)
              IconButton(
                onPressed: _handleClear,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Clear search',
              ),
          ],
        ),
      );
    });
  }
}
