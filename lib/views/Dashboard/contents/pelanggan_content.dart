import 'package:flutter/material.dart';
import 'package:meko_poin/services/customer_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/customer_table/customer_table.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:meko_poin/views/Dashboard/components/form/customer_form.dart';
import 'package:meko_poin/models/customer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PelangganContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final CustomerRepository customerRepository;

  const PelangganContent({
    super.key,
    required this.onStateChanged,
    required this.customerRepository,
  });

  @override
  State<PelangganContent> createState() => _PelangganContentState();
}

class _PelangganContentState extends State<PelangganContent> {
  ContentState _currentState = ContentState.table;
  Map<String, dynamic>? _customerToEdit;
  late final CustomerRepository customerRepository;

  @override
  void initState() {
    super.initState();
    customerRepository = widget.customerRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
  }

  void _showForm({Customer? customer}) {
    setState(() {
      _currentState = ContentState.form;
      _customerToEdit = customer != null
          ? {
              'id': customer.id,
              'name': customer.name,
              'phone': customer.phone,
            }
          : null;
      widget.onStateChanged(_currentState);
    });
  }

  void _showTable() {
    setState(() {
      _currentState = ContentState.table;
      _customerToEdit = null;
      widget.onStateChanged(_currentState);
    });
  }

  Future<void> _handleCustomerFormSubmit(
      Map<String, dynamic> customerData) async {
    try {
      // Dapatkan user ID dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('userId');

      if (currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User tidak terautentikasi')),
          );
        }
        return;
      }

      if (_customerToEdit == null) {
        // Add new customer
        final newCustomer = Customer(
          id: null,
          userId: currentUserId,
          name: customerData['name'],
          phone: customerData['phone'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await customerRepository.insertCustomer(newCustomer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer baru berhasil ditambahkan')),
          );
        }
      } else {
        // Edit existing customer
        final updatedCustomer = Customer(
          id: _customerToEdit!['id'],
          userId: currentUserId,
          name: customerData['name'],
          phone: customerData['phone'],
          createdAt: DateTime.now(), // Tetap gunakan created_at asli
          updatedAt: DateTime.now(),
        );
        await customerRepository.updateCustomer(updatedCustomer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer berhasil diperbarui')),
          );
        }
      }
      _showTable();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan customer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double currentMaxHeight = _currentState == ContentState.table
        ? MediaQuery.of(context).size.height * 0.77
        : double.infinity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentState != ContentState.table)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _showTable,
                  color: Colors.grey.shade700,
                ),
              if (_currentState != ContentState.table) const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: CustomColors.fontSubColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: currentMaxHeight,
            ),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentState) {
      case ContentState.table:
        return "Customer";
      case ContentState.form:
        return _customerToEdit != null ? "Edit Customer" : "Buat Customer Baru";
      default:
        return "Customer";
    }
  }

  String _getSubtitle() {
    switch (_currentState) {
      case ContentState.table:
        return "Data master untuk customer aplikasi MEKO POIN";
      case ContentState.form:
        return _customerToEdit != null
            ? "Edit data customer"
            : "Buat customer baru";
      default:
        return "Data master untuk customer aplikasi MEKO POIN";
    }
  }

  Widget _buildContent() {
    switch (_currentState) {
      case ContentState.table:
        return CustomerTable(
          onAddNew: _showForm,
          customerRepository: customerRepository,
          onEditCustomer: (customer) => _showForm(customer: customer),
          onDeleteCustomer: (customer) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Konfirmasi Penghapusan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(
                            height: 1,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 10),
                          // Content text
                          Text(
                            'Hapus customer ${customer.name}?',
                            style: TextStyle(
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Tindakan ini tidak dapat dibatalkan. Pastikan juga data customer tidak terkoneksi dengan data lainnya. Jika terkoneksi dan tetap dihapus, mungkin akan menimbulkan masalah.',
                            style: TextStyle(
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Divider
                          Divider(
                            height: 1,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          // Footer Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[400],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Batal'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red[300],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Hapus'),
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

            if (confirmed == true) {
              try {
                await customerRepository.deleteCustomer(customer.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer berhasil dihapus')),
                  );
                }
                _showTable();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus customer: $e')),
                  );
                }
              }
            }
          },
        );
      case ContentState.form:
        return CustomerForm(
          onCancel: _showTable,
          initialCustomerData: _customerToEdit,
          onSubmit: _handleCustomerFormSubmit,
        );
      default:
        return CustomerTable(
          onAddNew: _showForm,
          customerRepository: customerRepository,
          onEditCustomer: (customer) => _showForm(customer: customer),
          onDeleteCustomer: (customer) {},
        );
    }
  }
}
