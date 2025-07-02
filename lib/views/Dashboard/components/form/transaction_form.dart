import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransactionForm extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSubmit;

  const TransactionForm({
    super.key,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _orderQuantityController =
      TextEditingController();
  final TextEditingController _discountNominalController =
      TextEditingController();
  final TextEditingController _discountPercentController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedOrderCategory;
  String? _selectedOrderItem;
  String? _selectedPaymentMethod;

  // Dummy data for cart items (replace with your actual cart management)
  List<Map<String, dynamic>> _cartItems = [
    {
      'category': 'Produk',
      'item': 'SELF PHOTO 1-2 Orang',
      'quantity': 1,
      'price': 45000
    },
    {
      'category': 'Bahan',
      'item': 'STRIPE GLOSSY',
      'quantity': 1,
      'price': 15000
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _orderQuantityController.dispose();
    _discountNominalController.dispose();
    _discountPercentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitTransaction() {
    final Map<String, dynamic> transactionData = {
      'phone': _phoneController.text,
      'name': _nameController.text,
      'order_category': _selectedOrderCategory,
      'order_item': _selectedOrderItem,
      'order_quantity': _orderQuantityController.text,
      'discount_nominal': _discountNominalController.text,
      'discount_percent': _discountPercentController.text,
      'payment_method': _selectedPaymentMethod,
      'note': _noteController.text,
      'cart_items': _cartItems, // Pass cart items to the review modal
    };

    _showReviewOrderModal(transactionData);
    // widget.onSubmit(transactionData); // This would be called after confirming in the modal
  }

  void _showReviewOrderModal(Map<String, dynamic> transactionData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ReviewOrderModal(
            onProcess: () {
              Navigator.of(context).pop(); // Close the modal
              widget.onSubmit(transactionData); // Call the original onSubmit
            },
            onCancel: () {
              Navigator.of(context).pop(); // Close the modal
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column (2/3 width)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pelanggan Section Card
                        _buildSectionCard(
                          title: 'Pelanggan',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFormLabel('No. Hp'),
                                        const SizedBox(height: 8),
                                        _buildTextField(
                                            _phoneController, 'Masukkan no HP'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFormLabel('Nama'),
                                        const SizedBox(height: 8),
                                        _buildTextField(
                                            _nameController, 'Masukkan nama'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pesanan Section Card
                        _buildSectionCard(
                          title: 'Pesanan',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOrderInputRow(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Keranjang Section
                        _buildSectionCard(
                          title: 'Keranjang',
                          content: _buildCartTable(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right Column (1/3 width)
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pembayaran Section Card
                        _buildSectionCard(
                          title: 'Pembayaran',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              // Diskon Nominal
                              const Text(
                                'Diskon (Nominal)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111B37),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(_discountNominalController,
                                  'Masukkan diskon nominal'),
                              const SizedBox(height: 16),

                              // Diskon Persen
                              const Text(
                                'Diskon (Persen)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111B37),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(_discountPercentController,
                                  'Masukkan diskon persen'),
                              const SizedBox(height: 16),
                              // Total Harga
                              const Text(
                                'Total Harga',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111B37),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Rp 60.000',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111B37),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Metode Pembayaran
                              const Text(
                                'Metode Pembayaran',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111B37),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentMethodDropdown(),
                              const SizedBox(height: 16),

                              // Catatan
                              const Text(
                                'Catatan (Opsional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111B37),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                  _noteController, 'Masukkan catatan'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Footer with buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: widget.onCancel,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF4B5675),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Tinjau',
                    style: TextStyle(
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

  Widget _buildSectionCard({required String title, required Widget content}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
                bottom: title == 'Keranjang'
                    ? BorderSide.none
                    : BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: Color(0xFF111B37),
              ),
            ),
          ),
          // Content
          Padding(
            padding: title == 'Keranjang'
                ? const EdgeInsets.all(0)
                : const EdgeInsets.all(16),
            child: content,
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
        color: Color(0xFF111B37),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText) {
    final isNoteField = controller == _noteController;

    return SizedBox(
      height: isNoteField ? null : 36,
      child: TextField(
        maxLines: isNoteField ? null : 1,
        minLines: isNoteField ? 4 : 1,
        controller: controller,
        keyboardType:
            isNoteField ? TextInputType.multiline : TextInputType.text,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          color: Color(0xFF111B37),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF78829D),
          ),
          contentPadding: const EdgeInsets.all(12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF1379F0),
              width: 1.0,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          alignLabelWithHint: isNoteField, // Better alignment for multiline
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required Function(String?) onChanged,
    required List<String> items,
  }) {
    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF78829D),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        iconSize: 20,
        isExpanded: true,
        items: items.map<DropdownMenuItem<String>>((String itemValue) {
          return DropdownMenuItem<String>(
            value: itemValue,
            child: Text(
              itemValue,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                color: Color(0xFF111B37),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          color: Color(0xFF111B37),
        ),
      ),
    );
  }

  Widget _buildOrderInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormLabel('Kategori'),
              const SizedBox(height: 8),
              _buildDropdownField(
                value: _selectedOrderCategory,
                hint: 'Pilih kategori',
                onChanged: (newValue) {
                  setState(() {
                    _selectedOrderCategory = newValue;
                  });
                },
                items: const ['Product', 'Paper', 'Packaging', 'Additional'],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormLabel('Item'),
              const SizedBox(height: 8),
              _buildDropdownField(
                value: _selectedOrderItem,
                hint: 'Pilih Item',
                onChanged: (newValue) {
                  setState(() {
                    _selectedOrderItem = newValue;
                  });
                },
                items: const ['SELF PHOTO 1-2', 'STRIPE GLOSSY', 'Item 3'],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormLabel('Jumlah'),
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: TextField(
                  controller: _orderQuantityController,
                  keyboardType: TextInputType.number,
                  textAlignVertical: TextAlignVertical.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111B37),
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan jumlah',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9AA4B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF1379F0),
                        width: 1.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: SizedBox(
                      width: 24,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Up Button
                          SizedBox(
                            width: 24,
                            height: 16,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                onTap: () {
                                  final current = int.tryParse(
                                          _orderQuantityController.text) ??
                                      0;
                                  _orderQuantityController.text =
                                      (current + 1).toString();
                                },
                                child: const Center(
                                  child: Icon(
                                    Icons.keyboard_arrow_up,
                                    size: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Divider
                          Container(
                            height: 1,
                            width: 16,
                            color: Colors.grey.shade200,
                          ),
                          // Down Button
                          SizedBox(
                            width: 24,
                            height: 16,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(4),
                                ),
                                onTap: () {
                                  final current = int.tryParse(
                                          _orderQuantityController.text) ??
                                      1;
                                  if (current > 1) {
                                    _orderQuantityController.text =
                                        (current - 1).toString();
                                  }
                                },
                                child: const Center(
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF1379F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            onPressed: () {
              // Add item to cart logic
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return _buildDropdownField(
      value: _selectedPaymentMethod,
      hint: 'Pilih metode pembayaran',
      onChanged: (newValue) {
        setState(() {
          _selectedPaymentMethod = newValue;
        });
      },
      items: const ['Tunai', 'Transfer Bank', 'QRIS'],
    );
  }

  Widget _buildCartTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // const SizedBox(height: 16),
          // const Text(
          //   'Keranjang',
          //   style: TextStyle(
          //     fontSize: 16,
          //     height: 1.0,
          //     fontWeight: FontWeight.w600,
          //     color: Color(0xFF111B37),
          //     fontFamily: 'Inter',
          //   ),
          // ),
          // const SizedBox(height: 16),

          // Table Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Kolom Kategori
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Kategori',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4B5675),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Item
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Item',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4B5675),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Jumlah
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Jumlah',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4B5675),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Harga (tanpa border kanan)
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      child: const Center(
                        child: Text(
                          'Harga',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4B5675),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Table Rows (Dynamically generated from _cartItems)
          ..._cartItems
              .map((item) => Container(
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18.0, vertical: 10.0),
                              child: Text(
                                item['category'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF111B37),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                          VerticalDivider(
                              thickness: 1, width: 1, color: Colors.grey[300]),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18.0, vertical: 10.0),
                              child: Text(
                                item['item'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF111B37),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                          VerticalDivider(
                              thickness: 1, width: 1, color: Colors.grey[300]),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18.0, vertical: 10.0),
                              child: Text(
                                '${item['quantity']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.0,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF27314B),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                          VerticalDivider(
                              thickness: 1, width: 1, color: Colors.grey[300]),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18.0, vertical: 10.0),
                              child: Text(
                                'Rp ${item['price']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.0,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF27314B),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}

class ReviewOrderModal extends StatelessWidget {
  final VoidCallback onProcess;
  final VoidCallback onCancel;

  const ReviewOrderModal({
    Key? key,
    required this.onProcess,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tinjau Pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111B37),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: Color(0xFF78829D)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onCancel,
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nama', 'John Doe'),
                const SizedBox(height: 8),
                _buildInfoRow('No. HP', '081221430376'),
                const SizedBox(height: 8),
                _buildInfoRow('Tanggal', '5 Feb 2024, 14:00:23'),
                const SizedBox(height: 8),
                _buildInfoRow('Invoice', '#1'),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),

                // Order items
                Column(
                  children: [
                    _buildItemPesanan('SELF PHOTO 1-2 Orang', '1', 'Rp 45.000'),
                    _buildItemPesanan('STRIPE GLOSSY', '1', 'Rp 15.000'),
                    _buildItemPesanan('4R (12X20)', '1', 'Rp 0'),
                    _buildItemPesanan('KEYCHAIN LOVE', '1', 'Rp 5.000'),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),

                _buildPaymentRow('Diskon', '0'),
                const SizedBox(height: 8),
                _buildPaymentRow('Total', 'Rp 65.000'),
                const SizedBox(height: 8),
                _buildPaymentRow('Pembayaran', 'QRIS'),
              ],
            ),
          ),

          // Footer buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xFF4B5675),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onProcess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Proses',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5675),
            ),
          ),
        ),
        const Text(
          ':',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF4B5675),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Color(0xFF111B37),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5675),
            ),
          ),
        ),
        const Text(
          ':',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF4B5675),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Color(0xFF111B37),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemPesanan(String name, String qty, String price) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111B37),
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(
              width: 10,
              child: Text(
                qty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111B37),
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                price,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111B37),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ));
  }
}
