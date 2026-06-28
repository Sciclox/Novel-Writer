import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppShortcuts {
  static SingleActivator ctrl(LogicalKeyboardKey key) => SingleActivator(key, control: true);
  static SingleActivator ctrlShift(LogicalKeyboardKey key) => SingleActivator(key, control: true, shift: true);
  static SingleActivator alt(LogicalKeyboardKey key) => SingleActivator(key, alt: true);
  static SingleActivator meta(LogicalKeyboardKey key) => SingleActivator(key, meta: true);
  static SingleActivator only(LogicalKeyboardKey key) => SingleActivator(key);
}