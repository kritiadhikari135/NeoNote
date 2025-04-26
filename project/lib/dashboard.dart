
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/widgets/custom_scaffold.dart'; // Import your reusable scaffold
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'package:project/services/local_storage.dart';
import 'package:project/services/user_service.dart'; // Import UserService
import 'package:project/personalScreen/content_page.dart';
import 'package:project/providers/pages_provider.dart';
import 'package:project/services/diary_service.dart';
import 'package:project/personalScreen/newPages/Openned_diary.dart';
import 'package:project/personalScreen/diary_page.dart';
import 'package:intl/intl.dart';
import 'package:project/services/calendar_service.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:project/app_router.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // String _selectedPage = "Home"; // Tracks which page is active
  // String _fullName = 'Loading...';
  String _selectedPage = "Home";
  String _fullName = 'Loading...';
  List<String> _pages = [];
  List<dynamic> _recentDiaries = [];
  bool _isLoadingDiaries = false;

  // Calendar service and upcoming events
  final CalendarService _calendarService = CalendarService();
  List<CalendarEventData<Object?>> _upcomingEvents = [];
  bool _isLoadingEvents = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData(); // Ensure it runs after the first frame is built
      _fetchRecentDiaries(); // Fetch recent diary entries
      _fetchUserPages(); // Fetch user's content pages
      _fetchUpcomingEvents(); // Fetch upcoming calendar events
    });
  }

  // Fetch upcoming calendar events
  Future<void> _fetchUpcomingEvents() async {
    try {
      print('Starting to fetch upcoming events');
      setState(() {
        _isLoadingEvents = true;
      });

      // Get upcoming events (limit to 5 dates, showing all events per date)
      final events = await _calendarService.getUpcomingEvents(limit: 5);

      print('Dashboard received ${events.length} upcoming events');
      if (events.isNotEmpty) {
        // Group events by date for logging
        Map<String, List<CalendarEventData<Object?>>> eventsByDate = {};

        for (var event in events) {
          final dateKey = DateFormat('yyyy-MM-dd').format(event.date);
          if (!eventsByDate.containsKey(dateKey)) {
            eventsByDate[dateKey] = [];
          }
          eventsByDate[dateKey]!.add(event);
          print('Event: ${event.title}, Date: ${DateFormat('yyyy-MM-dd').format(event.date)}, Start: ${event.startTime != null ? DateFormat('HH:mm').format(event.startTime!) : "All day"}');
        }

        // Log events by date
        print('Events grouped by date:');
        eventsByDate.forEach((date, dateEvents) {
          print('Date: $date, Events: ${dateEvents.length}');
          for (var event in dateEvents) {
            print('  - ${event.title}');
          }
        });
      } else {
        print('No upcoming events received');
      }

      setState(() {
        _upcomingEvents = events;
        _isLoadingEvents = false;
      });
    } catch (e) {
      print('Error fetching upcoming events: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  // Fetch user's content pages
  Future<void> _fetchUserPages() async {
    try {
      // Access the PagesProvider and fetch pages
      final pagesProvider = Provider.of<PagesProvider>(context, listen: false);
      await pagesProvider.fetchPages();
      print('✅ User pages fetched successfully');
    } catch (e) {
      print('❌ Error fetching user pages: $e');
    }
  }

  // Fetch recent diary entries
  Future<void> _fetchRecentDiaries() async {
    try {
      setState(() {
        _isLoadingDiaries = true;
      });

      // Create an instance of DiaryService
      final diaryService = DiaryService();

      // Fetch all diary entries
      final entries = await diaryService.getAllEntries();

      // Sort entries by updated_at or created_at in descending order (newest first)
      entries.sort((a, b) {
        final dateA = a.updatedAt ?? a.createdAt ?? a.date;
        final dateB = b.updatedAt ?? b.createdAt ?? b.date;
        return dateB.compareTo(dateA);
      });

      // Take the 7 most recent entries
      final recentEntries = entries.take(7).toList();

      // Convert DiaryEntry objects to maps for easier use in the UI
      final recentDiaries = recentEntries.map((entry) => {
        'id': entry.id,
        'title': entry.title,
        'content': entry.content,
        'date': entry.date.toIso8601String(),
        'backgroundColor': entry.backgroundColor,
        'textColor': entry.textColor,
        'template': entry.template,
      }).toList();

      setState(() {
        _recentDiaries = recentDiaries;
        _isLoadingDiaries = false;
      });

      print('Fetched ${_recentDiaries.length} recent diary entries');
    } catch (e) {
      print('Error fetching recent diaries: $e');
      setState(() {
        _isLoadingDiaries = false;
      });
    }
  }




  Future<void> _fetchUserData() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // final token = prefs.getString('access_token');
      String? token = await LocalStorage.getToken();

      if (token == null) {
        print("Token is null. Redirecting to login.");
        _redirectToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/accounts/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('full_name')) {
          setState(() {
            _fullName = data['full_name'];
          });
        } else {
          print("Key 'full_name' not found in response: $data");
        }
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

void _redirectToLogin() {
  Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
}

// Navigate to create a new diary entry
Future<void> _navigateToNewDiary() async {
  try {
    print('Navigating to new diary page');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewDiaryPage(),
      ),
    );

    if (result != null && mounted) {
      print('New diary created, refreshing list');
      await _fetchRecentDiaries(); // Refresh the recent diaries
    }
  } catch (e) {
    print('Error navigating to new diary page: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating new diary entry')),
      );
    }
  }
}

