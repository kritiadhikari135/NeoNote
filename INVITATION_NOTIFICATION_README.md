# Project Re-invitation Notification Feature

## Overview

This feature enhances the project invitation system to handle the case where a user who previously left a project is invited again. Instead of creating a new invitation notification, the system will update the previous invitation and override the notification in the user's inbox.

## Problem Solved

Previously, when:
1. User A sent a project invitation to User B
2. User B accepted the invitation
3. User B later left the project
4. User A sent another invitation to User B for the same project

The system would create a new invitation notification, leading to multiple notifications for the same project. This implementation ensures that only the most recent invitation notification is displayed in User B's inbox.

## Changes Made

1. **Enhanced TeamInvitation Model**
   - Modified the `save` method to detect and update existing invitations
   - Added logic to handle re-invitations after a user has left a project

2. **New Notification Type**
   - Added a new notification type `project_invitation` specifically for project invitations
   - This allows better tracking and management of invitation notifications

3. **Specialized Notification Creation Method**
   - Added `create_project_invitation_notification` method to the Notification model
   - This method handles cleaning up old notifications and creating appropriate new ones
   - Supports both new invitations and re-invitations with different messaging

4. **Updated Invitation Process**
   - Modified the `invite_member` method to detect when a user is being re-invited
   - Added logic to update existing invitations instead of creating new ones
   - Improved notification management for cleaner user experience

## Technical Implementation

### TeamInvitation Model

The `save` method now:
- Checks for existing invitations for the same project and recipient
- Updates existing invitations instead of creating new ones when appropriate
- Handles the case where a user previously left the project

### Notification Model

The new `create_project_invitation_notification` method:
- Deletes any existing project invitation notifications for the same project and recipient
- Also deletes any accepted/rejected invitation notifications for the same project
- Creates a new notification with appropriate messaging based on whether it's a re-invitation
- Uses a dedicated notification type for better tracking

### ProjectViewSet

The `invite_member` method now:
- Checks for any existing invitations (not just pending ones)
- Updates existing invitations instead of creating new ones when appropriate
- Uses the specialized notification creation method for better notification management

## User Experience

With this feature:
1. Users will see only the most recent invitation notification in their inbox
2. Re-invitations will be clearly marked as such ("invited you to join project X again")
3. The notification system is cleaner and more intuitive
4. Users won't be confused by multiple invitations for the same project

## Testing

To test this feature:
1. User A creates a project and invites User B
2. User B accepts the invitation
3. User B leaves the project
4. User A invites User B again
5. Verify that User B sees only one invitation notification in their inbox
6. Verify that the notification indicates it's a re-invitation
