// lib/services/guest_service.dart
import 'package:flutter/material.dart';

class GuestService extends ChangeNotifier {
  bool _isGuest = false;

  bool get isGuest => _isGuest;

  void setGuestMode(bool value) {
    _isGuest = value;
    notifyListeners();
  }

  void logout() {
    _isGuest = false;
    notifyListeners();
  }
}