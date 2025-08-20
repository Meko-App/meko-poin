import 'package:flutter/material.dart';
import 'package:meko_poin/models/master_data.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class PackagingDialog extends StatefulWidget {
  final MasterData paperData;
  final MasterDataRepository repository;

  const PackagingDialog({
    super.key,
    required this.paperData,
    required this.repository,
  });

  @override
  _PackagingDialogState createState() => _PackagingDialogState();
}

class _PackagingDialogState extends State<PackagingDialog> {
  int? _selectedPackagingId;
  List<MasterData> _packagingOptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackagingOptions();
    _selectedPackagingId =
        widget.paperData.packagingId != 0 ? widget.paperData.packagingId : null;
  }

  Future<void> _loadPackagingOptions() async {
    try {
      final options = await widget.repository.getPackagingMasterData();
      setState(() {
        _packagingOptions = options;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading packaging options: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSave() async {
    if (_selectedPackagingId == null) return;
    try {
      await widget.repository.updatePackagingId(
        widget.paperData.id!,
        _selectedPackagingId!,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan packaging: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CustomColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: CustomColors.borderCardColor, width: 1),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Divider(height: 1, color: CustomColors.borderCardColor),
            const SizedBox(height: 10),
            _buildBody(),
            const SizedBox(height: 10),
            Divider(height: 1, color: CustomColors.borderCardColor),
            const SizedBox(height: 10),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.paperData.packagingId == 0
                ? 'Tambah Packaging'
                : 'Edit Packaging',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Paper: ${widget.paperData.name}',
            style: TextStyle(
              fontSize: 16,
              color: CustomColors.fontSubColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : DropdownButtonFormField<int>(
              value: _selectedPackagingId,
              dropdownColor: CustomColors.cardColor,
              decoration: InputDecoration(
                labelText: 'Pilih Packaging',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: CustomColors.borderCardColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: CustomColors.borderCardColor),
                ),
              ),
              style: TextStyle(color: Colors.white),
              items: _packagingOptions.map((packaging) {
                return DropdownMenuItem<int>(
                  value: packaging.id,
                  child: Text(
                    packaging.name,
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPackagingId = value;
                });
              },
            ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _selectedPackagingId != null ? _onSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Mengurangi radius
              ),
            ),
            child: Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
