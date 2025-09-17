import 'package:meko_poin/models/kas.dart';

class KasWithBalance {
  final Kas kas;
  final int initialBalance;
  final int finalBalance;

  KasWithBalance({
    required this.kas,
    required this.initialBalance,
    required this.finalBalance,
  });
}
