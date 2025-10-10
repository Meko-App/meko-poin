import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/utils/validators.dart';

class CustomerForm extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialCustomerData;

  const CustomerForm({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    this.initialCustomerData,
  });

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomerData != null) {
      _nameController.text = widget.initialCustomerData!['name'] ?? '';
      _phoneController.text = widget.initialCustomerData!['phone'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    // Validasi name
    final nameError = Validators.validateName(_nameController.text);
    setState(() {
      _nameError = nameError;
    });

    // Validasi phone
    final phoneError = Validators.validatePhone(_phoneController.text);
    setState(() {
      _phoneError = phoneError;
    });

    if (nameError != null || phoneError != null) {
      return;
    }

    final String name = _nameController.text;
    final String phone = _phoneController.text;

    final Map<String, dynamic> customerData = {
      'name': name,
      'phone': phone,
    };

    widget.onSubmit(customerData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input Nama
                  _buildFormLabel('Nama'),
                  const SizedBox(height: 8),
                  _buildTextField(_nameController, 'Masukkan Nama',
                      errorText: _nameError),
                  const SizedBox(height: 16),

                  // Input No. HP
                  _buildFormLabel('No. HP'),
                  const SizedBox(height: 8),
                  _buildTextField(_phoneController, 'Masukkan No. HP',
                      errorText: _phoneError),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: CustomColors.cardColor,
              border: Border(
                top: BorderSide(
                  color: CustomColors.borderCardColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: widget.onCancel,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: CustomColors.fontSubColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    widget.initialCustomerData != null ? 'Simpan' : 'Buat Baru',
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool enabled = true, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                color: CustomColors.fontSubColor,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: errorText != null ? Colors.red : Color(0xFF1379F0),
                    width: 1.0),
              ),
              filled: true,
              fillColor: enabled
                  ? CustomColors.inputColor
                  : CustomColors.borderInputColor,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}
