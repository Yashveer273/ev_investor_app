import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary & Brand Colors
  static const Color primary = Color(
    0xFF0F172A,
  ); // Deep Navy / Slate-900 (#0F172A)
  static const Color primaryHover = Color(0xFF1E293B); // Slate-800
  static const Color accent = Color(0xFF10B981); // Emerald-500
  static const Color accentDark = Color(0xFF047857); // Emerald-700
  static const Color accentLight = Color(0xFFD1FAE5); // Emerald-100
  static const Color accentMint = Color(0xFF34D399); // Emerald-400

  // Backgrounds & Surfaces
  static const Color background = Color(
    0xFFF8FAFC,
  ); // Main Scaffold BG (#F8FAFC)
  static const Color surface = Colors.white; // Cards & Header BG
  static const Color surfaceMuted = Color(
    0xFFF1F5F9,
  ); // Slate-100 (Chips / Disabled)

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate-200 (#E2E8F0)
  static const Color borderHighlight = Color(0xFFA7F3D0); // Emerald-200

  // Text Colors
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Dark Heading & Value Text
  static const Color textSecondary = Color(
    0xFF64748B,
  ); // Muted Labels (#64748B)
  static const Color textTertiary = Color(0xFF94A3B8); // Hints / Placeholders
  static const Color textInverse = Colors.white; // Text on Dark BG

  // Status Colors
  static const Color warningBg = Color(
    0xFFFEF3C7,
  ); // Amber-100 (KYC Pending / Due)
  static const Color warningText = Color(0xFF92400E); // Amber-800
  static const Color dangerBg = Color(0xFFFEF2F2); // Red-50 (Logout / Expired)
  static const Color dangerText = Color(0xFFB91C1C); // Red-700
}