// Navigate to a diary entry
Future<void> _openDiary(dynamic diary) async {
  try {
    print('Opening diary: $diary');

    // Pass the diary map directly (no need to serialize)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewDiaryPage(initialData: diary),
      ),
    );

    if (result != null && mounted) {
      print('Diary updated, refreshing list');
      await _fetchRecentDiaries(); // Refresh the recent diaries
    }
  } catch (e) {
    print('Error opening diary: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening diary entry')),
      );
    }
  }
}



Future<void> _logout() async {
  // Clear token from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('user_pages'); // Remove token from SharedPreferences

  // Clear token from LocalStorage (flutter_secure_storage)
  await LocalStorage.clearToken(); // Assuming LocalStorage handles secure storage

  // Clear cached user ID
  UserService.clearCachedUserId();
  print('✅ Cleared cached user ID');

  // Clear any cached data or pages
  setState(() {
    _fullName = 'Loading...';  // Reset user data
    _pages = [];  // Clear cached pages or session data
  });

  // Clear in-memory data using provider
  Provider.of<PagesProvider>(context, listen: false).clearPages();
  print('✅ Cleared pages from PagesProvider');

  // Check if token was cleared from LocalStorage
  String? storedToken = await LocalStorage.getToken();
  print("Token after logout: $storedToken");  // Should print null after logout

  // Optionally, check if the token is also cleared from SharedPreferences (for debug purposes)
  String? storedPrefToken = prefs.getString('access_token');
  print("Token from SharedPreferences after logout: $storedPrefToken");

  String? storedPages = prefs.getString('user_pages');
  print("Stored pages after logout: $storedPages");  // Should print null after logout

  // Redirect to login page
  _redirectToLogin();
}

// Helper method to clean title text that might be in JSON format
String _cleanTitle(String title) {
  try {
    // Check if the title is in JSON format
    if (title.startsWith('[') || title.startsWith('{')) {
      final jsonData = json.decode(title);
      if (jsonData is List && jsonData.isNotEmpty) {
        // Extract text from Delta format if possible
        String extractedTitle = '';
        for (var op in jsonData) {
          if (op is Map && op.containsKey('insert') && op['insert'] is String) {
            extractedTitle += op['insert'];
          }
        }
        return extractedTitle.isNotEmpty ? extractedTitle.trim() : 'Untitled';
      } else {
        return 'Untitled';
      }
    }
    return title.trim();
  } catch (e) {
    print('Error cleaning title: $e');
    return title.trim();
  }
}

