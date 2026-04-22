import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageHelper {
  static ImageProvider getBarberImage(String? imageStr, String fallbackId) {
    if (imageStr != null && imageStr.isNotEmpty) {
      if (imageStr.startsWith('http')) {
        return CachedNetworkImageProvider(imageStr);
      } else {
        try {
          return MemoryImage(base64Decode(imageStr));
        } catch (_) {
          // Noto'g'ri base64 bo'lsa — default icon ko'rsatamiz
          return const AssetImage('assets/images/default_barber.png');
        }
      }
    }
    // Rasm yo'q — placeholder ichki asset yoki umumiy ikon
    return const AssetImage('assets/images/default_barber.png');
  }
}
