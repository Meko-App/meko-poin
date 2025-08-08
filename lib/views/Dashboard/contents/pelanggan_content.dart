import 'package:flutter/material.dart';
import 'package:meko_poin/services/customer_repository.dart';
import 'package:meko_poin/views/Dashboard/components/table/customer_table/customer_table.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class PelangganContent extends StatefulWidget {
  final CustomerRepository customerRepository;

  const PelangganContent({super.key, required this.customerRepository});

  @override
  State<PelangganContent> createState() => _PenggunaContentState();
}

class _PenggunaContentState extends State<PelangganContent> {
  late final CustomerRepository customerRepository;

  @override
  void initState() {
    super.initState();
    customerRepository = widget.customerRepository;
  }

  @override
  Widget build(BuildContext context) {
    double currentMaxHeight = MediaQuery.of(context).size.height * 0.77;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pelanggan",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Data ringkasan pelanggan",
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
              child: CustomerTable(
                customerRepository: customerRepository,
              )),
        ],
      ),
    );
  }
}
