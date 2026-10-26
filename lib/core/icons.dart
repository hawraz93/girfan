import 'package:flutter/material.dart';

/// Category icons are stored by key so the DB never holds code points.
const Map<String, IconData> kCatIcons = {
  'restaurant': Icons.restaurant_rounded,
  'grocery': Icons.shopping_basket_rounded,
  'coffee': Icons.coffee_rounded,
  'child': Icons.child_care_rounded,
  'family': Icons.family_restroom_rounded,
  'car': Icons.directions_car_rounded,
  'fuel': Icons.local_gas_station_rounded,
  'taxi': Icons.local_taxi_rounded,
  'home': Icons.home_rounded,
  'bolt': Icons.bolt_rounded,
  'water': Icons.water_drop_rounded,
  'health': Icons.medical_services_rounded,
  'pharmacy': Icons.medication_rounded,
  'clothes': Icons.checkroom_rounded,
  'beauty': Icons.face_retouching_natural_rounded,
  'fun': Icons.movie_rounded,
  'sport': Icons.fitness_center_rounded,
  'phone': Icons.phone_iphone_rounded,
  'wifi': Icons.wifi_rounded,
  'school': Icons.school_rounded,
  'book': Icons.menu_book_rounded,
  'gift': Icons.card_giftcard_rounded,
  'travel': Icons.flight_rounded,
  'pets': Icons.pets_rounded,
  'mosque': Icons.mosque_rounded,
  'charity': Icons.volunteer_activism_rounded,
  'repair': Icons.build_rounded,
  'salary': Icons.payments_rounded,
  'work': Icons.work_rounded,
  'bank': Icons.account_balance_rounded,
  'trend': Icons.trending_up_rounded,
  'star': Icons.star_rounded,
  'more': Icons.more_horiz_rounded,
};

IconData catIcon(String key) => kCatIcons[key] ?? Icons.category_rounded;

/// Curated hues that sit well together on both themes.
const List<int> kCatColors = [
  0xFFF17B73, 0xFFF4A259, 0xFFE8B54D, 0xFFA3D977, 0xFF5FD3A3, 0xFF4FC3F7,
  0xFF6C8CFF, 0xFF9B7BFF, 0xFFD67BFF, 0xFFFF7BB3, 0xFFB0A090, 0xFF8A93A3,
];
