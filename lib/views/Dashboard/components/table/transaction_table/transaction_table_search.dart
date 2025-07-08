import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionTableSearch extends StatefulWidget {
  final List<dynamic> currentPageData;
  final List<dynamic> data;
  final Function(DateTime?, DateTime?) onDateRangeSelected;
  final VoidCallback onAddNew;
  final VoidCallback onPrintReport;

  const TransactionTableSearch({
    super.key,
    required this.currentPageData,
    required this.data,
    required this.onDateRangeSelected,
    required this.onAddNew,
    required this.onPrintReport,
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

  void _showDropdown() {
    if (_isDropdownVisible) return;

    setState(() => _isDropdownVisible = true);

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = 560.0; // Lebar tetap dropdown

    // Hitung offset agar ujung kanan dropdown sejajar dengan select
    final rightOffset = screenWidth -
        (renderBox.localToGlobal(Offset.zero).dx + size.width) -
        16;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        right: rightOffset, // Posisikan dari kanan
        top: renderBox.localToGlobal(Offset.zero).dy + size.height + 4,
        width: dropdownWidth,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(16),
            child: _DateRangePickerContent(
              startDate: _startDate,
              endDate: _endDate,
              onApply: (start, end) {
                setState(() {
                  _startDate = start;
                  _endDate = end;
                });
                widget.onDateRangeSelected(_startDate, _endDate);
                _hideDropdown();
              },
              onCancel: _hideDropdown,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    setState(() => _isDropdownVisible = false);
  }

  void _toggleDropdown() =>
      _isDropdownVisible ? _hideDropdown() : _showDropdown();

  void _resetDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _overlayEntry != null;
    });
    widget.onDateRangeSelected(null, null);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
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
              color: Color(0xFF111B37),
              fontFamily: 'Inter',
            ),
          ),
          // --- START of the corrected section ---
          Row(
            // Replaced SizedBox with a direct Row to allow natural sizing
            mainAxisSize: MainAxisSize
                .min, // Allows the Row to take minimum horizontal space
            children: [
              CompositedTransformTarget(
                link: _layerLink,
                child: InkWell(
                  // No Expanded here, it will take its natural width
                  onTap: _toggleDropdown,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize:
                          MainAxisSize.min, // Ensure inner row takes min width
                      children: [
                        Text(
                          _startDate == null || _endDate == null
                              ? 'Pilih Tanggal'
                              : '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Inter',
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(
                            width: 8), // Added space between text and icon
                        Icon(
                          _isDropdownVisible
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: const Color(0xFFA4ABBF),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED143B),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(0, 34),
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
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1379F0), // Blue background
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(0, 34),
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
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0BC33F), // Green background
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  minimumSize: const Size(0, 34),
                ),
                onPressed: widget.onPrintReport,
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
    _startDate = widget.startDate ?? DateTime.now();
    _endDate = widget.endDate ?? DateTime.now();

    // Initialize months based on the start date or current date
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
      padding: const EdgeInsets.only(bottom: 8),
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
                    onPressed: () => widget.onApply(_startDate, _endDate),
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
