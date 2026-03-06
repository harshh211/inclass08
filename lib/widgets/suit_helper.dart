import 'package:flutter/material.dart';

/// Returns the correct icon and color for a playing card suit.
class SuitHelper {
  static IconData iconFor(String suit) {
    switch (suit) {
      case 'Hearts':
        return Icons.favorite;
      case 'Diamonds':
        return Icons.diamond;
      case 'Clubs':
        return Icons.filter_vintage;
      case 'Spades':
        return Icons.sailing;
      default:
        return Icons.style;
    }
  }

  static Color colorFor(String suit) {
    switch (suit) {
      case 'Hearts':
      case 'Diamonds':
        return const Color(0xFFD32F2F);
      case 'Clubs':
      case 'Spades':
        return const Color(0xFF212121);
      default:
        return Colors.grey;
    }
  }

  static Color backgroundFor(String suit) {
    switch (suit) {
      case 'Hearts':
        return const Color(0xFFFFEBEE);
      case 'Diamonds':
        return const Color(0xFFFFF8E1);
      case 'Clubs':
        return const Color(0xFFE8F5E9);
      case 'Spades':
        return const Color(0xFFE3F2FD);
      default:
        return Colors.grey.shade100;
    }
  }
}
