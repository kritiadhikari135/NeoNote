import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/models/page.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/diary_service.dart';
import 'package:project/services/api_service.dart';
import 'package:project/services/goal_service.dart';
import 'package:project/services/user_service.dart'; // Import UserService
import 'package:project/providers/pages_provider.dart';
import 'package:provider/provider.dart';
import 'package:project/personalScreen/content_page.dart';
import 'package:project/personalScreen/newPages/Openned_diary.dart';
import 'package:project/personalScreen/goal.dart';
import 'package:project/widgets/custom_scaffold.dart';

// Model for deleted pages
class DeletedPage {
  final PageModel page;
  final DateTime deletedAt;
  final String userId; // Add userId field

  DeletedPage({required this.page, required this.deletedAt, required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'page': {
        'id': page.id,
        'title': page.title,
        'content': page.content,
      },
      'deletedAt': deletedAt.toIso8601String(),
      'userId': userId, // Include userId in JSON
    };
  }

  factory DeletedPage.fromJson(Map<String, dynamic> json) {
    // Handle case where userId might be missing in older data
    String userId = 'default_user'; // Default user ID
    if (json.containsKey('userId') && json['userId'] != null && json['userId'] != '') {
      userId = json['userId'];
    }

    return DeletedPage(
      page: PageModel(
        id: json['page']['id'],
        title: json['page']['title'],
        content: json['page']['content'],
      ),
      deletedAt: DateTime.parse(json['deletedAt']),
      userId: userId,
    );
  }
}

// Model for deleted diaries
class DeletedDiary {
  final DiaryEntry diary;
  final DateTime deletedAt;
  final String userId; // Add userId field

  DeletedDiary({required this.diary, required this.deletedAt, required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'diary': diary.toJson(),
      'deletedAt': deletedAt.toIso8601String(),
      'userId': userId, // Include userId in JSON
    };
  }

  factory DeletedDiary.fromJson(Map<String, dynamic> json) {
    // Handle case where userId might be missing in older data
    String userId = 'default_user'; // Default user ID
    if (json.containsKey('userId') && json['userId'] != null && json['userId'] != '') {
      userId = json['userId'];
    }

    return DeletedDiary(
      diary: DiaryEntry.fromJson(json['diary']),
      deletedAt: DateTime.parse(json['deletedAt']),
      userId: userId,
    );
  }
}

// Model for deleted goals
class DeletedGoal {
  final Goal goal;
  final DateTime deletedAt;
  final String userId; // Add userId field

  DeletedGoal({required this.goal, required this.deletedAt, required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'goal': {
        'id': goal.id,
        'title': goal.title,
        'startDate': goal.startDate.toIso8601String(),
        'completionDate': goal.completionDate.toIso8601String(),
        'isCompleted': goal.isCompleted,
        'completionTime': goal.completionTime?.toIso8601String(),
        'user': goal.user,
        'createdBy': goal.createdBy,
        'createdAt': goal.createdAt.toIso8601String(),
        'lastModifiedBy': goal.lastModifiedBy,
        'lastModifiedAt': goal.lastModifiedAt.toIso8601String(),
        'tasks': goal.tasks.map((task) => {
          'id': task.id,
          'title': task.title,
          'status': task.status,
          'priority': task.priority,
          'dueDate': task.dueDate?.toIso8601String(),
          'dateCreated': task.dateCreated.toIso8601String(),
          'goal': task.goal,
        }).toList(),
      },
      'deletedAt': deletedAt.toIso8601String(),
      'userId': userId, // Include userId in JSON
    };
  }

  factory DeletedGoal.fromJson(Map<String, dynamic> json) {
    final goalJson = json['goal'];
    final tasksJson = goalJson['tasks'] as List;

    // Handle case where userId might be missing in older data
    String userId = 'default_user'; // Default user ID
    if (json.containsKey('userId') && json['userId'] != null && json['userId'] != '') {
      userId = json['userId'];
    }

    return DeletedGoal(
      goal: Goal(
        id: goalJson['id'],
        title: goalJson['title'],
        startDate: DateTime.parse(goalJson['startDate']),
        completionDate: DateTime.parse(goalJson['completionDate']),
        isCompleted: goalJson['isCompleted'],
        completionTime: goalJson['completionTime'] != null
            ? DateTime.parse(goalJson['completionTime'])
            : null,
        user: goalJson['user'],
        createdBy: goalJson['createdBy'],
        createdAt: DateTime.parse(goalJson['createdAt']),
        lastModifiedBy: goalJson['lastModifiedBy'],
        lastModifiedAt: DateTime.parse(goalJson['lastModifiedAt']),
        tasks: tasksJson.map((taskJson) => GoalTask(
          id: taskJson['id'],
          title: taskJson['title'],
          status: taskJson['status'],
          priority: taskJson['priority'],
          dueDate: taskJson['dueDate'] != null
              ? DateTime.parse(taskJson['dueDate'])
              : null,
          dateCreated: DateTime.parse(taskJson['dateCreated']),
          goal: taskJson['goal'],
        )).toList(),
      ),
      deletedAt: DateTime.parse(json['deletedAt']),
      userId: userId,
    );
  }
}

