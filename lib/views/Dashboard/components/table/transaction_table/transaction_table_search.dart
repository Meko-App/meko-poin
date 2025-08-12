import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/report_service.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class TransactionTableSearch extends StatefulWidget {
  final List<dynamic> currentPageData;
  final List<dynamic> data;
  final Function(DateTime?, DateTime?) onDateRangeSelected;
  final VoidCallback onAddNew;
  final VoidCallback onPrintReport;
  final Function(String) onSearch;

  const TransactionTableSearch({
    super.key,
    required this.currentPageData,
    required this.data,
    required this.onDateRangeSelected,
    required this.onAddNew,
    required this.onPrintReport,
    required this.onSearch,
  });

  @override
  State<TransactionTableSearch> createState() => _TransactionTableSearchState();
}

class _TransactionTableSearchState extends State<TransactionTableSearch> {
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownVisible = false;
  bool _isDisposed = false;

  void _showDropdown() {
    if (_isDropdownVisible || _isDisposed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;

      final overlay = Overlay.of(context, rootOverlay: true);
      // ignore: unnecessary_null_comparison
      if (overlay == null) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      setState(() => _isDropdownVisible = true);

      final size = renderBox.size;
      final screenWidth = MediaQuery.of(context).size.width;
      final dropdownWidth = 560.0;

      final rightOffset = screenWidth -
          (renderBox.localToGlobal(Offset.zero).dx + size.width) +
          260;

      _overlayEntry?.remove();
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          right: rightOffset,
          top: renderBox.localToGlobal(Offset.zero).dy + size.height - 5,
          width: dropdownWidth,
          child: Material(
            color: Colors.white,
            elevation: 10,
            borderRadius: BorderRadius.circular(8),
            child: _DateRangePickerContent(
              startDate: _startDate,
              endDate: _endDate,
              onApply: (start, end) {
                if (!_isDisposed && mounted) {
                  setState(() {
                    _startDate = start;
                    _endDate = end;
                  });
                }
                widget.onDateRangeSelected(_startDate, _endDate);
                _hideDropdown();
              },
              onCancel: _hideDropdown,
            ),
          ),
        ),
      );

