import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddRejectDialog extends StatefulWidget {
  final String itemName;
  final int currentRejectStock;
  final Function(int) onRejectAdded;

  const AddRejectDialog({
    super.key,
    required this.itemName,
    required this.currentRejectStock,
    required this.onRejectAdded,
  });

  @override
  State<AddRejectDialog> createState() => _AddRejectDialogState();
}

class _AddRejectDialogState extends State<AddRejectDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rejectController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _rejectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = Colors.grey[900];
    final textColor = Colors.white;
    final borderColor = Colors.grey[700];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Dialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tambah Stock Reject',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: textColor.withOpacity(0.6)),
                        onPressed: () => Navigator.pop(context),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 20),

                  // Item Info
                  _buildInfoTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Produk',
                    value: widget.itemName,
                    color: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    icon: Icons.warning_amber_outlined,
                    title: 'Jumlah Reject Hingga Saat Ini',
                    value: widget.currentRejectStock.toString(),
                    color: textColor,
                  ),
                  const SizedBox(height: 24),

                  // Input Field
                  TextFormField(
                    controller: _rejectController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Jumlah Reject',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: textColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: textColor.withOpacity(0.6),
                      ),
                      hintText: 'Masukkan jumlah reject',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan jumlah reject';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      if (int.parse(value) <= 0) {
                        return 'Jumlah harus lebih dari 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: textColor.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('BATAL'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: textColor,
                          foregroundColor: bgColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isSubmitting = true);
                                  try {
                                    final rejectAmount =
                                        int.parse(_rejectController.text);
                                    await widget.onRejectAdded(rejectAmount);
                                    if (mounted) Navigator.pop(context);
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isSubmitting = false);
                                    }
                                  }
                                }
                              },
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('SIMPAN'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
