import 'package:ev_investors_app/screens/pages/Home/widget/product_card_widget.dart';
import 'package:flutter/material.dart';

import 'widget/search_section_widget.dart';

class HomeComponent {
  HomeComponent._();

  static Widget searchSection() {
    return const SearchSectionWidget();
  }

  static Widget productCardSection() {
    return const ProductCardWidget();
  }
}