      overlay.insert(_overlayEntry!);
    });
  }

  void _hideDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    if (!_isDisposed && mounted) {
      setState(() => _isDropdownVisible = false);
    }
  }

  void _toggleDropdown() {
    if (_isDisposed) return;
    _isDropdownVisible ? _hideDropdown() : _showDropdown();
  }

  void _resetDateRange() {
    if (_isDisposed) return;
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    widget.onDateRangeSelected(null, null);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideDropdown();
    super.dispose();
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
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 250,
                height: 34,
                child: TextField(
                  onChanged: widget.onSearch,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari Nama',
                    hintStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                      color: CustomColors.fontSubColor,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 14,
                      color: Colors.white,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 20,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: CustomColors.borderCardColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              CompositedTransformTarget(
                link: _layerLink,
                child: InkWell(
                  onTap: _toggleDropdown,
                  child: Container(
                    height: 34,
                    width: 240,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: CustomColors.borderCardColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _startDate == null || _endDate == null
                              ? 'Pilih Tanggal'
                              : '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Inter',
                            color: CustomColors.fontSubColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isDropdownVisible
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: CustomColors.fontSubColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED143B),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(57, 40),
                  ),
                  onPressed: _resetDateRange,
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
              ],
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1379F0), // Blue background
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(100, 40),
                ),
                onPressed: widget.onAddNew,
                child: const Text(
                  'Tambah Baru',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0BC33F), // Green background
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Color(0xFF0BC33F)),
                  ),
                  minimumSize: const Size(108, 40),
                ),
                onPressed: () => ReportService.exportTransactionsToExcel(
                  transactions: widget.data,
                  reportTitle: 'Laporan Penjualan',
                  startDate: _startDate,
                  endDate: _endDate,
                  context: context,
                ),
                child: const Text(
                  'Cetak Laporan',
                  style: TextStyle(
                    color: Colors.white, // White text color
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _DateRangePickerContent extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onApply;
  final VoidCallback onCancel;

  const _DateRangePickerContent({
    required this.startDate,
    required this.endDate,
    required this.onApply,
    required this.onCancel,
  });

  @override
  State<_DateRangePickerContent> createState() =>
      _DateRangePickerContentState();
}

class _DateRangePickerContentState extends State<_DateRangePickerContent> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  late DateTime _currentLeftMonth; // Month for the left calendar
  late DateTime _currentRightMonth; // Month for the right calendar

  @override
  void initState() {
    super.initState();
    DateTime todayAtMidnight = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    _startDate = widget.startDate ?? todayAtMidnight;
    _endDate = widget.endDate ?? todayAtMidnight;

    _currentLeftMonth = DateTime(_startDate.year, _startDate.month, 1);
    _currentRightMonth =
        DateTime(_currentLeftMonth.year, _currentLeftMonth.month + 1, 1);
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final normalizedStartDate =
          DateTime(_startDate.year, _startDate.month, _startDate.day);
      final normalizedEndDate =
          DateTime(_endDate.year, _endDate.month, _endDate.day);

      if (normalizedStartDate.isAtSameMomentAs(normalizedEndDate)) {
        // If only one date is selected, or starting a new selection
        if (normalizedDate.isBefore(normalizedStartDate)) {
          _startDate = normalizedDate;
        } else if (normalizedDate.isAfter(normalizedStartDate)) {
          _endDate = normalizedDate;
        } else {
          // Clicked on the same date again - keep it as a single selection
        }
      } else {
        // If a range is already selected
        if (normalizedDate.isBefore(normalizedStartDate)) {
          _startDate = normalizedDate;
        } else if (normalizedDate.isAfter(normalizedEndDate)) {
          _endDate = normalizedDate;
        } else {
          // If clicked within or on existing range boundaries, start new selection
          _startDate = normalizedDate;
          _endDate = normalizedDate;
        }
      }

      // Ensure start date is always before or equal to end date
      if (_startDate.isAfter(_endDate)) {
        DateTime temp = _startDate;
        _startDate = _endDate;
        _endDate = temp;
      }
    });
  }

  bool _isDateInRange(DateTime date) {
    // Normalize dates to remove time components for accurate comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStartDate =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final normalizedEndDate =
        DateTime(_endDate.year, _endDate.month, _endDate.day);

    if (normalizedStartDate.isAtSameMomentAs(normalizedEndDate)) {
      return normalizedDate.isAtSameMomentAs(normalizedStartDate);
    }
    return (normalizedDate.isAfter(normalizedStartDate) &&
            normalizedDate.isBefore(normalizedEndDate)) ||
        normalizedDate.isAtSameMomentAs(normalizedStartDate) ||
        normalizedDate.isAtSameMomentAs(normalizedEndDate);
  }

  void _goToPreviousMonths() {
    setState(() {
      _currentLeftMonth =
          DateTime(_currentLeftMonth.year, _currentLeftMonth.month - 1, 1);
      _currentRightMonth =
          DateTime(_currentRightMonth.year, _currentRightMonth.month - 1, 1);
    });
  }

  void _goToNextMonths() {
    setState(() {
      _currentLeftMonth =
          DateTime(_currentLeftMonth.year, _currentLeftMonth.month + 1, 1);
      _currentRightMonth =
          DateTime(_currentRightMonth.year, _currentRightMonth.month + 1, 1);
    });
  }

  Widget _buildMonthHeader(DateTime month) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: Center(
        // Center the month text
        child: Text(
          DateFormat('MMM yyyy')
              .format(month), // Changed format to include year
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdaysHeader() {
    const List<String> weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDayCell(DateTime date, DateTime displayMonth) {
    final isCurrentMonth =
        date.month == displayMonth.month && date.year == displayMonth.year;
    final isInRange = _isDateInRange(date);

    // Normalize dates to remove time components for accurate comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStartDate =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final normalizedEndDate =
        DateTime(_endDate.year, _endDate.month, _endDate.day);

    final isStart = normalizedDate.isAtSameMomentAs(normalizedStartDate);
    final isEnd = normalizedDate.isAtSameMomentAs(normalizedEndDate);
    final isSingleDateSelection =
        normalizedStartDate.isAtSameMomentAs(normalizedEndDate);

    BorderRadius? borderRadius;
    if (isStart && !isSingleDateSelection) {
      borderRadius = const BorderRadius.horizontal(left: Radius.circular(4));
    } else if (isEnd && !isSingleDateSelection) {
      borderRadius = const BorderRadius.horizontal(right: Radius.circular(4));
    } else {
      borderRadius =
          BorderRadius.circular(4); // For single date or middle of range
    }

    return GestureDetector(
        onTap: () => _onDateSelected(date),
        child: Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 0.5,
              vertical: 2), // Reduce horizontal margin slightly
          decoration: BoxDecoration(
            color: isStart || isEnd
                ? const Color(0xFF1379F0) // Blue for start and end dates
                : isInRange && !isSingleDateSelection
                    ? const Color(0xFF1379F0)
                        .withOpacity(0.1) // Light blue for middle range
                    : Colors.transparent, // Transparent for unselected
            borderRadius: borderRadius,
          ),
          child: Center(
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 12,
                color: isStart || isEnd
                    ? Colors.white // White text for start and end dates
                    : isCurrentMonth
                        ? const Color(
                            0xFF111827) // Dark gray for current month dates
                        : const Color(
                            0xFFD1D5DB), // Light gray for previous/next month dates
                fontFamily: 'Inter',
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    size: 20, color: Color(0xFFA4ABBF)),
                onPressed: _goToPreviousMonths,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                // Wrap month names in Expanded to share space
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround, // Distribute month names
                  children: [
                    _buildMonthHeader(_currentLeftMonth),
                    _buildMonthHeader(_currentRightMonth),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFFA4ABBF)),
                onPressed: _goToNextMonths,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280, // Adjusted height to better fit two calendars
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildWeekdaysHeader(),
                    Expanded(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.0, // Make cells square
                        ),
                        itemCount: 42, // Enough cells to cover 6 weeks
                        itemBuilder: (context, index) {
                          final firstDay = DateTime(_currentLeftMonth.year,
                              _currentLeftMonth.month, 1);
                          final weekdayOfFirstDay = firstDay.weekday % 7;
                          final day = index - weekdayOfFirstDay + 1;
                          final date = DateTime(_currentLeftMonth.year,
                              _currentLeftMonth.month, day);
                          return _buildDayCell(date, _currentLeftMonth);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFFE5E7EB),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildWeekdaysHeader(),
                    Expanded(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.0, // Make cells square
                        ),
                        itemCount: 42, // Enough cells to cover 6 weeks
                        itemBuilder: (context, index) {
                          final firstDay = DateTime(_currentRightMonth.year,
                              _currentRightMonth.month, 1);
                          final weekdayOfFirstDay = firstDay.weekday % 7;
                          final day = index - weekdayOfFirstDay + 1;
                          final date = DateTime(_currentRightMonth.year,
                              _currentRightMonth.month, day);
                          return _buildDayCell(date, _currentRightMonth);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Align items to start and end
            children: [
              Text(
                _startDate.isAtSameMomentAs(_endDate)
                    ? DateFormat('dd/MM/yyyy').format(_startDate)
                    : '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              Row(
                // Wrap buttons in another Row for spacing control
                children: [
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF111827),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final start = _startDate;
                      final end = _endDate;

                      widget.onApply(start, end);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1379F0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
