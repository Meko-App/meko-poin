import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class AttendanceTableSearch extends StatefulWidget {
  final List<dynamic> currentPageData;
  final List<dynamic> data;
  final List<dynamic> data2;
  final int? currentYear;
  final int? currentMonth;
  final Function(int? year, int? month) onFilterChanged;

  const AttendanceTableSearch({
    super.key,
    required this.currentPageData,
    required this.data,
    required this.data2,
    this.currentYear,
    this.currentMonth,
    required this.onFilterChanged,
  });

  @override
  State<AttendanceTableSearch> createState() => _AttendanceTableSearchState();
}

class _AttendanceTableSearchState extends State<AttendanceTableSearch> {
  int? _selectedYear;
  int? _selectedMonth;
  final List<int> _availableYears = [];
  final List<int> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    // Set nilai awal dari props
    _selectedYear = widget.currentYear;
    _selectedMonth = widget.currentMonth;
    _extractAvailableYearsAndMonths();
  }

  @override
  void didUpdateWidget(covariant AttendanceTableSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.currentYear != widget.currentYear ||
        oldWidget.currentMonth != widget.currentMonth) {
      setState(() {
        _selectedYear = widget.currentYear;
        _selectedMonth = widget.currentMonth;
        _extractAvailableYearsAndMonths();
      });
    }
  }

  void _extractAvailableYearsAndMonths() {
    final yearsSet = <int>{};
    final monthsSet = <int>{};

    for (var report in widget.data) {
      final dateString = report['date'] as String;
      final dateParts = dateString.split('-');
      if (dateParts.length == 3) {
        final year = int.tryParse(dateParts[0]);
        final month = int.tryParse(dateParts[1]);

        if (year != null) yearsSet.add(year);
        if (month != null) monthsSet.add(month);
      }
    }

    setState(() {
      _availableYears
        ..clear()
        ..addAll(yearsSet.toList()..sort((a, b) => b.compareTo(a)));
      _availableMonths
        ..clear()
        ..addAll(monthsSet.toList()..sort((a, b) => a.compareTo(b)));
    });
  }

  void _onYearChanged(int? year) {
    setState(() {
      _selectedYear = year;
      _selectedMonth = null; // Reset bulan ketika tahun berubah
    });
  }

  void _onMonthChanged(int? month) {
    setState(() {
      _selectedMonth = month;
    });
    widget.onFilterChanged(_selectedYear, month);
  }

  void _clearFilters() {
    setState(() {
      _selectedYear = null;
      _selectedMonth = null;
    });
    widget.onFilterChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    // Hitung jumlah hari kehadiran yang difilter
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan ${widget.currentPageData.length} of ${widget.data2.length} data',
            style: const TextStyle(
              fontSize: 14,
              height: 1.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          Row(
            children: [
              // Tahun Dropdown
              Container(
                width: 240,
                height: 34,
                decoration: BoxDecoration(
                  color: CustomColors.inputColor,
                  border: Border.all(
                    color: CustomColors.borderCardColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                    dropdownColor: CustomColors.inputColor,
                    borderRadius: BorderRadius.circular(6),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        size: 16, color: CustomColors.fontSubColor),
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Pilih Tahun',
                        style: TextStyle(
                          fontSize: 12,
                          color: CustomColors.fontSubColor,
                        ),
                      ),
                    ),
                    items: _availableYears.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            year.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _onYearChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Bulan Dropdown
              Container(
                width: 240,
                height: 34,
                decoration: BoxDecoration(
                  color: CustomColors.inputColor,
                  border: Border.all(
                    color: CustomColors.borderCardColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                    dropdownColor: CustomColors.inputColor,
                    borderRadius: BorderRadius.circular(6),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        size: 16, color: CustomColors.fontSubColor),
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Pilih Bulan',
                        style: TextStyle(
                          fontSize: 12,
                          color: CustomColors.fontSubColor,
                        ),
                      ),
                    ),
                    items: _availableMonths.map((month) {
                      return DropdownMenuItem<int>(
                        value: month,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            _getMonthName(month),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _onMonthChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Clear Filter Button
              if (_selectedYear != null && _selectedMonth != null)
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED143B),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _clearFilters,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return 'Bulan $month';
    }
  }
}
