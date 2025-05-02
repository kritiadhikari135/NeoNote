from django.db import models
from django.utils import timezone
from accounts.models import CustomUser
from goals.models import Goal

class Notification(models.Model):
    """
    Model for storing user notifications, particularly for goal reminders and task reminders.
    """
    NOTIFICATION_TYPES = [
        ('goal_reminder', 'Goal Reminder'),
        ('task_due', 'Task Due'),
        ('system', 'System Notification'),
        ('invitation_accepted', 'Invitation Accepted'),
        ('invitation_rejected', 'Invitation Rejected'),
        ('project_invitation', 'Project Invitation'),
    ]

    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=255)
    message = models.TextField()
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    created_at = models.DateTimeField(default=timezone.now)
    due_date_time = models.DateTimeField(null=True, blank=True)
    is_read = models.BooleanField(default=False)
    source_id = models.IntegerField(null=True, blank=True)  # ID of the related item (goal, task, etc.)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} - {self.user.email}"

    @property
    def is_past_due(self):
        """Check if the notification is past due"""
        if self.due_date_time:
            return self.due_date_time < timezone.now()
        return False

    @classmethod
    def create_goal_reminder(cls, goal):
        """Create a notification for a goal reminder"""
        if not goal.has_reminder or not goal.reminder_date_time:
            return None

        # Check if a notification for this goal already exists
        existing = cls.objects.filter(
            user=goal.user,
            notification_type='goal_reminder',
            source_id=goal.id
        ).first()

        if existing:
            # Update existing notification
            existing.title = f"Goal Reminder: {goal.title}"
            existing.message = f"Reminder for your goal: {goal.title}"
            existing.due_date_time = goal.reminder_date_time
            existing.is_read = False
            existing.save()
            return existing
        else:
            # Create new notification
            return cls.objects.create(
                user=goal.user,
                title=f"Goal Reminder: {goal.title}",
                message=f"Reminder for your goal: {goal.title}",
                notification_type='goal_reminder',
                due_date_time=goal.reminder_date_time,
                source_id=goal.id
            )

    @classmethod
    def remove_goal_reminder(cls, goal_id):
        """Remove notifications for a goal"""
        cls.objects.filter(
            notification_type='goal_reminder',
            source_id=goal_id
        ).delete()

    @classmethod
    def create_task_reminder(cls, task):
        """Create a notification for a task reminder"""
        # Import Task models here to avoid circular import
        try:
            from task.models import Task as IndependentTask
            from goals.models import Task as GoalTask

            print(f"Creating task reminder for task ID: {task.id}, title: {task.title}")

            # Check if task has the required attributes
            if not hasattr(task, 'has_reminder') or not hasattr(task, 'reminder_date_time'):
                print(f"Task {task.id} missing required attributes")
                return None

            # Check if task has reminder enabled
            if not task.has_reminder or not task.reminder_date_time:
                print(f"Task {task.id} has no reminder or reminder_date_time is None")
                return None

            print(f"Task {task.id} has reminder: {task.has_reminder}, time: {task.reminder_date_time}")

            # Check if task has user attribute
            if not hasattr(task, 'user'):
                print(f"Task {task.id} has no user attribute")
                return None

            print(f"Task {task.id} has user: {task.user}")

            # Check if a notification for this task already exists
            existing = cls.objects.filter(
                user=task.user,
                notification_type='task_due',
                source_id=task.id
            ).first()

            # Check if this is a goal task (has goal attribute)
            goal_title = None
            if hasattr(task, 'goal') and task.goal:
                try:
                    goal_title = task.goal.title
                    print(f"Task {task.id} belongs to goal: {goal_title}")
                except Exception as e:
                    print(f"Error getting goal title: {e}")

            # Create appropriate message based on whether it's a goal task
            title = f"Task Reminder: {task.title}"
            if isinstance(task, GoalTask) and goal_title:
                message = f"Reminder for your goal task: {task.title} (Goal: {goal_title})"
                title = f"Goal Task Reminder: {task.title}"
            else:
                message = f"Reminder for your task: {task.title}"

            if existing:
                # Update existing notification
                print(f"Updating existing notification for task {task.id}")
                existing.title = title
                existing.message = message
                existing.due_date_time = task.reminder_date_time
                existing.is_read = False
                existing.save()
                return existing
            else:
                # Create new notification
                print(f"Creating new notification for task {task.id}")
                return cls.objects.create(
                    user=task.user,
                    title=title,
                    message=message,
                    notification_type='task_due',
                    due_date_time=task.reminder_date_time,
                    source_id=task.id
                )
        except Exception as e:
            print(f"Error creating task reminder: {e}")
            return None

    @classmethod
    def remove_task_reminder(cls, task_id):
        """Remove notifications for a task"""
        cls.objects.filter(
            notification_type='task_due',
            source_id=task_id
        ).delete()

    @classmethod
    def create_invitation_notification(cls, invitation, action):
        """
        Create a notification for invitation responses

        Args:
            invitation: The TeamInvitation object
            action: Either 'accepted' or 'rejected'
        """
        if action not in ['accepted', 'rejected']:
            return None

        notification_type = f'invitation_{action}'

        # Create notification for the sender of the invitation
        title = f"Invitation {action.capitalize()}"
        message = f"{invitation.recipient.full_name} has {action} your invitation to join project '{invitation.project.name}'"

        # Check if a notification for this invitation already exists
        existing = cls.objects.filter(
            user=invitation.sender,
            notification_type=notification_type,
            source_id=invitation.id
        ).first()

        if existing:
            # Update existing notification
            existing.title = title
            existing.message = message
            existing.is_read = False
            existing.created_at = timezone.now()  # Update timestamp to bring to top
            existing.save()
            return existing
        else:
            # Create new notification
            return cls.objects.create(
                user=invitation.sender,
                title=title,
                message=message,
                notification_type=notification_type,
                source_id=invitation.id
            )

    @classmethod
    def create_project_invitation_notification(cls, invitation, is_reinvitation=False):
        """
        Create a notification for a new project invitation

        Args:
            invitation: The TeamInvitation object
            is_reinvitation: Whether this is a re-invitation after the user left
        """
        # Delete any existing project invitation notifications for this project and recipient
        from django.db.models import Q
        cls.objects.filter(
            Q(notification_type='project_invitation'),
            Q(user=invitation.recipient),
            Q(source_id=invitation.id)
        ).delete()

        # Also delete any accepted/rejected invitation notifications
        cls.objects.filter(
            Q(notification_type='invitation_accepted') |
            Q(notification_type='invitation_rejected'),
            Q(user=invitation.recipient),
            Q(message__contains=f"project '{invitation.project.name}'")
        ).delete()

        # Create the notification message based on whether this is a re-invitation
        if is_reinvitation:
            title = "Project Re-invitation"
            message = f"{invitation.sender.full_name} has invited you to join project '{invitation.project.name}' again"
        else:
            title = "New Project Invitation"
            message = f"{invitation.sender.full_name} has invited you to join project '{invitation.project.name}'"

        # Create the notification
        return cls.objects.create(
            user=invitation.recipient,
            title=title,
            message=message,
            notification_type='project_invitation',
            source_id=invitation.id
        )
