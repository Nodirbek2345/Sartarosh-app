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
          return CachedNetworkImageProvider(
            'https://i.pravatar.cc/500?u=$fallbackId',
          );
        }
      }
    }
    return CachedNetworkImageProvider(
      'https://i.pravatar.cc/500?u=$fallbackId',
    );
  }
}