// Build cards for upcoming events
List<Widget> _buildUpcomingEventCards() {
  print('Building upcoming event cards from ${_upcomingEvents.length} events');

  if (_upcomingEvents.isEmpty) {
    print('No events to display');
    return [
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No upcoming events',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      )
    ];
  }

  print('Building cards for ${_upcomingEvents.length} events');

  // Group events by date
  Map<String, List<CalendarEventData<Object?>>> eventsByDate = {};

  for (var event in _upcomingEvents) {
    // Format the date as a string key
    final dateKey = DateFormat('yyyy-MM-dd').format(event.date);
    print('Adding event "${event.title}" to date $dateKey');

    // Add to the map
    if (!eventsByDate.containsKey(dateKey)) {
      eventsByDate[dateKey] = [];
    }
    eventsByDate[dateKey]!.add(event);
  }

  // Sort dates
  final sortedDates = eventsByDate.keys.toList()..sort();
  print('Sorted dates: $sortedDates');

  // Build a card for each date
  return sortedDates.map((dateKey) {
    final events = eventsByDate[dateKey]!;
    final date = DateTime.parse(dateKey);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;

    // Format the date header
    final dateHeader = isToday
        ? 'Today, ${DateFormat('MMMM d').format(date)}'
        : '${DateFormat('EEEE, MMMM d').format(date)}';

    // Sort events by start time
    events.sort((a, b) =>
        (a.startTime ?? a.date).compareTo(b.startTime ?? b.date));

    // Build the event items
    final eventItems = <Widget>[];

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final startTime = event.startTime != null
          ? DateFormat('h:mm a').format(event.startTime!)
          : 'All day';

      // Add the event text
      eventItems.add(
        Text(
          '$startTime, ${event.title}',
          style: const TextStyle(fontSize: 14),
        )
      );

      // Add spacing between items (except after the last item)
      if (i < events.length - 1) {
        eventItems.add(const SizedBox(height: 4));
      }
    }

    // Return a card with the date and events
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to the calendar page
          Navigator.pushNamed(context, AppRouter.calendarRoute);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading icon
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 16),
                child: Icon(
                  Icons.calendar_today,
                  color: const Color(0xFF255DE1),
                  size: 24,
                ),
              ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Text(
                      dateHeader,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Event items - make it scrollable if there are many events
                    eventItems.length <= 4
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: eventItems,
                        )
                      : Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: eventItems,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }).toList();
}



  // Refresh all dashboard data
  Future<void> _refreshDashboard() async {
    await Future.wait([
      _fetchRecentDiaries(),
      _fetchUpcomingEvents(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: _selectedPage,
      onItemSelected: (page) {
        setState(() {
          _selectedPage = page;
        });
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Container(
            color: const Color.fromARGB(255, 37, 93, 225),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(), // This pushes the text to the center
                Text(
                  'Good Morning, $_fullName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(), // This ensures the text stays centered
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
          // Dashboard Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDashboard,
              color: const Color(0xFF255DE1),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recents Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.menu_book,
                            size: 24,
                            color: Color(0xFF255DE1),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Recent Diaries',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/diary');
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("View All"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF255DE1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoadingDiaries
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _recentDiaries.isEmpty
                      ? const Center(
                          child: Text(
                            'No recent diary entries',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                          child: Row(
                            children: [
                              // Add a "New Entry" card at the beginning
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: InkWell(
                                    onTap: _navigateToNewDiary,
                                    child: Container(
                                      width: 120,
                                      height: 160,
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3F2FD),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.3),
                                                  spreadRadius: 1,
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.add_circle_outline, size: 30, color: Color(0xFF255DE1)),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'New Entry',
                                            style: TextStyle(fontSize: 14),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Generate cards for recent diary entries
                              ...List.generate(
                                _recentDiaries.length,
                                (index) {
                                  final diary = _recentDiaries[index];
                                  final date = DateTime.parse(diary['date']);

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: InkWell(
                                        onTap: () => _openDiary(diary),
                                        child: Container(
                                          width: 120,
                                          height: 160,
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE3F2FD),
                                                  borderRadius: BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.withOpacity(0.3),
                                                      spreadRadius: 1,
                                                      blurRadius: 2,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.menu_book, size: 30, color: Color(0xFF255DE1)),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                diary['title'] != null ? _cleanTitle(diary['title'].toString()) : DateFormat('MMM d').format(date),
                                                style: const TextStyle(fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                DateFormat('MMM d').format(date),
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 20),
                  // Upcoming Events Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.event,
                            size: 24,
                            color: Color(0xFF255DE1),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Upcoming Events',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRouter.calendarRoute);
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("View All"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF255DE1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoadingEvents
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Column(
                        children: _buildUpcomingEventCards(),
                      ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