// Provider for managing deleted items
class BinProvider extends ChangeNotifier {
  List<DeletedPage> _deletedPages = [];
  List<DeletedDiary> _deletedDiaries = [];
  List<DeletedGoal> _deletedGoals = [];
  String? _currentUserId;

  // For now, return all items regardless of user ID to ensure items are displayed
  // This is a temporary fix until we properly implement user-specific bins
  List<DeletedPage> get deletedPages {
    print('📊 Total deleted pages: ${_deletedPages.length}');
    if (_currentUserId != null) {
      print('🔍 Current user ID: $_currentUserId');

      // Debug user IDs in deleted pages
      if (_deletedPages.isNotEmpty) {
        print('🔢 User IDs in deleted pages: ${_deletedPages.map((p) => p.userId).toList()}');
      }
    }

    return _deletedPages;
  }

  List<DeletedDiary> get deletedDiaries {
    print('📊 Total deleted diaries: ${_deletedDiaries.length}');
    if (_currentUserId != null) {
      print('🔍 Current user ID: $_currentUserId');

      // Debug user IDs in deleted diaries
      if (_deletedDiaries.isNotEmpty) {
        print('🔢 User IDs in deleted diaries: ${_deletedDiaries.map((d) => d.userId).toList()}');
      }
    }

    return _deletedDiaries;
  }

  List<DeletedGoal> get deletedGoals {
    print('📊 Total deleted goals: ${_deletedGoals.length}');
    if (_currentUserId != null) {
      print('🔍 Current user ID: $_currentUserId');

      // Debug user IDs in deleted goals
      if (_deletedGoals.isNotEmpty) {
        print('🔢 User IDs in deleted goals: ${_deletedGoals.map((g) => g.userId).toList()}');
      }
    }

    return _deletedGoals;
  }

  // Number of days to keep items in bin before permanent deletion
  static const int retentionDays = 30;

  // Key for storing the last check date in SharedPreferences
  static const String _lastCheckKey = 'bin_last_check_date';

  BinProvider() {
    // Load deleted items when the provider is created
    _loadDeletedItems();
    // Set current user ID
    _setCurrentUserId();
    // Check if we need to run the daily cleanup
    _checkDailyCleanup();
  }

