import 'package:meko_poin/models/master_data.dart';

class MasterDataWithUser {
  final MasterData masterData;
  final String addedBy;

  MasterDataWithUser({
    required this.masterData,
    required this.addedBy,
  });
}
