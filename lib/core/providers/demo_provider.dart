import 'package:flutter_riverpod/flutter_riverpod.dart';

final demoModeProvider = StateProvider<bool>((ref) => false);

class DemoState {
  static const bajajId = 'demo-bajaj';
  static const bancoId = 'demo-banco';
}
