import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class DateRangeFilter extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime?, DateTime?) onDateRangeSelected;
  final String placeholder;
  final double width;

  const DateRangeFilter({
    super.key,
    required this.onDateRangeSelected,
    this.initialStartDate,
    this.initialEndDate,
    this.placeholder = 'Pilih Tanggal',
    this.width = 240,
  });

  @override
  State<DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<DateRangeFilter> {
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDropdownVisible = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  void didUpdateWidget(covariant DateRangeFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStartDate != widget.initialStartDate ||
        oldWidget.initialEndDate != widget.initialEndDate) {
      _startDate = widget.initialStartDate;
      _endDate = widget.initialEndDate;
    }
  }

  void _showDropdown() {
    if (_isDropdownVisible || _isDisposed) return;

    if (_isDisposed || !mounted) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    setState(() => _isDropdownVisible = true);

    final size = renderBox.size;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const preferredDropdownWidth = 560.0;
    const horizontalPadding = 16.0;
    const verticalPadding = 12.0;
    const dropdownGap = 8.0;
    const estimatedDropdownHeight = 430.0;
    final dropdownWidth = preferredDropdownWidth > screenWidth - 32
        ? screenWidth - 32
        : preferredDropdownWidth;

    var leftOffset = fieldOffset.dx;
    final maxLeft = screenWidth - dropdownWidth - horizontalPadding;
    if (leftOffset > maxLeft) {
      leftOffset = maxLeft;
    }
    if (leftOffset < horizontalPadding) {
      leftOffset = horizontalPadding;
    }

    final availableBelow =
        screenHeight - (fieldOffset.dy + size.height) - verticalPadding;
    final availableAbove = fieldOffset.dy - verticalPadding;
    final shouldOpenAbove = availableBelow < estimatedDropdownHeight &&
        availableAbove > availableBelow;

    final maxDropdownHeight = screenHeight - (verticalPadding * 2);
    final dropdownHeight = estimatedDropdownHeight > maxDropdownHeight
        ? maxDropdownHeight
        : estimatedDropdownHeight;

    var topOffset = shouldOpenAbove
        ? fieldOffset.dy - dropdownHeight - dropdownGap
        : fieldOffset.dy + size.height + dropdownGap;

    final minTop = verticalPadding;
    final maxTop = screenHeight - dropdownHeight - verticalPadding;
    if (topOffset < minTop) {
      topOffset = minTop;
    }
    if (topOffset > maxTop) {
      topOffset = maxTop;
    }

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: leftOffset,
        top: topOffset,
        width: dropdownWidth,
        child: Material(
          color: CustomColors.cardColor,
          elevation: 10,
          borderRadius: BorderRadius.circular(8),
          shadowColor: Colors.black.withValues(alpha: 0.35),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDropdownHeight),
            child: SingleChildScrollView(
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
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleDropdown,
          child: Container(
            key: _fieldKey,
            height: 34,
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: CustomColors.borderCardColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    _startDate == null || _endDate == null
                        ? widget.placeholder
                        : '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                      color: CustomColors.fontSubColor,
                    ),
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
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFED143B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: const Size(57, 34),
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
      ],
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
  late DateTime _currentLeftMonth;
  late DateTime _currentRightMonth;

  @override
  void initState() {
    super.initState();
    final todayAtMidnight = DateTime(
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
        if (normalizedDate.isBefore(normalizedStartDate)) {
          _startDate = normalizedDate;
        } else if (normalizedDate.isAfter(normalizedStartDate)) {
          _endDate = normalizedDate;
        }
      } else {
        if (normalizedDate.isBefore(normalizedStartDate)) {
          _startDate = normalizedDate;
        } else if (normalizedDate.isAfter(normalizedEndDate)) {
          _endDate = normalizedDate;
        } else {
          _startDate = normalizedDate;
          _endDate = normalizedDate;
        }
      }

      if (_startDate.isAfter(_endDate)) {
        final temp = _startDate;
        _startDate = _endDate;
        _endDate = temp;
      }
    });
  }

  bool _isDateInRange(DateTime date) {
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
        child: Text(
          DateFormat('MMM yyyy').format(month),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdaysHeader() {
    const weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CustomColors.fontSubColor,
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
      borderRadius = BorderRadius.circular(4);
    }

    return GestureDetector(
      onTap: () => _onDateSelected(date),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 2),
        decoration: BoxDecoration(
          color: isStart || isEnd
              ? const Color(0xFF1379F0)
              : isInRange && !isSingleDateSelection
                  ? const Color(0xFF1379F0).withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 12,
              color: isStart || isEnd
                  ? Colors.white
                  : isCurrentMonth
                      ? Colors.white
                      : CustomColors.fontSubColor.withValues(alpha: 0.55),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
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
                    size: 20, color: CustomColors.fontSubColor),
                onPressed: _goToPreviousMonths,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMonthHeader(_currentLeftMonth),
                    _buildMonthHeader(_currentRightMonth),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    size: 20, color: CustomColors.fontSubColor),
                onPressed: _goToNextMonths,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
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
                          childAspectRatio: 1.0,
                        ),
                        itemCount: 42,
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
                color: CustomColors.borderCardColor,
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
                          childAspectRatio: 1.0,
                        ),
                        itemCount: 42,
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
            border:
                Border(top: BorderSide(color: CustomColors.borderCardColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _startDate.isAtSameMomentAs(_endDate)
                    ? DateFormat('dd/MM/yyyy').format(_startDate)
                    : '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: CustomColors.inputColor,
                      side: const BorderSide(
                          color: CustomColors.borderInputColor),
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
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onApply(_startDate, _endDate);
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
