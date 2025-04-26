import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:calendar_view/calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:project/services/local_storage.dart'; // Use the same LocalStorage as other services

class CalendarService {
  // URL for the Django calendar events API
  static const String baseUrl = 'http://127.0.0.1:8000/api/calendar/api/events/'; // Use the API endpoint

  // Get the auth token using LocalStorage
  Future<String?> _getToken() async {
    try {
      // Get token from LocalStorage (same as other services)
      String? token = await LocalStorage.getToken();

      if (token != null && token.isNotEmpty) {
        print('✅ Using token from LocalStorage for calendar');
        return 'Bearer $token';
      } else {
        print('⚠️ No token found in LocalStorage for calendar');
        return null;
      }
    } catch (e) {
      print('❌ Error getting token for calendar: $e');
      return null;
    }
  }

  // Helper to create headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token ?? '',  // Token already includes 'Bearer ' prefix
    };
  }

  // Convert color from Flutter to Django format
  String _colorToHex(Color color) {
    final hex = '#${color.value.toRadixString(16).substring(2)}';
    print('Converting color to hex: $color -> $hex');
    return hex;
  }

  // Convert hex color from Django to Flutter Color
  Color _hexToColor(String hexColor) {
    print('Converting hex to color: $hexColor');
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    final color = Color(int.parse(hexColor, radix: 16));
    print('Converted hex to color: $hexColor -> $color');
    return color;
  }

  // Map color name to Flutter Color
  Color _getColorFromName(String colorName) {
    print('Converting color name to color: $colorName');
    Color color;
    switch (colorName) {
      case 'red':
        color = Colors.red;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'purple':
        color = Colors.purple;
        break;
      case 'teal':
        color = Colors.teal;
        break;
      case 'blue':
      default:
        color = Colors.blue;
        break;
    }
    print('Converted color name to color: $colorName -> $color');
    return color;
  }

  // Convert Django event to CalendarEventData
  CalendarEventData<Object?> _convertToCalendarEventData(Map<String, dynamic> event) {
    print('Converting event data: $event');

    try {
      // Parse the date string from the API
      final dateStr = event['date'];
      print('Raw date string from API: $dateStr');

      final date = DateTime.parse(dateStr);
      print('Parsed date: ${date.year}-${date.month}-${date.day}');

      // Parse start and end times
      final startTimeParts = event['start_time'].split(':');
      final endTimeParts = event['end_time'].split(':');

      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      final endTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      print('Event time range: ${DateFormat('yyyy-MM-dd HH:mm').format(startTime)} to ${DateFormat('yyyy-MM-dd HH:mm').format(endTime)}');

      // Store the event ID in the event object for reference
      final eventData = {
        ...event,
        'eventId': event['id'].toString(),
      };

      // Determine the color to use
      Color eventColor;
      if (event['color'] != null) {
        print('Using hex color from event: ${event['color']}');
        eventColor = _hexToColor(event['color']);
      } else if (event['color_name'] != null) {
        print('Using color name from event: ${event['color_name']}');
        eventColor = _getColorFromName(event['color_name']);
      } else {
        print('No color info found, using default blue');
        eventColor = Colors.blue;
      }
      print('Final color for event: $eventColor');

      // Create the CalendarEventData with the correct date
      final calendarEvent = CalendarEventData(
        title: event['title'],
        description: event['description'] ?? '',
        date: date,  // Use the parsed date from the API
        startTime: startTime,
        endTime: endTime,
        color: eventColor,
        event: eventData, // Store the original event data with ID
      );

      print('Created CalendarEventData for ${event['title']} on ${DateFormat('yyyy-MM-dd').format(date)}');
      return calendarEvent;
    } catch (e) {
      print('ERROR parsing event data: $e');
      print('Stack trace: ${StackTrace.current}');

      // Create a fallback event with current date if parsing fails
      final now = DateTime.now();
      print('Using fallback date: ${now.year}-${now.month}-${now.day}');

      return CalendarEventData(
        title: event['title'] ?? 'Unknown Event',
        description: event['description'] ?? '',
        date: now,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        color: Colors.red, // Use red to indicate an error
        event: {'id': event['id'], 'eventId': event['id'].toString(), 'error': 'Failed to parse date'},
      );
    }
  }

  // FINAL SOLUTION: Get events for a specific month
  Future<List<CalendarEventData<Object?>>> getEventsForMonth(int year, int month) async {
    try {
      final headers = await _getHeaders();

      // Add a timeout to the request
      final url = '${baseUrl}month/?year=$year&month=$month';
      print('FINAL SOLUTION: Fetching events from: $url');
      print('FINAL SOLUTION: Using headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your server.');
        },
      );

      print('FINAL SOLUTION: Response status: ${response.statusCode}');
      print('FINAL SOLUTION: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('FINAL SOLUTION: Successfully loaded ${data.length} events from API for $year-$month');

        // Convert API data to CalendarEventData objects
        final events = data.map((event) => _convertToCalendarEventData(event)).toList();

        // IMPORTANT: Strictly verify that events are for the correct month
        print('FINAL SOLUTION: Strictly verifying events are for month $year-$month');
        final filteredEvents = events.where((event) {
          final isCorrectMonth = event.date.year == year && event.date.month == month;
          if (!isCorrectMonth) {
            print('FINAL SOLUTION: WARNING: Event ${event.title} has date ${event.date.year}-${event.date.month}-${event.date.day} but was returned for month $year-$month');
          } else {
            print('FINAL SOLUTION: VALID: Event ${event.title} has correct date ${event.date.year}-${event.date.month}-${event.date.day} for month $year-$month');
          }
          return isCorrectMonth;
        }).toList();

        print('FINAL SOLUTION: After strict filtering: ${filteredEvents.length} events for month $year-$month');

        // Print all filtered events for debugging
        for (var event in filteredEvents) {
          print('FINAL SOLUTION: Filtered event: ${event.title} on ${DateFormat('yyyy-MM-dd').format(event.date)}');
        }

        return filteredEvents;
      } else {
        print('FINAL SOLUTION: Failed to load events: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('FINAL SOLUTION: Error fetching events: $e');
      print('FINAL SOLUTION: Error type: ${e.runtimeType}');
      print('FINAL SOLUTION: Stack trace: ${StackTrace.current}');

      // Check if it's a connection error
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        print('FINAL SOLUTION: Connection error: The Django server is not running. Please start the server.');
      }

      return [];
    }
  }

  // Return sample events for testing
  List<CalendarEventData<Object?>> _getSampleEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    final threeDaysLater = today.add(const Duration(days: 3));
    final fourDaysLater = today.add(const Duration(days: 4));
    final fiveDaysLater = today.add(const Duration(days: 5));
    final nextWeek = today.add(const Duration(days: 7));

    print('Creating sample events for testing');

    return [
      // Today's events
      CalendarEventData(
        title: 'Team Meeting',
        description: 'Weekly team sync-up',
        date: today,
        startTime: DateTime(today.year, today.month, today.day, 10, 0),
        endTime: DateTime(today.year, today.month, today.day, 11, 0),
        color: Colors.blue,
        event: {'id': 'sample-1', 'eventId': 'sample-1'},
      ),
      CalendarEventData(
        title: 'Lunch with Client',
        description: 'Discuss project requirements',
        date: today,
        startTime: DateTime(today.year, today.month, today.day, 13, 0),
        endTime: DateTime(today.year, today.month, today.day, 14, 30),
        color: Colors.green,
        event: {'id': 'sample-2', 'eventId': 'sample-2'},
      ),
      CalendarEventData(
        title: 'Project Review',
        description: 'Review project progress',
        date: today,
        startTime: DateTime(today.year, today.month, today.day, 15, 0),
        endTime: DateTime(today.year, today.month, today.day, 16, 0),
        color: Colors.deepPurple,
        event: {'id': 'sample-10', 'eventId': 'sample-10'},
      ),
      CalendarEventData(
        title: 'Call with Vendor',
        description: 'Discuss delivery timeline',
        date: today,
        startTime: DateTime(today.year, today.month, today.day, 17, 0),
        endTime: DateTime(today.year, today.month, today.day, 17, 30),
        color: Colors.indigo,
        event: {'id': 'sample-11', 'eventId': 'sample-11'},
      ),
      // Tomorrow's events
      CalendarEventData(
        title: 'Project Deadline',
        description: 'Submit final deliverables',
        date: tomorrow,
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 17, 0),
        color: Colors.red,
        event: {'id': 'sample-3', 'eventId': 'sample-3'},
      ),
      CalendarEventData(
        title: 'Team Dinner',
        description: 'Celebrate project completion',
        date: tomorrow,
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 21, 0),
        color: Colors.amber,
        event: {'id': 'sample-4', 'eventId': 'sample-4'},
      ),
      CalendarEventData(
        title: 'Morning Standup',
        description: 'Daily team standup',
        date: tomorrow,
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 30),
        color: Colors.lightBlue,
        event: {'id': 'sample-12', 'eventId': 'sample-12'},
      ),
      CalendarEventData(
        title: 'Client Demo',
        description: 'Demo new features to client',
        date: tomorrow,
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 15, 30),
        color: Colors.teal,
        event: {'id': 'sample-13', 'eventId': 'sample-13'},
      ),
      // Day after tomorrow's events
      CalendarEventData(
        title: 'Doctor Appointment',
        description: 'Annual checkup',
        date: dayAfterTomorrow,
        startTime: DateTime(dayAfterTomorrow.year, dayAfterTomorrow.month, dayAfterTomorrow.day, 14, 0),
        endTime: DateTime(dayAfterTomorrow.year, dayAfterTomorrow.month, dayAfterTomorrow.day, 15, 0),
        color: Colors.purple,
        event: {'id': 'sample-5', 'eventId': 'sample-5'},
      ),
      // Three days later events
      CalendarEventData(
        title: 'Gym Session',
        description: 'Weekly workout',
        date: threeDaysLater,
        startTime: DateTime(threeDaysLater.year, threeDaysLater.month, threeDaysLater.day, 7, 0),
        endTime: DateTime(threeDaysLater.year, threeDaysLater.month, threeDaysLater.day, 8, 30),
        color: Colors.teal,
        event: {'id': 'sample-6', 'eventId': 'sample-6'},
      ),
      // Four days later events
      CalendarEventData(
        title: 'Movie Night',
        description: 'Watch new releases',
        date: fourDaysLater,
        startTime: DateTime(fourDaysLater.year, fourDaysLater.month, fourDaysLater.day, 19, 0),
        endTime: DateTime(fourDaysLater.year, fourDaysLater.month, fourDaysLater.day, 22, 0),
        color: Colors.indigo,
        event: {'id': 'sample-7', 'eventId': 'sample-7'},
      ),
      // Five days later events
      CalendarEventData(
        title: 'Shopping',
        description: 'Buy groceries',
        date: fiveDaysLater,
        startTime: DateTime(fiveDaysLater.year, fiveDaysLater.month, fiveDaysLater.day, 10, 0),
        endTime: DateTime(fiveDaysLater.year, fiveDaysLater.month, fiveDaysLater.day, 12, 0),
        color: Colors.brown,
        event: {'id': 'sample-8', 'eventId': 'sample-8'},
      ),
      // Next week's events
      CalendarEventData(
        title: 'Conference',
        description: 'Annual industry conference',
        date: nextWeek,
        startTime: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 9, 0),
        endTime: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 18, 0),
        color: Colors.orange,
        event: {'id': 'sample-9', 'eventId': 'sample-9'},
      ),
    ];
  }

  // Get events for a date range
  Future<List<CalendarEventData<Object?>>> getEventsForRange(DateTime start, DateTime end) async {
    try {
      final headers = await _getHeaders();
      final startFormatted = DateFormat('yyyy-MM-dd').format(start);
      final endFormatted = DateFormat('yyyy-MM-dd').format(end);

      print('Fetching events for range: $startFormatted to $endFormatted');
      final response = await http.get(
        Uri.parse('${baseUrl}range/?start_date=$startFormatted&end_date=$endFormatted'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your server.');
        },
      );

      print('Range API response status: ${response.statusCode}');
      print('Range API response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully loaded ${data.length} events for range from API');

        // Convert API data to CalendarEventData objects
        final events = data.map((event) => _convertToCalendarEventData(event)).toList();

        // Verify that events are within the date range
        print('Verifying events are within range $startFormatted to $endFormatted');
        final filteredEvents = events.where((event) {
          // Use inclusive comparison for start and end dates
          final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
          final startDate = DateTime(start.year, start.month, start.day);
          final endDate = DateTime(end.year, end.month, end.day);

          final isInRange = (eventDate.isAtSameMomentAs(startDate) || eventDate.isAfter(startDate)) &&
                           (eventDate.isAtSameMomentAs(endDate) || eventDate.isBefore(endDate));

          if (!isInRange) {
            print('WARNING: Event ${event.title} has date ${DateFormat('yyyy-MM-dd').format(event.date)} but was returned for range $startFormatted to $endFormatted');
          } else {
            print('VALID RANGE: Event ${event.title} has date ${DateFormat('yyyy-MM-dd').format(event.date)} within range $startFormatted to $endFormatted');
          }
          return isInRange;
        }).toList();

        print('After filtering: ${filteredEvents.length} events for range');

        // Print all filtered events for debugging
        for (var event in filteredEvents) {
          print('Range filtered event: ${event.title} on ${DateFormat('yyyy-MM-dd').format(event.date)}');
        }

        return filteredEvents;
      } else {
        print('Failed to load events: ${response.statusCode}');
        // For testing purposes, return sample events when the server is not available
        if (response.statusCode == 404 || response.statusCode >= 500) {
          return _getSampleEvents().where((event) {
            final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
            final startDate = DateTime(start.year, start.month, start.day);
            final endDate = DateTime(end.year, end.month, end.day);

            return (eventDate.isAtSameMomentAs(startDate) || eventDate.isAfter(startDate)) &&
                   (eventDate.isAtSameMomentAs(endDate) || eventDate.isBefore(endDate));
          }).toList();
        }
        return [];
      }
    } catch (e) {
      print('Error fetching events for range: $e');
      print('Stack trace: ${StackTrace.current}');

      // For testing purposes, return sample events when there's a connection error
      print('Returning sample events due to API error in getEventsForRange');
      final sampleEvents = _getSampleEvents();
      return sampleEvents.where((event) {
        final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);

        return (eventDate.isAtSameMomentAs(startDate) || eventDate.isAfter(startDate)) &&
               (eventDate.isAtSameMomentAs(endDate) || eventDate.isBefore(endDate));
      }).toList();
    }
  }

  // Get events for a specific day
  Future<List<CalendarEventData<Object?>>> getEventsForDay(DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateFormatted = DateFormat('yyyy-MM-dd').format(date);

      print('Fetching events for day: $dateFormatted');
      final response = await http.get(
        Uri.parse('${baseUrl}day/?date=$dateFormatted'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your server.');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully loaded ${data.length} events for day $dateFormatted');

        // Convert API data to CalendarEventData objects
        final events = data.map((event) => _convertToCalendarEventData(event)).toList();

        // Verify that events are for the correct day
        print('Verifying events are for day $dateFormatted');
        final filteredEvents = events.where((event) {
          final isCorrectDay = event.date.year == date.year &&
                              event.date.month == date.month &&
                              event.date.day == date.day;
          if (!isCorrectDay) {
            print('WARNING: Event ${event.title} has date ${DateFormat('yyyy-MM-dd').format(event.date)} but was returned for day $dateFormatted');
          }
          return isCorrectDay;
        }).toList();

        print('After filtering: ${filteredEvents.length} events for day $dateFormatted');
        return filteredEvents;
      } else {
        print('Failed to load events: ${response.statusCode}');
        // For testing purposes, return sample events when the server is not available
        if (response.statusCode == 404 || response.statusCode >= 500) {
          return _getSampleEvents().where((event) =>
            event.date.year == date.year &&
            event.date.month == date.month &&
            event.date.day == date.day
          ).toList();
        }
        return [];
      }
    } catch (e) {
      print('Error fetching events: $e');
      // For testing purposes, return sample events when there's a connection error
      return _getSampleEvents().where((event) =>
        event.date.year == date.year &&
        event.date.month == date.month &&
        event.date.day == date.day
      ).toList();
    }
  }

  // Create a new event
  Future<CalendarEventData<Object?>?> createEvent(CalendarEventData<Object?> event) async {
    try {
      // Validate event times
      if (event.startTime == null || event.endTime == null) {
        print('Failed to add event: Start time or end time is null');
        return null;
      }

      if (event.endTime!.isBefore(event.startTime!) || event.endTime!.isAtSameMomentAs(event.startTime!)) {
        print('Failed to add event: End time occurs before or at the same time as start time');
        return null;
      }
      print('Creating event: ${event.title} on ${event.date}');
      print('Event details: startTime=${event.startTime}, endTime=${event.endTime}, color=${event.color}');

      final headers = await _getHeaders();
      print('Headers: $headers');

      // Format the data for the API
      final Map<String, dynamic> eventData = {
        'title': event.title,
        'description': event.description ?? '',
        'date': DateFormat('yyyy-MM-dd').format(event.date),
        'start_time': DateFormat('HH:mm:ss').format(event.startTime ?? event.date),
        'end_time': DateFormat('HH:mm:ss').format(event.endTime ?? event.date),
        'color': _colorToHex(event.color),
      };

      print('Sending event data: $eventData');

      try {
        print('Sending POST request to: $baseUrl');
        print('With headers: $headers');
        print('And body: ${json.encode(eventData)}');

        final response = await http.post(
          Uri.parse(baseUrl),
          headers: headers,
          body: json.encode(eventData),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Connection timed out. Please check your server.');
          },
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          return _convertToCalendarEventData(data);
        } else {
          print('Failed to create event: ${response.statusCode}');
          print('Response: ${response.body}');

          // Don't create mock events when server returns error
          if (response.statusCode == 404 || response.statusCode >= 500) {
            print('Server error: ${response.statusCode}');
            print('Cannot create event due to server error');
            return null;
          }

          return null;
        }
      } catch (httpError) {
        print('HTTP error: $httpError');
        throw httpError; // Re-throw to be caught by the outer try-catch
      }
    } catch (e) {
      print('Error creating event: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');

      // Check if it's a connection error
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        print('Connection error: The Django server is not running. Please start the server.');
      }

      // Don't create mock events when there's an exception
      print('Cannot create event due to exception');
      return null;
    }
  }

  // Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl$eventId/'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your server.');
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting event: $e');

      // Don't simulate successful deletion
      print('Cannot delete event due to error');
      return false;
    }
  }

  // Update an event
  Future<CalendarEventData<Object?>?> updateEvent(String eventId, CalendarEventData<Object?> event) async {
    try {
      final headers = await _getHeaders();

      // Format the data for the API
      final Map<String, dynamic> eventData = {
        'title': event.title,
        'description': event.description,
        'date': DateFormat('yyyy-MM-dd').format(event.date),
        'start_time': DateFormat('HH:mm:ss').format(event.startTime ?? event.date),
        'end_time': DateFormat('HH:mm:ss').format(event.endTime ?? event.date),
        'color': _colorToHex(event.color),
      };

      final response = await http.put(
        Uri.parse('$baseUrl$eventId/'),
        headers: headers,
        body: json.encode(eventData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _convertToCalendarEventData(data);
      } else {
        print('Failed to update event: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating event: $e');
      return null;
    }
  }

  // Get upcoming events (events from today onwards)
  Future<List<CalendarEventData<Object?>>> getUpcomingEvents({int limit = 5}) async {
    try {
      final today = DateTime.now();
      // Get events for the next 60 days to ensure we have enough events
      final endDate = today.add(const Duration(days: 60));

      print('Fetching upcoming events from ${DateFormat('yyyy-MM-dd').format(today)} to ${DateFormat('yyyy-MM-dd').format(endDate)}');

      // Use the existing getEventsForRange method which we know works
      final allEvents = await getEventsForRange(today, endDate);
      print('Fetched ${allEvents.length} events in date range');

      // Sort by date and time
      allEvents.sort((a, b) {
        // First compare by date
        final dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) return dateComparison;

        // If same date, compare by start time
        return (a.startTime ?? a.date).compareTo(b.startTime ?? b.date);
      });

      // Group events by date
      Map<String, List<CalendarEventData<Object?>>> eventsByDate = {};

      for (var event in allEvents) {
        final dateKey = DateFormat('yyyy-MM-dd').format(event.date);
        if (!eventsByDate.containsKey(dateKey)) {
          eventsByDate[dateKey] = [];
        }
        eventsByDate[dateKey]!.add(event);
      }

      // Get events from multiple dates (up to 5 dates)
      List<CalendarEventData<Object?>> events = [];
      final sortedDates = eventsByDate.keys.toList()..sort();

      // Take up to 5 dates
      final datesToInclude = sortedDates.take(5).toList();
      print('Including events from dates: $datesToInclude');

      // Add events from each date
      for (var dateKey in datesToInclude) {
        // Sort events for this date by time
        eventsByDate[dateKey]!.sort((a, b) =>
            (a.startTime ?? a.date).compareTo(b.startTime ?? b.date));

        // Add all events for this date
        final dateEvents = eventsByDate[dateKey]!.toList();
        events.addAll(dateEvents);
      }

      print('Returning ${events.length} upcoming events from ${datesToInclude.length} different dates');

      // Print details of each event for debugging
      for (var i = 0; i < events.length; i++) {
        final event = events[i];
        print('Event $i: ${event.title} on ${DateFormat('yyyy-MM-dd').format(event.date)} at ${event.startTime != null ? DateFormat('HH:mm').format(event.startTime!) : "All day"}');
      }

      return events;
    } catch (e) {
      print('Error fetching upcoming events: $e');
      print('Stack trace: ${StackTrace.current}');

      // Return sample events for testing when API fails
      print('Returning sample events due to API error');
      final sampleEvents = _getSampleEvents();

      // Group sample events by date
      Map<String, List<CalendarEventData<Object?>>> eventsByDate = {};

      for (var event in sampleEvents) {
        final dateKey = DateFormat('yyyy-MM-dd').format(event.date);
        if (!eventsByDate.containsKey(dateKey)) {
          eventsByDate[dateKey] = [];
        }
        eventsByDate[dateKey]!.add(event);
      }

      // Get events from multiple dates
      List<CalendarEventData<Object?>> events = [];
      final sortedDates = eventsByDate.keys.toList()..sort();

      // Take up to 5 dates
      final datesToInclude = sortedDates.take(5).toList();
      print('Including sample events from dates: $datesToInclude');

      // Add events from each date
      for (var dateKey in datesToInclude) {
        // Sort events for this date by time
        eventsByDate[dateKey]!.sort((a, b) =>
            (a.startTime ?? a.date).compareTo(b.startTime ?? b.date));

        // Add all events for this date
        final dateEvents = eventsByDate[dateKey]!.toList();
        events.addAll(dateEvents);
      }

      return events;
    }
  }
}
