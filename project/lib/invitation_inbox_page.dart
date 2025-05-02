import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold_workspace.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:project/services/local_storage.dart';
import 'package:project/services/notification_service.dart';
import 'package:project/utils/platform_helper.dart';

class InvitationInboxPage extends StatefulWidget {
  const InvitationInboxPage({super.key});

  @override
  State<InvitationInboxPage> createState() => _InvitationInboxPageState();
}

class _InvitationInboxPageState extends State<InvitationInboxPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> invitations = [];
  bool isLoading = true;
  String error = '';
  String? currentUserId;
  Timer? _refreshTimer;
  late TabController _tabController;
  int _unreadResponses = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();

    // Listen for tab changes to mark notifications as read when viewing sent tab
    _tabController.addListener(_handleTabChange);

    // Set up a timer to refresh invitations every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        fetchInvitations();
        _checkUnreadResponses();
      }
    });
  }

  void _handleTabChange() {
    // If the user switches to the "Sent" tab (index 1), mark responses as read
    if (_tabController.index == 1 && _unreadResponses > 0) {
      // Only mark invitation notifications as read
      NotificationService.markInvitationResponsesAsRead().then((_) {
        // After marking as read, refresh the unread count
        _checkUnreadResponses();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      // First check if we have a valid token
      final token = await LocalStorage.getToken();
      if (token == null) {
        setState(() {
          error = 'Not authenticated';
          isLoading = false;
        });
        return;
      }

      // Get the current user ID
      final userId = await LocalStorage.getUserId();

      if (userId == null) {
        // Try to get user profile to get the user ID
        try {
          final response = await http.get(
            Uri.parse('http://127.0.0.1:8000/api/accounts/profile/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': '*',
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data.containsKey('id')) {
              // Save the user ID for future use
              await LocalStorage.saveUserId(data['id'].toString());
              setState(() {
                currentUserId = data['id'].toString();
              });
            } else {
              setState(() {
                error = 'User ID not found in profile';
                isLoading = false;
              });
              return;
            }
          } else {
            setState(() {
              error = 'Not authenticated';
              isLoading = false;
            });
            return;
          }
        } catch (e) {
          setState(() {
            error = 'Error fetching user profile: $e';
            isLoading = false;
          });
          return;
        }
      } else {
        setState(() {
          currentUserId = userId;
        });
      }

      await fetchInvitations();
      _checkUnreadResponses();
    } catch (e) {
      setState(() {
        error = 'Error initializing: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _checkUnreadResponses() async {
    try {
      final count = await NotificationService.getUnreadInvitationResponseCount();
      if (mounted) {
        setState(() {
          _unreadResponses = count;
        });
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> fetchInvitations() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        setState(() {
          error = 'Not authenticated';
          isLoading = false;
        });
        return;
      }

      // Create headers with all necessary CORS headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': '*',
      };

      // Use direct URL with 127.0.0.1 for web to avoid CORS issues
      String baseUrl = 'http://127.0.0.1:8000';

      // Build the URL with parameters
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '$baseUrl/api/work/invitations/?include_sent=true&t=$timestamp';

      print('📡 Fetching invitations directly...');

      // Make a direct request
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (mounted) {
          setState(() {
            invitations = data.map((invitation) {
              // Check if this is a newly responded invitation
              bool isNew = false;
              if (invitation['status'] != 'pending' &&
                  invitation['responded_at'] != null &&
                  currentUserId == invitation['sender']['id'].toString()) {
                // Calculate if response is within the last 24 hours
                final respondedAt = DateTime.parse(invitation['responded_at']);
                final now = DateTime.now();
                final difference = now.difference(respondedAt);
                isNew = difference.inHours < 24;
              }

              return {
                'id': invitation['id'],
                'project': invitation['project'],
                'sender': invitation['sender'],
                'recipient': invitation['recipient'],
                'status': invitation['status'],
                'created_at': invitation['created_at'],
                'responded_at': invitation['responded_at'],
                'is_new_response': isNew, // Add flag for new responses
              };
            }).toList();
            isLoading = false;
            error = ''; // Clear any previous errors
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Authentication error
        if (mounted) {
          setState(() {
            error = 'Not authenticated';
            isLoading = false;
            invitations = []; // Clear invitations
          });

          // Clear invalid token
          await LocalStorage.clearToken();
        }
      } else {
        if (mounted) {
          setState(() {
            error = 'Failed to load invitations (Status: ${response.statusCode})';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Provide more detailed error message
          if (PlatformHelper.isWeb) {
            error = 'Error connecting to server: ${e.toString().substring(0, math.min(e.toString().length, 100))}\n\nThis may be due to CORS restrictions in the browser. Try using the desktop app instead.';
          } else {
            error = 'Error connecting to server: $e';
          }
          isLoading = false;
        });
      }
    }
  }

  Future<void> respondToInvitation(
    Map<String, dynamic> inv,
    String action,
  ) async {
    // Store a reference to the ScaffoldMessengerState before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final token = await LocalStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    try {
      // Create headers with all necessary CORS headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': '*',
      };

      // Build the URL
      final url = 'http://127.0.0.1:8000/api/work/invitations/${inv['id']}/respond/';

      // Make a direct request
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'action': action}),
      );

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      if (response.statusCode == 200) {
        final isSender = currentUserId == inv['sender']['id'].toString();
        final otherName = isSender
            ? inv['recipient']['full_name']
            : inv['sender']['full_name'];

        final verb = action == 'accept' ? 'accepted' : 'rejected';
        final snackBarText = isSender
            ? '$otherName $verb your invitation.'
            : 'You $verb the invitation from $otherName.';

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(snackBarText),
            backgroundColor:
                action == 'accept' ? Colors.green : Colors.red,
          ),
        );

        await fetchInvitations();
      } else {
        final errorData = json.decode(response.body);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorData['error'] ?? 'Failed to respond to invitation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  // Helper method to build status indicator
  Widget _buildStatusIndicator(String status, bool isNewResponse) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case 'accepted':
        backgroundColor = const Color(0xFFE8F5E9); // Light green
        textColor = Colors.green;
        icon = Icons.check_circle;
        text = 'Accepted';
        break;
      case 'rejected':
        backgroundColor = const Color(0xFFFFEBEE); // Light red
        textColor = Colors.red;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      default:
        backgroundColor = const Color(0xFFF5F5F5); // Light grey
        textColor = Colors.grey;
        icon = Icons.schedule;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: isNewResponse && status != 'pending'
            ? Border.all(color: Colors.amber, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Build a list of invitations filtered by sender/recipient
  Widget _buildInvitationsList(bool showSent) {
    // Filter invitations based on whether the current user is the sender
    final filteredInvitations = invitations.where((invitation) {
      final senderId = invitation['sender']['id'].toString();
      final recipientId = invitation['recipient']['id'].toString();
      final isCurrentUserSender = currentUserId == senderId;
      final isCurrentUserRecipient = currentUserId == recipientId;

      if (showSent) {
        // For "Sent" tab, show only invitations where the user is the sender
        return isCurrentUserSender;
      } else {
        // For "Received" tab, show only invitations where the user is the recipient
        return isCurrentUserRecipient;
      }
    }).toList();

    if (filteredInvitations.isEmpty) {
      return Center(
        child: Text(
          showSent ? 'No sent invitations' : 'No received invitations',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredInvitations.length,
      itemBuilder: (context, index) {
        final invitation = filteredInvitations[index];
        final project = invitation['project'];
        final sender = invitation['sender'];
        final status = invitation['status'];
        final recipient = invitation['recipient'];
        final respondedAt = invitation['responded_at'];
        final isCurrentUserSender = currentUserId == sender['id'].toString();
        final isNewResponse = invitation['is_new_response'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          // Add a subtle highlight for new responses
          color: isNewResponse ? const Color(0xFFFFFDE7) : null, // Light yellow background for new responses
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isNewResponse
              ? const BorderSide(color: Colors.amber, width: 2)
              : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            project['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status indicator
                          _buildStatusIndicator(status, isNewResponse),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (status == 'pending') ...[
                  Text(
                    isCurrentUserSender
                        ? 'To: ${recipient['full_name']}'
                        : 'From: ${sender['full_name']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project['description'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (isCurrentUserSender) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Waiting for response...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    isCurrentUserSender
                        ? 'To: ${recipient['full_name']}'
                        : 'From: ${sender['full_name']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final actionVerb = status == 'accepted' ? 'accepted' : 'rejected';

                      // Display message based on who sent the invitation
                      if (isCurrentUserSender) {
                        // User is the sender, show that recipient responded
                        return Row(
                          children: [
                            if (isNewResponse)
                              const Icon(Icons.notifications_active, color: Colors.amber, size: 16),
                            if (isNewResponse)
                              const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${recipient['full_name']} $actionVerb your invitation',
                                style: TextStyle(
                                  color: status == 'accepted' ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // User is the recipient, show their own action
                        return Text(
                          'You $actionVerb this invitation',
                          style: TextStyle(
                            color: status == 'accepted' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    },
                  ),
                  if (respondedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'on ${DateTime.parse(respondedAt).toLocal().toString().split('.')[0]}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                if (status == 'pending' && !isCurrentUserSender)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => respondToInvitation(
                          invitation,
                          'reject',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => respondToInvitation(
                          invitation,
                          'accept',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldWorkspace(
      selectedPage: 'Inbox',
      onItemSelected: (page) {},
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: const BoxDecoration(
              color: Color(0xFF255DE1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Text(
              'Inbox',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invitations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (error.isNotEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            error,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          if (error == 'Not authenticated')
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1877F2),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text('Go to Login'),
                            ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              tabs: [
                                const Tab(text: 'Received'),
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Sent'),
                                      if (_unreadResponses > 0) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.amber,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            _unreadResponses.toString(),
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              indicator: BoxDecoration(
                                color: const Color(0xFF255DE1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Received invitations tab
                                _buildInvitationsList(false),
                                // Sent invitations tab
                                _buildInvitationsList(true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
