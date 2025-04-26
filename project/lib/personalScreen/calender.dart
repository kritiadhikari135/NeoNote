import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:project/services/calendar_service.dart';
import 'package:project/services/local_storage.dart';
import 'dart:math';

// Define our own enum for view types
enum CalendarViewType {
  month,
  week,
  day
}

class Calenderpage extends StatefulWidget {
  const Calenderpage({super.key});

  @override
  State<Calenderpage> createState() => _CalenderpageState();
}

class _CalenderpageState extends State<Calenderpage> {
  final GlobalKey<MonthViewState> _monthViewKey = GlobalKey<MonthViewState>();
  final GlobalKey<WeekViewState> _weekViewKey = GlobalKey<WeekViewState>();
  final GlobalKey<DayViewState> _dayViewKey = GlobalKey<DayViewState>();

  // Add separate ScrollControllers for different scrollable widgets
  final ScrollController _monthListScrollController = ScrollController();
  final ScrollController _dialogScrollController = ScrollController();

  EventController eventController = EventController();
  CalendarViewType _calendarView = CalendarViewType.month;
  DateTime _focusedDate = DateTime.now();

  final CalendarService _calendarService = CalendarService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loginAndLoadEvents();
  }

  @override
  void dispose() {
    // Dispose of all ScrollControllers when the widget is disposed
    _monthListScrollController.dispose();
    _dialogScrollController.dispose();
    super.dispose();
  }

  Future<void> _loginAndLoadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we have a token
      final token = await LocalStorage.getToken();

      if (token != null && token.isNotEmpty) {
        print('✅ Token found, loading events');
      } else {
        print('⚠️ No token found, events may not load properly');
      }

      // Load events using the existing token
      await _loadEvents();
    } catch (e) {
      _handleError(e, 'checking token');
      // Still try to load events
      await _loadEvents();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle network errors gracefully
  void _handleError(dynamic error, String operation) {
    print('Error $operation: $error');
    String message = 'Failed to $operation. Please try again later.';

    // Check for specific error types
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('network connection') ||
        error.toString().contains('semaphore timeout')) {
      message = 'Cannot connect to server. Please make sure the Django server is running.';
      print('Server connection error - Django server may not be running');
    } else if (error.toString().contains('401')) {
      message = 'Authentication error. Please log in again.';
    } else if (error.toString().contains('timeout')) {
      message = 'Request timed out. Please try again.';
      print('Using sample data due to timeout');
    }

    // Show error message to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          backgroundColor: error.toString().contains('SocketException') ||
                          error.toString().contains('Connection refused') ?
                          Colors.red : Colors.orange,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load events for current month only
      final now = DateTime.now();

      print('CALENDAR: Initial load - fetching events for current month');
      // Create a new EventController
      eventController = EventController();

      // Load events for current month only
      final currentMonth = DateTime(now.year, now.month, 1);
      print('CALENDAR: Loading events for month ${currentMonth.year}-${currentMonth.month}');

      final monthEvents = await _calendarService.getEventsForMonth(currentMonth.year, currentMonth.month);

      print('CALENDAR: Loaded ${monthEvents.length} events for current month');

      // Add events to the controller
      eventController.addAll(monthEvents);

      // Log all events for debugging
      for (var event in monthEvents) {
        print('CALENDAR: Initial load event: ${event.title} on ${DateFormat('yyyy-MM-dd').format(event.date)}');
      }
    } catch (e) {
      _handleError(e, 'load events');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // WINDOWS STYLE: Direct API call with forced refresh
  Future<void> _loadEventsForFocusedDate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new EventController instead of clearing the existing one
      eventController = EventController();
      print('WINDOWS STYLE: Created new EventController');

      switch (_calendarView) {
        case CalendarViewType.month:
          // Get the first day of the focused month
          final focusedMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
          print('WINDOWS STYLE: Loading events for month: ${focusedMonth.year}-${focusedMonth.month}');

          // Load events for the current month only
          print('WINDOWS STYLE: Loading events for focused month ${focusedMonth.year}-${focusedMonth.month}');
          final currentMonthEvents = await _calendarService.getEventsForMonth(focusedMonth.year, focusedMonth.month);

          print('WINDOWS STYLE: Loaded ${currentMonthEvents.length} events for current month');

          // Log all events for debugging
          for (var event in currentMonthEvents) {
            print('WINDOWS STYLE: Event: ${event.title} on ${DateFormat('yyyy-MM-dd').format(event.date)}');
          }

          // Add events to the new controller
          print('WINDOWS STYLE: Adding ${currentMonthEvents.length} events to controller');
          eventController.addAll(currentMonthEvents);
          break;

        case CalendarViewType.week:
          // For week view, get the start and end of the week (Sunday to Saturday)
          // Calculate the start of the week (Sunday) for the focused date
          final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7));
          final weekEnd = weekStart.add(const Duration(days: 6));
          print('WINDOWS STYLE: Loading events for week: ${weekStart.toString()} to ${weekEnd.toString()}');
          final events = await _calendarService.getEventsForRange(weekStart, weekEnd);
          eventController.addAll(events);
          break;

        case CalendarViewType.day:
          // For day view, just get the events for that day
          print('WINDOWS STYLE: Loading events for day: ${_focusedDate.toString()}');
          final events = await _calendarService.getEventsForDay(_focusedDate);
          eventController.addAll(events);
          break;
      }

      // Force a complete rebuild of the calendar view
      setState(() {
        print('WINDOWS STYLE: Forcing complete rebuild');
      });

    } catch (e) {
      _handleError(e, 'load events');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Calendar',
      onItemSelected: (String value) {},
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF255DE1),
        onPressed: () => _showAddEventDialog(context),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: const Color(0xFF255DE1),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Calendar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF255DE1),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.today),
                          onPressed: () async {
                            setState(() {
                              _focusedDate = DateTime.now();
                            });
                            await _jumpToToday();
                          },
                          tooltip: 'Today',
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _loadEventsForFocusedDate(),
                          tooltip: 'Refresh',
                        ),
                        // Month/Year selector button only for month view
                        if (_calendarView == CalendarViewType.month)
                          IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () => _showMonthYearPicker(context),
                            tooltip: 'Select Month/Year',
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildViewToggleButton(CalendarViewType.month, 'Month'),
                    const SizedBox(width: 10),
                    _buildViewToggleButton(CalendarViewType.week, 'Week'),
                    const SizedBox(width: 10),
                    _buildViewToggleButton(CalendarViewType.day, 'Day'),
                  ],
                ),
                const SizedBox(height: 10),
                // Only show month/year picker in month view
                GestureDetector(
                  onTap: () {
                    if (_calendarView == CalendarViewType.month) {
                      _showMonthYearPicker(context);
                    }
                  },
                  child: _buildDateHeader(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildCalendarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(CalendarViewType view, String title) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _calendarView == view ? const Color(0xFF255DE1) : Colors.grey.shade200,
        foregroundColor: _calendarView == view ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () async {
        if (_calendarView != view) {
          setState(() {
            _calendarView = view;
            _isLoading = true; // Show loading indicator
          });

          // If switching to week view, make sure we're showing the current week
          if (view == CalendarViewType.week) {
            // Calculate the start of the current week (Sunday)
            final now = DateTime.now();
            final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
            _focusedDate = currentWeekStart;
            _weekViewKey.currentState?.jumpToWeek(currentWeekStart);
          }

          // If switching to day view, make sure we're showing the current day
          if (view == CalendarViewType.day) {
            final now = DateTime.now();
            _focusedDate = now;
            _dayViewKey.currentState?.jumpToDate(now);
          }

          // Load appropriate events for the selected view
          await _loadEventsForFocusedDate();

          setState(() {
            _isLoading = false;
          });
        }
      },
      child: Text(title),
    );
  }

  Widget _buildDateHeader() {
    String headerText = '';
    switch (_calendarView) {
      case CalendarViewType.month:
        headerText = DateFormat('MMMM yyyy').format(_focusedDate);
        break;
      case CalendarViewType.week:
        // Calculate week start (Sunday) and end (Saturday)
        // For Sunday start, we need to calculate differently
        // Sunday is 7 in DateTime.weekday (1 is Monday, 7 is Sunday)
        final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        headerText = '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';
        break;
      case CalendarViewType.day:
        headerText = DateFormat('EEEE, MMMM d, yyyy').format(_focusedDate);
        break;
    }

    return Text(
      headerText,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    // Get the current month and year
    int selectedMonth = _focusedDate.month;
    int selectedYear = _focusedDate.year;

    // Show a dialog with month and year pickers
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Month and Year'),
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              content: SizedBox(
                width: 300, // Fixed narrower width
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Month dropdown
                  Row(
                    children: [
                      const Text('Month: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(_getMonthName(index + 1)),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedMonth = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Year dropdown
                  Row(
                    children: [
                      const Text('Year: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: List.generate(11, (index) {
                          // Show 5 years in the past and 5 years in the future
                          return DropdownMenuItem<int>(
                            value: DateTime.now().year - 5 + index,
                            child: Text('${DateTime.now().year - 5 + index}'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedYear = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
                ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF255DE1),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Jump to the selected month and year
                    final newDate = DateTime(selectedYear, selectedMonth, 1);
                    print('WINDOWS STYLE: Month/Year picker selected date: ${newDate.year}-${newDate.month}');

                    // Use the outer setState to update the widget state
                    this.setState(() {
                      _focusedDate = newDate;
                      _isLoading = true; // Show loading indicator
                    });

                    // First load events for the new month and adjacent months
                    print('WINDOWS STYLE: Loading events for month: ${newDate.year}-${newDate.month}');
                    await _loadEventsForFocusedDate();

                    // Then jump to the new month
                    print('WINDOWS STYLE: Jumping to month: ${newDate.year}-${newDate.month}');
                    _monthViewKey.currentState?.jumpToMonth(newDate);

                    // Force a rebuild to ensure the calendar shows the correct events
                    this.setState(() {
                      print('WINDOWS STYLE: Rebuild complete for: ${newDate.year}-${newDate.month}');
                    });
                  },
                  child: const Text(
                    'Go',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showWeekPicker(BuildContext context) async {
    // First, let the user pick a date
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      // Calculate the start of the week (Sunday) for the picked date
      // Sunday is 7 in DateTime.weekday (1 is Monday, 7 is Sunday)
      final weekStart = picked.subtract(Duration(days: picked.weekday % 7));

      setState(() {
        _focusedDate = weekStart;
        _isLoading = true; // Show loading indicator
      });

      // Jump to the new week
      _weekViewKey.currentState?.jumpToWeek(weekStart);

      // Load events for the new week
      await _loadEventsForFocusedDate();

      // Force a rebuild to ensure the calendar shows the correct events
      setState(() {});
    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _focusedDate) {
      setState(() {
        _focusedDate = picked;
        _isLoading = true; // Show loading indicator
      });

      switch (_calendarView) {
        case CalendarViewType.month:
          _monthViewKey.currentState?.jumpToMonth(picked);
          break;
        case CalendarViewType.week:
          _weekViewKey.currentState?.jumpToWeek(picked);
          break;
        case CalendarViewType.day:
          _dayViewKey.currentState?.jumpToDate(picked);
          break;
      }

      // Load events for the new date
      await _loadEventsForFocusedDate();

      // Force a rebuild to ensure the calendar shows the correct events
      setState(() {});
    }
  }

  Future<void> _jumpToToday() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final now = DateTime.now();

    switch (_calendarView) {
      case CalendarViewType.month:
        _focusedDate = DateTime(now.year, now.month, 1);
        _monthViewKey.currentState?.jumpToMonth(now);
        break;
      case CalendarViewType.week:
        // Calculate the start of the current week (Sunday)
        final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
        _focusedDate = currentWeekStart;
        _weekViewKey.currentState?.jumpToWeek(currentWeekStart);
        break;
      case CalendarViewType.day:
        _focusedDate = now;
        _dayViewKey.currentState?.jumpToDate(now);
        break;
    }

    // Load events for today
    await _loadEventsForFocusedDate();

    // Force a rebuild to ensure the calendar shows the correct events
    setState(() {
      _isLoading = false;
    });
  }

  void _previousPage() {
    switch (_calendarView) {
      case CalendarViewType.month:
        // Calculate the previous month date
        final prevMonth = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
        setState(() {
          _focusedDate = prevMonth;
        });
        // Jump directly to the previous month instead of using animation
        _monthViewKey.currentState?.jumpToMonth(prevMonth);
        // Explicitly load events for the new month
        _loadEventsForFocusedDate();
        break;
      case CalendarViewType.week:
        // Calculate the previous week date
        final prevWeek = _focusedDate.subtract(const Duration(days: 7));
        setState(() {
          _focusedDate = prevWeek;
        });
        // Jump directly to the previous week instead of using animation
        _weekViewKey.currentState?.jumpToWeek(prevWeek);
        // Explicitly load events for the new week
        _loadEventsForFocusedDate();
        break;
      case CalendarViewType.day:
        // Calculate the previous day date
        final prevDay = _focusedDate.subtract(const Duration(days: 1));
        setState(() {
          _focusedDate = prevDay;
        });
        // Jump directly to the previous day instead of using animation
        _dayViewKey.currentState?.jumpToDate(prevDay);
        // Explicitly load events for the new day
        _loadEventsForFocusedDate();
        break;
    }
  }

  void _nextPage() {
    switch (_calendarView) {
      case CalendarViewType.month:
        // Calculate the next month date
        final nextMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
        setState(() {
          _focusedDate = nextMonth;
        });
        // Jump directly to the next month instead of using animation
        _monthViewKey.currentState?.jumpToMonth(nextMonth);
        // Explicitly load events for the new month
        _loadEventsForFocusedDate();
        break;
      case CalendarViewType.week:
        // Calculate the next week date
        final nextWeek = _focusedDate.add(const Duration(days: 7));
        setState(() {
          _focusedDate = nextWeek;
        });
        // Jump directly to the next week instead of using animation
        _weekViewKey.currentState?.jumpToWeek(nextWeek);
        // Explicitly load events for the new week
        _loadEventsForFocusedDate();
        break;
      case CalendarViewType.day:
        // Calculate the next day date
        final nextDay = _focusedDate.add(const Duration(days: 1));
        setState(() {
          _focusedDate = nextDay;
        });
        // Jump directly to the next day instead of using animation
        _dayViewKey.currentState?.jumpToDate(nextDay);
        // Explicitly load events for the new day
        _loadEventsForFocusedDate();
        break;
    }
  }

  Widget _buildCalendarView() {
    switch (_calendarView) {
      case CalendarViewType.month:
        // SINGLE MONTH VIEW: Show only the current month with all dates
        return Container(
          height: 650, // Increased height to ensure all dates are fully visible
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom calendar header with day names and dates
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: _buildDayHeaders(),
                ),
              ),
              // Month view
              Expanded(
                child: MonthView(
                  key: _monthViewKey,
                  controller: eventController,
                  // Windows-style calendar configuration
                  showBorder: true,
                  cellAspectRatio: 1.2, // Slightly wider cells for better visibility
                  initialMonth: _focusedDate,
                  // Enable page navigation
                  onPageChange: (date, page) {
                    setState(() {
                      _focusedDate = date;
                      // This will trigger a rebuild of our custom header
                    });
                    _loadEventsForFocusedDate();
                  },
                  // Make sure all dates are shown
                  minMonth: DateTime(1900, 1, 1),
                  maxMonth: DateTime(2100, 12, 31),
                  // Hide the built-in weekday header since we're using our custom header
                  weekDayBuilder: (index) => const SizedBox.shrink(),
                  // Set first day of week to Sunday (index 0)
                  startDay: WeekDays.sunday,
                  // Show dates from adjacent months
                  onEventTap: (events, date) {
                    // Handle the event tap - always show event details dialog
                    // since we know there are events
                    _showEventDetailsDialog(context, events, date);
                  },
                  onCellTap: (events, date) {
                    // Handle cell tap based on date and presence of events
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final selectedDate = DateTime(date.year, date.month, date.day);
                    final isPastDate = selectedDate.isBefore(today);

                    // Check if there are events for this date
                    List<CalendarEventData<Object?>> dateEvents = [];
                    if (events is List<CalendarEventData<Object?>>) {
                      dateEvents = events.where((event) {
                        return event.date.year == date.year &&
                               event.date.month == date.month &&
                               event.date.day == date.day;
                      }).toList();
                    }

                    if (dateEvents.isNotEmpty) {
                      // If there are events, show the events dialog
                      _showEventDetailsDialog(context, dateEvents, date);
                    } else if (!isPastDate) {
                      // If it's current or future date with no events, show add event dialog
                      _showAddEventDialog(context, initialDate: date);
                    }
                    // Do nothing for past dates with no events
                  },
                  // Hide the header as we're using our custom header
                  headerBuilder: (date) => const SizedBox.shrink(),
                  cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) {
                    // Filter events to only show events for this specific date
                    List<CalendarEventData<Object?>> filteredEvents = [];
                    if (events is List<CalendarEventData<Object?>>) {
                      filteredEvents = events.where((event) {
                        // Make sure the event date matches this cell's date exactly
                        final matches = event.date.year == date.year &&
                              event.date.month == date.month &&
                              event.date.day == date.day;
                        return matches;
                      }).toList();
                    }

                    // Show all cells with different styling for current month vs adjacent months
                    return Container(
                      margin: const EdgeInsets.all(1),
                      padding: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: isToday ? Colors.blue.withOpacity(0.1) :
                              (isInMonth ? Colors.white : Colors.grey.shade50),
                        border: Border.all(color: isToday ? Colors.blue : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          // Date number
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isInMonth ? Colors.black : Colors.grey.shade500,
                              fontSize: 16, // Increased font size for better visibility
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Event indicators
                          Expanded(
                            child: filteredEvents.isNotEmpty
                              ? ListView.builder(
                                  // Disable scrolling and scrollbars within day cells
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  // Disable scrollbars and ensure no controller is used
                                  primary: false,
                                  shrinkWrap: true,
                                  // Limit to 2 events to ensure no scrolling is needed
                                  itemCount: filteredEvents.length > 2 ? 2 : filteredEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = filteredEvents[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: event.color.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        event.title ?? '',
                                        style: const TextStyle(fontSize: 10, color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox.shrink(),
                          ),
                          // More events indicator
                          if (filteredEvents.length > 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '+${filteredEvents.length - 2} more',
                                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      case CalendarViewType.week:
        return WeekView(
          key: _weekViewKey,
          controller: eventController,
          onEventTap: (events, date) {
            // Handle the event tap
            _showEventDetailsDialog(context, events, date);
          },
          onDateLongPress: (date) {
            _showAddEventDialog(context, initialDate: date);
          },
          onPageChange: (date, page) {
            setState(() {
              _focusedDate = date;
            });
            _loadEventsForFocusedDate();
          },
          // Set first day of week to Sunday
          startDay: WeekDays.sunday,
          // Custom weekday names (SUN, MON, TUE, etc.) with dates
          weekDayBuilder: (date) {
            // Convert date to day of week index (0 = Sunday, 1 = Monday, etc.)
            final dayIndex = date.weekday % 7; // Convert to 0-based index with Sunday as 0
            final dayNames = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

            // Check if this is today
            final now = DateTime.now();
            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
                color: isToday ? Colors.blue.withOpacity(0.1) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Combine day name and date in a more compact layout
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: dayNames[dayIndex],
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        TextSpan(
                          text: '\n${date.day}', // Add date on new line
                          style: TextStyle(
                            color: isToday ? const Color(0xFF255DE1) : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          // Hide the header as we're using our custom header
          weekPageHeaderBuilder: (startDate, endDate) => const SizedBox.shrink(),
          eventTileBuilder: (date, events, boundary, startTime, endTime) {
            // Filter events to only show events for this specific date
            List<CalendarEventData<Object?>> filteredEvents = [];
            if (events is List<CalendarEventData<Object?>>) {
              filteredEvents = events.where((event) {
                return event.date.year == date.year &&
                       event.date.month == date.month &&
                       event.date.day == date.day;
              }).toList();
            }

            // Custom event tile for week view
            if (filteredEvents.isEmpty) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                color: filteredEvents[0].color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  filteredEvents[0].title ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
      case CalendarViewType.day:
        return DayView(
          key: _dayViewKey,
          controller: eventController,
          onEventTap: (events, date) {
            // Handle the event tap
            _showEventDetailsDialog(context, events, date);
          },
          onDateLongPress: (date) {
            _showAddEventDialog(context, initialDate: date);
          },
          onPageChange: (date, page) {
            setState(() {
              _focusedDate = date;
            });
            _loadEventsForFocusedDate();
          },
          // Hide the header as we're using our custom header
          dayTitleBuilder: (date) => const SizedBox.shrink(),
          eventTileBuilder: (date, events, boundary, startTime, endTime) {
            // Filter events to only show events for this specific date
            List<CalendarEventData<Object?>> filteredEvents = [];
            if (events is List<CalendarEventData<Object?>>) {
              filteredEvents = events.where((event) {
                return event.date.year == date.year &&
                       event.date.month == date.month &&
                       event.date.day == date.day;
              }).toList();
            }

            // Custom event tile for day view
            if (filteredEvents.isEmpty) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                color: filteredEvents[0].color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              height: 34.0, // Fixed height to prevent overflow
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        filteredEvents[0].title ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (filteredEvents[0].description?.isNotEmpty ?? false)
                      Flexible(
                        child: Text(
                          filteredEvents[0].description ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Helper method to format TimeOfDay in 12-hour format with AM/PM
  String _formatTimeOfDay(TimeOfDay time) {
    // Convert 24-hour format to 12-hour format
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Build day headers for the calendar (SUN, MON, TUE, etc.)
  List<Widget> _buildDayHeaders() {
    final dayNames = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final List<Widget> headers = [];

    // Create headers for each day of the week
    for (int i = 0; i < 7; i++) {
      headers.add(
        Expanded(
          child: Center(
            child: Text(
              dayNames[i],
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return headers;
  }

  void _showEventDetailsDialog(BuildContext context, dynamic eventOrEvents, DateTime date) {
    print('_showEventDetailsDialog called with date: ${date.toString()}');

    // Check if the date is in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    final isPastDate = selectedDate.isBefore(today);

    // Convert to list if it's a single event
    List<CalendarEventData<Object?>> events;
    if (eventOrEvents is List<CalendarEventData<Object?>>) {
      print('eventOrEvents is a List with ${eventOrEvents.length} events');
      events = eventOrEvents;
    } else if (eventOrEvents is CalendarEventData<Object?>) {
      print('eventOrEvents is a single CalendarEventData: ${eventOrEvents.title}');
      events = [eventOrEvents];
    } else {
      print('eventOrEvents is an unexpected type: ${eventOrEvents.runtimeType}');
      // Fallback for unexpected types
      events = [];
    }

    print('Before filtering: ${events.length} events');
    for (var event in events) {
      print('Event: ${event.title}, Date: ${event.date.toString()}');
    }

    // Filter events to only show events for this specific date
    events = events.where((event) {
      final matches = event.date.year == date.year &&
             event.date.month == date.month &&
             event.date.day == date.day;
      print('Event ${event.title} on ${event.date.toString()} matches ${date.toString()}: $matches');
      return matches;
    }).toList();

    print('After filtering: ${events.length} events');
    for (var event in events) {
      print('Filtered Event: ${event.title}, Date: ${event.date.toString()}');
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Events on ${DateFormat('MMM d, yyyy').format(date)}'),
          // Set a fixed width that's narrower than the default
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          content: SizedBox(
            width: 300, // Fixed narrower width
            child: ListView.builder(
              // Use primary: false to ensure this ListView doesn't try to use a PrimaryScrollController
              primary: false,
              shrinkWrap: true,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: double.infinity,
                      color: event.color,
                    ),
                    title: Text(event.title ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.description?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(event.description ?? ''),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${DateFormat('h:mm a').format(event.startTime ?? date)} - ${DateFormat('h:mm a').format(event.endTime ?? date)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF255DE1)),
                          tooltip: 'Edit',
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the details dialog
                            _showEditEventDialog(context, event, date);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () {
                        try {
                          print('Attempting to delete event: ${event.title}');

                          // Get the event ID from the event data
                          Map<String, dynamic>? eventData;
                          String? eventId;

                          try {
                            eventData = event.event as Map<String, dynamic>?;
                            eventId = eventData?['eventId'];
                            print('Event data: $eventData');
                            print('Event ID: $eventId');
                          } catch (e) {
                            print('Error extracting event ID: $e');
                          }

                          if (eventId == null) {
                            print('Event ID is null, checking if this is a sample event');
                            // For sample events that might not have an ID
                            if (event.event is String) {
                              // Old format where event is just the title string
                              eventId = 'sample-${DateTime.now().millisecondsSinceEpoch}';
                              print('Created sample ID for string event: $eventId');
                            } else {
                              _handleError('Event ID not found', 'delete event');
                              return;
                            }
                          }

                          // Delete from backend first
                          print('Calling deleteEvent with ID: $eventId');
                          _calendarService.deleteEvent(eventId).then((success) {
                            print('Delete result: $success');
                            if (success) {
                              eventController.remove(event);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Event "${event.title}" deleted')),
                              );
                            } else {
                              _handleError('Server returned failure', 'delete event');
                            }
                          }).catchError((error) {
                            print('Error in deleteEvent callback: $error');
                            _handleError(error, 'delete event');
                          });
                        } catch (e) {
                          print('Exception in event deletion UI: $e');
                          print('Stack trace: ${StackTrace.current}');
                          _handleError(e, 'prepare for deletion');
                        }
                      },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 14),
              ),
            ),
            // Only show Add Event button for current or future dates
            if (!isPastDate)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF255DE1),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddEventDialog(context, initialDate: date);
                },
                child: const Text(
                  'Add Event',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showEditEventDialog(BuildContext context, CalendarEventData<Object?> event, DateTime date) {
    // Extract event data
    final Map<String, dynamic> eventData = event.event as Map<String, dynamic>;
    final String? eventId = eventData['id']?.toString() ?? eventData['eventId']?.toString();

    if (eventId == null) {
      _handleError('Event ID not found', 'edit event');
      return;
    }

    // Initialize controllers with existing event data
    final TextEditingController titleController = TextEditingController(text: event.title ?? '');
    final TextEditingController descriptionController = TextEditingController(text: event.description ?? '');

    // Initialize date and times
    DateTime selectedDate = event.date ?? date;
    TimeOfDay startTime = TimeOfDay(hour: event.startTime?.hour ?? 8, minute: event.startTime?.minute ?? 0);
    TimeOfDay endTime = TimeOfDay(hour: event.endTime?.hour ?? 9, minute: event.endTime?.minute ?? 0);

    // Initialize color
    Color selectedColor = event.color ?? Colors.blue;

    // Show the dialog with the same UI as add event, but pre-filled
    _showEventDialog(
      context: context,
      title: 'Edit Event',
      titleController: titleController,
      descriptionController: descriptionController,
      selectedDate: selectedDate,
      startTime: startTime,
      endTime: endTime,
      selectedColor: selectedColor,
      onSave: (CalendarEventData<Object?> updatedEvent) {
        // Update the event in the backend
        _updateEvent(eventId, updatedEvent);
      },
    );
  }

  void _updateEvent(String eventId, CalendarEventData<Object?> updatedEvent) {
    try {
      print('Updating event with ID: $eventId');
      print('Updated event data: $updatedEvent');

      // Store the scaffold messenger for later use
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Updating event...')),
      );

      // Call the service to update the event
      _calendarService.updateEvent(eventId, updatedEvent).then((updatedEvent) {
        print('Event updated successfully: $updatedEvent');

        if (updatedEvent != null) {
          // Remove the old event and add the updated one
          try {
            // Find and remove the old event
            final events = eventController.events;
            CalendarEventData<Object?>? oldEvent;

            for (final event in events) {
              final eventData = event.event as Map<String, dynamic>?;
              if (eventData != null) {
                final id = eventData['id']?.toString() ?? eventData['eventId']?.toString();
                if (id == eventId) {
                  oldEvent = event;
                  break;
                }
              }
            }

            if (oldEvent != null) {
              eventController.remove(oldEvent);
              eventController.add(updatedEvent);

              // Show success message
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Event "${updatedEvent.title}" updated')),
              );
            } else {
              print('Could not find the old event to update');
              // Just add the updated event
              eventController.add(updatedEvent);

              // Show success message
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Event "${updatedEvent.title}" updated')),
              );
            }
          } catch (e) {
            print('Error updating event in controller: $e');
            _handleError(e, 'update event in calendar');
          }
        } else {
          // Show error message
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to update event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }).catchError((error) {
        print('Error updating event: $error');
        _handleError(error, 'update event');
      });
    } catch (e) {
      print('Exception in event update: $e');
      print('Stack trace: ${StackTrace.current}');
      _handleError(e, 'prepare for update');
    }
  }

  // Generic method for showing event dialog (used by both add and edit)
  void _showEventDialog({
    required BuildContext context,
    required String title,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    required DateTime selectedDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Color selectedColor,
    required Function(CalendarEventData<Object?>) onSave,
  }) {
    // Function to pick date
    Future<void> _selectDate(BuildContext context, StateSetter setState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
        });
      }
    }

    // Function to pick time
    Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay initialTime) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
      );
      return picked;
    }

    // List of colors to choose from - match the colors in CalendarService._getColorFromName
    final List<Color> colorOptions = [
      Colors.blue,   // Default
      Colors.red,    // Red
      Colors.green,  // Green
      Colors.orange, // Orange
      Colors.purple, // Purple
      Colors.teal,   // Teal
    ];

    // Print the selected color for debugging
    void _printSelectedColor(Color color) {
      String colorName = 'unknown';
      if (color == Colors.blue) colorName = 'blue';
      else if (color == Colors.red) colorName = 'red';
      else if (color == Colors.green) colorName = 'green';
      else if (color == Colors.orange) colorName = 'orange';
      else if (color == Colors.purple) colorName = 'purple';
      else if (color == Colors.teal) colorName = 'teal';

      print('Selected color: $colorName ($color)');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              content: SizedBox(
                width: 300, // Fixed narrower width
                child: SingleChildScrollView(
                controller: _dialogScrollController, // Use dedicated controller for dialog
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Event Title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Text('Date: '),
                        TextButton(
                          onPressed: () => _selectDate(context, setState),
                          child: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(color: Color(0xFF255DE1)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Start Time: '),
                        TextButton(
                          onPressed: () {
                            _selectTime(context, startTime).then((time) {
                              if (time != null) {
                                setState(() {
                                  startTime = time;
                                });
                              }
                            });
                          },
                          child: Text(
                            _formatTimeOfDay(startTime),
                            style: const TextStyle(color: Color(0xFF255DE1)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('End Time: '),
                        TextButton(
                          onPressed: () {
                            _selectTime(context, endTime).then((time) {
                              if (time != null) {
                                setState(() {
                                  endTime = time;
                                });
                              }
                            });
                          },
                          child: Text(
                            _formatTimeOfDay(endTime),
                            style: const TextStyle(color: Color(0xFF255DE1)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Event Color:'),
                    const SizedBox(height: 5),
                    Container(
                      height: 50, // Fixed height for color options
                      child: SingleChildScrollView(
                        physics: NeverScrollableScrollPhysics(), // Prevent scrolling
                        child: Wrap(
                        spacing: 12, // Increased spacing
                        runSpacing: 12, // Added spacing between rows
                        children: colorOptions.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                                _printSelectedColor(color);
                              });
                            },
                            child: Container(
                              width: 40, // Increased size
                              height: 40, // Increased size
                              margin: EdgeInsets.all(4), // Added margin
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color ? Colors.black : Colors.transparent,
                                  width: 3, // Thicker border
                                ),
                                // Add shadow for better visibility
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF255DE1),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      // Validate that end time is after start time
                      if (endTime.hour < startTime.hour ||
                          (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
                        // Show error dialog for invalid time selection
                        showDialog(
                          context: context,
                          barrierDismissible: false, // User must tap button to close dialog
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Invalid Time Selection'),
                              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              content: SizedBox(
                                width: 300, // Fixed narrower width
                                child: const Text('End time must be after start time. Please adjust your time selection.'),
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF255DE1),
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        return; // Don't proceed with event creation
                      }

                      try {
                        // Create the event locally first
                        print('Creating/updating event with title: ${titleController.text}');
                        print('Date: $selectedDate, Start: $startTime, End: $endTime');

                        // Create start and end time DateTime objects
                        final startDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          startTime.hour,
                          startTime.minute,
                        );

                        final endDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          endTime.hour,
                          endTime.minute,
                        );

                        print('Start DateTime: $startDateTime');
                        print('End DateTime: $endDateTime');

                        // Print the selected color before creating the event
                        _printSelectedColor(selectedColor);

                        final eventData = CalendarEventData(
                          date: selectedDate,
                          title: titleController.text,
                          description: descriptionController.text,
                          startTime: startDateTime,
                          endTime: endDateTime,
                          color: selectedColor,
                          event: {'title': titleController.text}, // Temporary event data
                        );

                        print('Created event data with color: ${eventData.color}');

                        // Close the dialog
                        Navigator.of(context).pop();

                        // Call the onSave callback
                        onSave(eventData);
                      } catch (e) {
                        print('Exception in event dialog: $e');
                        print('Stack trace: ${StackTrace.current}');

                        // Show error directly with context since we're still in the dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error preparing event: ${e.toString().substring(0, min(50, e.toString().length))}...'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    } else {
                      // Show error dialog if title is empty
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Missing Title'),
                            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            content: SizedBox(
                              width: 300, // Fixed narrower width
                              child: const Text('Please enter a title for your event.'),
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF255DE1),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                child: const Text(
                                  'OK',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text(
                    title == 'Edit Event' ? 'Update Event' : 'Add Event',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context, {DateTime? initialDate}) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime selectedDate = initialDate ?? _focusedDate; // Use the tapped date or focused date

    print('Opening add event dialog for date: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}');

    // Set reasonable default times (current time for start, +1 hour for end)
    final now = TimeOfDay.now();
    TimeOfDay startTime = now;
    TimeOfDay endTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
    Color selectedColor = Colors.blue;

    // Use the generic event dialog for adding events
    _showEventDialog(
      context: context,
      title: 'Add New Event',
      titleController: titleController,
      descriptionController: descriptionController,
      selectedDate: selectedDate, // Pass the correct date
      startTime: startTime,
      endTime: endTime,
      selectedColor: selectedColor,
      onSave: (CalendarEventData<Object?> event) async {
        // Store the scaffold messenger for later use
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        // Show loading indicator
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Creating event...')),
        );

        print('Creating event on date: ${event.date.year}-${event.date.month}-${event.date.day}');
        print('Event details: ${event.title}, Start: ${event.startTime}, End: ${event.endTime}');

        // Save to backend
        final createdEvent = await _calendarService.createEvent(event);
        if (createdEvent != null) {
          print('Event created successfully: ${createdEvent.title} on ${createdEvent.date}');
          eventController.add(createdEvent); // Add the event to the controller
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Event "${event.title}" added')),
          );

          // Reload events to ensure the new event is properly displayed
          _loadEventsForFocusedDate();
        } else {
          print('Failed to create event');
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to create event. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}