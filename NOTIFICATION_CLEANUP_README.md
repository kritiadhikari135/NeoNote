# Enhanced Notification Cleanup Feature

## Overview

This feature automatically deletes related notifications when a user leaves or deletes a project. This ensures that users don't receive notifications for projects they're no longer part of, keeping the notification system clean and relevant.

## Changes Made

1. **Project Deletion**
   - Added comprehensive code to delete all notifications related to a project when it's deleted
   - This affects all users who were part of the project
   - Implemented in the `destroy` method of `ProjectViewSet`

2. **Leaving a Project**
   - Enhanced notification cleanup when a user leaves a project
   - Now deletes both direct project notifications and invitation-related notifications
   - Implemented in the `leave_project` method of `ProjectViewSet`

3. **Invitation Deletion**
   - Added notification cleanup when an invitation is deleted
   - Ensures that invitation acceptance/rejection notifications are removed
   - Implemented in the `delete_invitation` method of `TeamInvitationViewSet`

4. **Debugging Tools**
   - Added a Django management command `debug_notifications` to help diagnose notification issues
   - Created a test script to verify notification cleanup functionality

## Technical Implementation

### Project Deletion

When a project is deleted, the system now uses three different methods to find and delete related notifications:

1. **Direct Source ID Matching**
   - Deletes notifications where `source_id` matches the project ID

2. **Project Name in Message**
   - Deletes invitation notifications that mention the project name in the message text
   - Uses `message__contains` to find these notifications

3. **Related Invitations**
   - Finds all invitations related to the project
   - Deletes notifications where `source_id` matches any of these invitation IDs

### Leaving a Project

When a user leaves a project, the system now:

1. **Direct Notifications**
   - Deletes notifications for the user where `source_id` matches the project ID

2. **Invitation Notifications by Message**
   - Deletes invitation notifications for the user that mention the project name

3. **Invitation Notifications by Source**
   - Finds all invitations related to the project where the user is sender or recipient
   - Deletes notifications where `source_id` matches any of these invitation IDs

### Invitation Deletion

When an invitation is deleted, the system now:

1. **Source ID Matching**
   - Deletes notifications where `source_id` matches the invitation ID

2. **Project Name Matching**
   - Also deletes notifications that mention the project name
   - Limits to notifications for the sender and recipient of the invitation

## Benefits

1. **Comprehensive Cleanup**
   - Multiple strategies ensure all related notifications are found and deleted
   - Handles both direct and indirect relationships between notifications and projects

2. **Improved Reliability**
   - More robust approach to finding related notifications
   - Better handling of edge cases and different notification types

3. **Detailed Logging**
   - Enhanced logging shows exactly how many notifications were deleted by each method
   - Makes it easier to diagnose and troubleshoot issues

## Testing and Verification

To test the notification cleanup functionality:

1. Run the `test_notification_cleanup.bat` script
2. Use the Django management command: `python manage.py debug_notifications`
3. This will show all notifications in the system before and after cleanup operations

## Error Handling

All notification deletion operations are wrapped in try-except blocks to ensure that:
1. If notification deletion fails, the main operation (project deletion, leaving project, etc.) still proceeds
2. Errors are properly logged for debugging
3. The user experience is not disrupted by background cleanup failures
