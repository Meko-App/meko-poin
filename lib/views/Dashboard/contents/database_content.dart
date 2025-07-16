import 'package:flutter/material.dart';
import 'package:meko_poin/services/database_helper.dart';

class DatabaseContent extends StatelessWidget {
  const DatabaseContent({super.key});

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
                    "Basis Data",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cadangkan dan pulihkan basis data",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade700,
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // First Button (Pulinkan)
                        OutlinedButton(
                          onPressed: () async {
                            await DatabaseHelper.instance
                                .restoreDatabase(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF4B5675),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 22,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_sync,
                                  color: Color(0xFF4B5675), size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Pulihkan',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        ElevatedButton(
                          onPressed: () async {
                            await DatabaseHelper.instance
                                .backupDatabase(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1379F0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 22,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.backup,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Cadangkan',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
