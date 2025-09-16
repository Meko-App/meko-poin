import 'package:flutter/material.dart';
import 'package:meko_poin/services/kas_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class KasTableFilter extends StatefulWidget {
  final KasRepository kasRepository;
  final List<dynamic> currentPageData;
  final List<dynamic> data;
  final Function(int? year, int? month) onFilterChanged;
  final VoidCallback onAddNew;
  final int? currentYear;
  final int? currentMonth;

  const KasTableFilter({
    super.key,
    required this.kasRepository,
    required this.currentPageData,
    required this.data,
    required this.onFilterChanged,
    required this.onAddNew,
    this.currentYear,
    this.currentMonth,
  });

  @override
  State<KasTableFilter> createState() => _KasTableFilterState();
}

class _KasTableFilterState extends State<KasTableFilter> {
  int? _selectedYear;
  int? _selectedMonth;
  final List<int> _availableYears = [];
  final List<int> _availableMonths = [];
  bool _isMonthDropdownEnabled = false;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.currentYear;
    _selectedMonth = widget.currentMonth;
    _isMonthDropdownEnabled = _selectedYear != null;
    _extractAvailableYearsAndMonths();
  }

  @override
  void didUpdateWidget(covariant KasTableFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.currentYear != widget.currentYear ||
        oldWidget.currentMonth != widget.currentMonth) {
      setState(() {
        _selectedYear = widget.currentYear;
        _selectedMonth = widget.currentMonth;
        _isMonthDropdownEnabled = _selectedYear != null;
        _extractAvailableYearsAndMonths();
      });
    }
  }

  void _extractAvailableYearsAndMonths() async {
    try {
      final allYears = await widget.kasRepository.getAvailableYears();

      List<int> availableMonthsForYear = [];
      if (_selectedYear != null) {
        availableMonthsForYear =
            await widget.kasRepository.getAvailableMonths(_selectedYear!);
      }

      setState(() {
        _availableYears
          ..clear()
          ..addAll(allYears);
        _availableMonths
          ..clear()
          ..addAll(availableMonthsForYear..sort((a, b) => a.compareTo(b)));
      });
    } catch (e) {
      debugPrint('Error extracting available years and months: $e');
    }
  }

  void _onYearChanged(int? year) {
    setState(() {
      _selectedYear = year;
      _selectedMonth = null; // Reset bulan ketika tahun berubah
      _isMonthDropdownEnabled = year != null;
    });
    _extractAvailableYearsAndMonths();
    // widget.onFilterChanged(year, null);
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
      _isMonthDropdownEnabled = false;
    });
    widget.onFilterChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan ${widget.currentPageData.length} of ${widget.data.length} data',
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
                  child: DropdownButton<int?>(
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
                        'Tahun',
                        style: TextStyle(
                          fontSize: 12,
                          color: CustomColors.fontSubColor,
                        ),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Pilih Tahun',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      ..._availableYears.map((year) {
                        return DropdownMenuItem<int?>(
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
                    ],
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
                  color: _isMonthDropdownEnabled
                      ? CustomColors.inputColor
                      : CustomColors.inputColor.withOpacity(0.5),
                  border: Border.all(
                    color: CustomColors.borderCardColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedMonth,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isMonthDropdownEnabled
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      fontFamily: 'Inter',
                    ),
                    dropdownColor: CustomColors.inputColor,
                    borderRadius: BorderRadius.circular(6),
                    icon: Icon(Icons.keyboard_arrow_down,
                        size: 16,
                        color: _isMonthDropdownEnabled
                            ? CustomColors.fontSubColor
                            : CustomColors.fontSubColor.withOpacity(0.5)),
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _isMonthDropdownEnabled ? 'Bulan' : 'Pilih tahun',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isMonthDropdownEnabled
                              ? CustomColors.fontSubColor
                              : CustomColors.fontSubColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Pilih Bulan',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      ..._availableMonths.map((month) {
                        return DropdownMenuItem<int?>(
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
                    ],
                    onChanged: _isMonthDropdownEnabled ? _onMonthChanged : null,
                  ),
                ),
              ),
              if (_selectedYear != null || _selectedMonth != null)
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

              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1379F0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: widget.onAddNew,
                child: const Text(
                  'Buat Baru',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.0,
                    fontWeight: FontWeight.w500,
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