  // Check if we need to run the daily cleanup
  Future<void> _checkDailyCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString(_lastCheckKey);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastCheckStr == null) {
        // First time running the app, set today as last check and run cleanup
        await prefs.setString(_lastCheckKey, today.toIso8601String());
        await _removeExpiredItems();
        return;
      }

      final lastCheck = DateTime.parse(lastCheckStr);
      final lastCheckDay = DateTime(lastCheck.year, lastCheck.month, lastCheck.day);

      if (today.isAfter(lastCheckDay)) {
        // It's a new day, run the cleanup
        print('🧹 Running daily cleanup check');
        await _removeExpiredItems();
        await prefs.setString(_lastCheckKey, today.toIso8601String());
      } else {
        print('✅ Already ran cleanup today');
      }
    } catch (e) {
      print('❌ Error checking daily cleanup: $e');
      // Run cleanup anyway to be safe
      await _removeExpiredItems();
    }
  }

  // Set the current user ID
  Future<void> _setCurrentUserId() async {
    try {
      _currentUserId = await UserService.getCurrentUserId();
      print('Current user ID set to: $_currentUserId');
      notifyListeners();
    } catch (e) {
      print('Error setting current user ID: $e');
      // If there's an error, we'll leave _currentUserId as null
      // which will cause the getters to return empty lists
    }
  }

  // Load deleted items from local storage
  Future<void> _loadDeletedItems() async {
    try {
      print('💾 Loading deleted items from local storage');
      final prefs = await SharedPreferences.getInstance();
      String? currentUserId = await UserService.getCurrentUserId();
      print('🔑 Current user ID for loading: $currentUserId');

      // Load deleted pages
      final pagesJson = prefs.getString('deleted_pages');
      print('📃 Raw pages JSON: ${pagesJson != null ? (pagesJson.length > 100 ? pagesJson.substring(0, 100) + '...' : pagesJson) : 'null'}');

      if (pagesJson != null) {
        final List<dynamic> pagesData = jsonDecode(pagesJson);
        print('📂 Found ${pagesData.length} deleted pages in storage');

        _deletedPages = pagesData.map((data) {
          // Handle migration of old data without userId
          if (!data.containsKey('userId')) {
            print('🔧 Migrating page without userId: ${data['page']['title']}');
            // Use current user ID if available, otherwise use default
            data['userId'] = currentUserId ?? 'default_user';
          }
          return DeletedPage.fromJson(data);
        }).toList();
        print('✅ Loaded ${_deletedPages.length} deleted pages');
      } else {
        print('⚠️ No deleted pages found in storage');
      }

      // Load deleted diaries
      final diariesJson = prefs.getString('deleted_diaries');
      print('📃 Raw diaries JSON: ${diariesJson != null ? (diariesJson.length > 100 ? diariesJson.substring(0, 100) + '...' : diariesJson) : 'null'}');

      if (diariesJson != null) {
        final List<dynamic> diariesData = jsonDecode(diariesJson);
        print('📂 Found ${diariesData.length} deleted diaries in storage');

        _deletedDiaries = diariesData.map((data) {
          // Handle migration of old data without userId
          if (!data.containsKey('userId')) {
            print('🔧 Migrating diary without userId: ${data['diary']['title']}');
            // Use current user ID if available, otherwise use default
            data['userId'] = currentUserId ?? 'default_user';
          }
          return DeletedDiary.fromJson(data);
        }).toList();
        print('✅ Loaded ${_deletedDiaries.length} deleted diaries');
      } else {
        print('⚠️ No deleted diaries found in storage');
      }

      // Load deleted goals
      final goalsJson = prefs.getString('deleted_goals');
      print('📃 Raw goals JSON: ${goalsJson != null ? (goalsJson.length > 100 ? goalsJson.substring(0, 100) + '...' : goalsJson) : 'null'}');

      if (goalsJson != null) {
        final List<dynamic> goalsData = jsonDecode(goalsJson);
        print('📂 Found ${goalsData.length} deleted goals in storage');

        _deletedGoals = goalsData.map((data) {
          // Handle migration of old data without userId
          if (!data.containsKey('userId')) {
            print('🔧 Migrating goal without userId: ${data['goal']['title']}');
            // Use current user ID if available, otherwise use default
            data['userId'] = currentUserId ?? 'default_user';
          }
          return DeletedGoal.fromJson(data);
        }).toList();
        print('✅ Loaded ${_deletedGoals.length} deleted goals');
      } else {
        print('⚠️ No deleted goals found in storage');
      }

      // Save migrated data back to storage
      await _saveDeletedItems();
      print('✅ Saved migrated data back to storage');

      notifyListeners();
    } catch (e) {
      print('❌ Error loading deleted items: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Save deleted items to local storage
  Future<void> _saveDeletedItems() async {
    try {
      print('💾 Saving deleted items to local storage');
      final prefs = await SharedPreferences.getInstance();

      // Save deleted pages
      final pagesJson = jsonEncode(_deletedPages.map((page) => page.toJson()).toList());
      await prefs.setString('deleted_pages', pagesJson);
      print('✅ Saved ${_deletedPages.length} pages to storage');

      // Save deleted diaries
      final diariesJson = jsonEncode(_deletedDiaries.map((diary) => diary.toJson()).toList());
      await prefs.setString('deleted_diaries', diariesJson);
      print('✅ Saved ${_deletedDiaries.length} diaries to storage');

      // Save deleted goals
      final goalsJson = jsonEncode(_deletedGoals.map((goal) => goal.toJson()).toList());
      await prefs.setString('deleted_goals', goalsJson);
      print('✅ Saved ${_deletedGoals.length} goals to storage');

      // Verify saved data
      final savedPagesJson = prefs.getString('deleted_pages');
      final savedDiariesJson = prefs.getString('deleted_diaries');
      final savedGoalsJson = prefs.getString('deleted_goals');

      print('🔍 Verification - Pages in storage: ${savedPagesJson != null ? jsonDecode(savedPagesJson).length : 0}');
      print('🔍 Verification - Diaries in storage: ${savedDiariesJson != null ? jsonDecode(savedDiariesJson).length : 0}');
      print('🔍 Verification - Goals in storage: ${savedGoalsJson != null ? jsonDecode(savedGoalsJson).length : 0}');

      print('✅ Successfully saved all deleted items to local storage');
    } catch (e) {
      print('❌ Error saving deleted items: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Add a deleted page
  Future<void> addDeletedPage(PageModel page) async {
    print('📝 Adding page to bin: ${page.title}');
    String userId = 'default_user'; // Default user ID

    try {
      final currentUserId = await UserService.getCurrentUserId();
      if (currentUserId != null) {
        userId = currentUserId;
        print('✅ Got user ID: $userId');
      } else {
        print('⚠️ Using default user ID: $userId');
      }
    } catch (e) {
      print('⚠️ Error getting user ID: $e, using default');
    }

    final deletedPage = DeletedPage(
      page: page,
      deletedAt: DateTime.now(),
      userId: userId,
    );
    _deletedPages.add(deletedPage);
    print('✅ Added page to bin. Total pages: ${_deletedPages.length}');

    await _saveDeletedItems();
    print('✅ Saved deleted items to storage');
    notifyListeners();
  }

  // Add a deleted diary
  Future<void> addDeletedDiary(DiaryEntry diary) async {
    print('📝 Adding diary to bin: ${diary.title}');
    String userId = 'default_user'; // Default user ID

    try {
      final currentUserId = await UserService.getCurrentUserId();
      if (currentUserId != null) {
        userId = currentUserId;
        print('✅ Got user ID: $userId');
      } else {
        print('⚠️ Using default user ID: $userId');
      }
    } catch (e) {
      print('⚠️ Error getting user ID: $e, using default');
    }

    final deletedDiary = DeletedDiary(
      diary: diary,
      deletedAt: DateTime.now(),
      userId: userId,
    );
    _deletedDiaries.add(deletedDiary);
    print('✅ Added diary to bin. Total diaries: ${_deletedDiaries.length}');

    await _saveDeletedItems();
    print('✅ Saved deleted items to storage');
    notifyListeners();
  }

  // Add a deleted goal
  Future<void> addDeletedGoal(Goal goal) async {
    print('📝 Adding goal to bin: ${goal.title}');
    String userId = 'default_user'; // Default user ID

    try {
      final currentUserId = await UserService.getCurrentUserId();
      if (currentUserId != null) {
        userId = currentUserId;
        print('✅ Got user ID: $userId');
      } else {
        print('⚠️ Using default user ID: $userId');
      }
    } catch (e) {
      print('⚠️ Error getting user ID: $e, using default');
    }

    final deletedGoal = DeletedGoal(
      goal: goal,
      deletedAt: DateTime.now(),
      userId: userId,
    );
    _deletedGoals.add(deletedGoal);
    print('✅ Added goal to bin. Total goals: ${_deletedGoals.length}');

    await _saveDeletedItems();
    print('✅ Saved deleted items to storage');
    notifyListeners();
  }

  // Restore a deleted page
  Future<void> restorePage(DeletedPage deletedPage) async {
    try {
      final apiService = ApiService();
      await apiService.createPage(deletedPage.page.title, deletedPage.page.content);
      _deletedPages.remove(deletedPage);
      _saveDeletedItems();
      notifyListeners();
    } catch (e) {
      print('Error restoring page: $e');
      rethrow;
    }
  }

  // Restore a deleted diary
  Future<void> restoreDiary(DeletedDiary deletedDiary) async {
    try {
      final diaryService = DiaryService();
      await diaryService.createEntry(deletedDiary.diary);
      _deletedDiaries.remove(deletedDiary);
      _saveDeletedItems();
      notifyListeners();
    } catch (e) {
      print('Error restoring diary: $e');
      rethrow;
    }
  }

  // Restore a deleted goal
  Future<void> restoreGoal(DeletedGoal deletedGoal) async {
    try {
      await GoalService.createGoal(
        title: deletedGoal.goal.title,
        startDate: deletedGoal.goal.startDate,
        completionDate: deletedGoal.goal.completionDate,
      );
      _deletedGoals.remove(deletedGoal);
      _saveDeletedItems();
      notifyListeners();
    } catch (e) {
      print('Error restoring goal: $e');
      rethrow;
    }
  }

  // Permanently delete a page
  void permanentlyDeletePage(DeletedPage deletedPage) {
    _deletedPages.remove(deletedPage);
    _saveDeletedItems();
    notifyListeners();
  }

  // Permanently delete a diary
  void permanentlyDeleteDiary(DeletedDiary deletedDiary) {
    _deletedDiaries.remove(deletedDiary);
    _saveDeletedItems();
    notifyListeners();
  }

  // Permanently delete a goal
  void permanentlyDeleteGoal(DeletedGoal deletedGoal) {
    _deletedGoals.remove(deletedGoal);
    _saveDeletedItems();
    notifyListeners();
  }

  // Check and remove items that are older than the retention period
  Future<void> _removeExpiredItems() async {
    print('🧹 Checking for expired items (older than $retentionDays days)');
    final now = DateTime.now();
    bool hasRemovedItems = false;

    // Check pages
    final expiredPages = _deletedPages.where((page) {
      final daysInBin = now.difference(page.deletedAt).inDays;
      return daysInBin > retentionDays;
    }).toList();

    if (expiredPages.isNotEmpty) {
      print('🗑️ Found ${expiredPages.length} expired pages to remove permanently');
      for (final page in expiredPages) {
        _deletedPages.remove(page);
        print('🗑️ Permanently removed page: ${page.page.title}');
      }
      hasRemovedItems = true;
    }

    // Check diaries
    final expiredDiaries = _deletedDiaries.where((diary) {
      final daysInBin = now.difference(diary.deletedAt).inDays;
      return daysInBin > retentionDays;
    }).toList();

    if (expiredDiaries.isNotEmpty) {
      print('🗑️ Found ${expiredDiaries.length} expired diaries to remove permanently');
      for (final diary in expiredDiaries) {
        _deletedDiaries.remove(diary);
        print('🗑️ Permanently removed diary: ${diary.diary.title}');
      }
      hasRemovedItems = true;
    }

    // Check goals
    final expiredGoals = _deletedGoals.where((goal) {
      final daysInBin = now.difference(goal.deletedAt).inDays;
      return daysInBin > retentionDays;
    }).toList();

    if (expiredGoals.isNotEmpty) {
      print('🗑️ Found ${expiredGoals.length} expired goals to remove permanently');
      for (final goal in expiredGoals) {
        _deletedGoals.remove(goal);
        print('🗑️ Permanently removed goal: ${goal.goal.title}');
      }
      hasRemovedItems = true;
    }

    // Save changes if any items were removed
    if (hasRemovedItems) {
      await _saveDeletedItems();
      notifyListeners();
      print('✅ Expired items removed and changes saved');
    } else {
      print('✅ No expired items found');
    }
  }
}

class BinPage extends StatefulWidget {
  const BinPage({super.key});

  @override
  State<BinPage> createState() => _BinPageState();
}

class _BinPageState extends State<BinPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BinProvider _binProvider;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentUser();
  }

  // Get the current user ID and refresh when it changes
  Future<void> _getCurrentUser() async {
    final userId = await UserService.getCurrentUserId();
    if (mounted && userId != _currentUserId) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the shared BinProvider instance
    _binProvider = Provider.of<BinProvider>(context, listen: false);

    // Force a reload of deleted items when the bin page is opened
    _binProvider._loadDeletedItems().then((_) {
      // Check for expired items using the daily cleanup method
      _binProvider._checkDailyCleanup().then((_) {
        if (mounted) {
          setState(() {}); // Refresh the UI
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Bin',
      onItemSelected: (String page) {
        // Navigation logic is handled by CustomScaffold
      },
      body: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF255DE1),
          automaticallyImplyLeading: false, // Remove back arrow
          centerTitle: true,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 28, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Bin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.black87,
                tabs: const [
                  Tab(text: 'Pages'),
                  Tab(text: 'Diaries'),
                  Tab(text: 'Goals'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Pages Tab
            _buildPagesTab(),
            // Diaries Tab
            _buildDiariesTab(),
            // Goals Tab
            _buildGoalsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagesTab() {
    return Consumer<BinProvider>(
      builder: (context, binProvider, child) {
        if (binProvider.deletedPages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(15),
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
                    child: Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Color(0xFF255DE1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No deleted pages",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: binProvider.deletedPages.length,
          itemBuilder: (context, index) {
            final deletedPage = binProvider.deletedPages[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(deletedPage.page.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deleted on: ${_formatDate(deletedPage.deletedAt)}'),
                    Text(
                      _getAutoDeleteText(deletedPage.deletedAt),
                      style: TextStyle(
                        color: _getAutoDeleteColor(deletedPage.deletedAt),
                        fontWeight: _isNearExpiration(deletedPage.deletedAt) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.blue),
                      onPressed: () async {
                        try {
                          await binProvider.restorePage(deletedPage);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Page restored successfully')),
                            );
                            // Refresh pages in the provider
                            Provider.of<PagesProvider>(context, listen: false).fetchPages();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error restoring page: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                          context,
                          'page',
                          () {
                            binProvider.permanentlyDeletePage(deletedPage);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Page permanently deleted')),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDiariesTab() {
    return Consumer<BinProvider>(
      builder: (context, binProvider, child) {
        if (binProvider.deletedDiaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(15),
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
                    child: Icon(
                      Icons.menu_book,
                      size: 48,
                      color: Color(0xFF255DE1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No deleted diaries",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: binProvider.deletedDiaries.length,
          itemBuilder: (context, index) {
            final deletedDiary = binProvider.deletedDiaries[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(deletedDiary.diary.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deleted on: ${_formatDate(deletedDiary.deletedAt)}'),
                    Text(
                      _getAutoDeleteText(deletedDiary.deletedAt),
                      style: TextStyle(
                        color: _getAutoDeleteColor(deletedDiary.deletedAt),
                        fontWeight: _isNearExpiration(deletedDiary.deletedAt) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.blue),
                      onPressed: () async {
                        try {
                          await binProvider.restoreDiary(deletedDiary);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Diary restored successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error restoring diary: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                          context,
                          'diary',
                          () {
                            binProvider.permanentlyDeleteDiary(deletedDiary);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Diary permanently deleted')),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalsTab() {
    return Consumer<BinProvider>(
      builder: (context, binProvider, child) {
        if (binProvider.deletedGoals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(15),
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
                    child: Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: Color(0xFF255DE1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No deleted goals",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: binProvider.deletedGoals.length,
          itemBuilder: (context, index) {
            final deletedGoal = binProvider.deletedGoals[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(deletedGoal.goal.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deleted on: ${_formatDate(deletedGoal.deletedAt)}'),
                    Text(
                      _getAutoDeleteText(deletedGoal.deletedAt),
                      style: TextStyle(
                        color: _getAutoDeleteColor(deletedGoal.deletedAt),
                        fontWeight: _isNearExpiration(deletedGoal.deletedAt) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.blue),
                      onPressed: () async {
                        try {
                          await binProvider.restoreGoal(deletedGoal);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Goal restored successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error restoring goal: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                          context,
                          'goal',
                          () {
                            binProvider.permanentlyDeleteGoal(deletedGoal);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Goal permanently deleted')),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String itemType, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete $itemType'),
          content: Text('Are you sure you want to permanently delete this $itemType? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete Permanently',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Calculate remaining days before auto-deletion
  int _getRemainingDays(DateTime deletedAt) {
    final now = DateTime.now();
    final daysInBin = now.difference(deletedAt).inDays;
    final remainingDays = BinProvider.retentionDays - daysInBin;
    return remainingDays > 0 ? remainingDays : 0;
  }

  // Check if an item is near expiration (less than 7 days remaining)
  bool _isNearExpiration(DateTime deletedAt) {
    final remainingDays = _getRemainingDays(deletedAt);
    return remainingDays <= 7 && remainingDays > 0;
  }

  // Get the auto-delete text based on remaining days
  String _getAutoDeleteText(DateTime deletedAt) {
    final remainingDays = _getRemainingDays(deletedAt);

    if (remainingDays == 0) {
      return 'Will be deleted today';
    } else if (remainingDays == 1) {
      return 'Will be deleted tomorrow';
    } else {
      return 'Auto-delete in: $remainingDays days';
    }
  }

  // Get the color for the auto-delete text based on remaining days
  Color _getAutoDeleteColor(DateTime deletedAt) {
    final remainingDays = _getRemainingDays(deletedAt);

    if (remainingDays <= 3) {
      return Colors.red; // Critical - 3 days or less
    } else if (remainingDays <= 7) {
      return Colors.orange; // Warning - 7 days or less
    } else {
      return Colors.grey[600]!; // Normal - more than 7 days
    }
  }
}