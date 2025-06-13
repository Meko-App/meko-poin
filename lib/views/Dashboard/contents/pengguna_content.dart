import 'package:flutter/material.dart';
import 'package:meko_poin/views/Dashboard/components/table/user_table/user_table.dart';

class PenggunaContent extends StatelessWidget {
  const PenggunaContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pengguna",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade900)),
          const SizedBox(height: 4),
          Text("Data master untuk pengguna aplikasi MEKO POIN",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.77, // 70% dari tinggi layar
            ),
            child: UserTable(),
          ),
        ],
      ),
    );
  }
}
