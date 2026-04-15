import 'dart:convert';
import 'package:flutter/material.dart';

class ImageHelper {
  static ImageProvider getBarberImage(String? imageStr, String fallbackId) {
    if (imageStr != null && imageStr.isNotEmpty) {
      if (imageStr.startsWith('http')) {
        return NetworkImage(imageStr);
      } else {
        try {
          return MemoryImage(base64Decode(imageStr));
        } catch (_) {
          return NetworkImage('https://i.pravatar.cc/500?u=$fallbackId');
        }
      }
    }
    return NetworkImage('https://i.pravatar.cc/500?u=$fallbackId');
  }
}
