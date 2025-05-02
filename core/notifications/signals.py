from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from goals.models import Goal, Task as GoalTask
from task.models import Task as IndependentTask
from .models import Notification

@receiver(post_save, sender=Goal)
def create_or_update_goal_notification(sender, instance, created, **kwargs):
    """
    Create or update a notification when a goal is created or updated with a reminder.
    """
    if hasattr(instance, 'has_reminder') and instance.has_reminder and instance.reminder_date_time:
        Notification.create_goal_reminder(instance)
    elif hasattr(instance, 'has_reminder') and not instance.has_reminder:
        # If reminder was removed, remove the notification
        Notification.remove_goal_reminder(instance.id)

@receiver(post_delete, sender=Goal)
def delete_goal_notification(sender, instance, **kwargs):
    """
    Delete notifications when a goal is deleted.
    """
    Notification.remove_goal_reminder(instance.id)

@receiver(post_save, sender=GoalTask)
def create_or_update_goal_task_notification(sender, instance, created, **kwargs):
    """
    Create or update a notification when a goal task is created or updated with a reminder.
    """
    print(f"Signal received for Goal Task {instance.id} - {instance.title}")

    # Check if the Task model has the required attributes
    has_reminder_attr = hasattr(instance, 'has_reminder')
    has_reminder_time_attr = hasattr(instance, 'reminder_date_time')

    print(f"Goal Task has 'has_reminder' attribute: {has_reminder_attr}")
    print(f"Goal Task has 'reminder_date_time' attribute: {has_reminder_time_attr}")

    # Only proceed if the task has both required attributes
    if has_reminder_attr and has_reminder_time_attr:
        print(f"Goal Task has reminder: {instance.has_reminder}, Reminder time: {instance.reminder_date_time}")

        if instance.has_reminder and instance.reminder_date_time:
            print(f"Creating notification for goal task {instance.id}")
            Notification.create_task_reminder(instance)
        elif not instance.has_reminder or instance.status == 'completed':
            print(f"Removing notification for goal task {instance.id}")
            Notification.remove_task_reminder(instance.id)
    else:
        print(f"Goal Task {instance.id} does not have reminder attributes, skipping notification handling")

@receiver(post_save, sender=IndependentTask)
def create_or_update_independent_task_notification(sender, instance, created, **kwargs):
    """
    Create or update a notification when an independent task is created or updated with a reminder.
    """
    print(f"Signal received for Independent Task {instance.id} - {instance.title}")

    # Check if the Task model has the required attributes
    has_reminder_attr = hasattr(instance, 'has_reminder')
    has_reminder_time_attr = hasattr(instance, 'reminder_date_time')

    print(f"Independent Task has 'has_reminder' attribute: {has_reminder_attr}")
    print(f"Independent Task has 'reminder_date_time' attribute: {has_reminder_time_attr}")

    # Only proceed if the task has both required attributes
    if has_reminder_attr and has_reminder_time_attr:
        print(f"Independent Task has reminder: {instance.has_reminder}, Reminder time: {instance.reminder_date_time}")

        if instance.has_reminder and instance.reminder_date_time:
            print(f"Creating notification for independent task {instance.id}")
            Notification.create_task_reminder(instance)
        elif not instance.has_reminder or instance.status == 'completed':
            print(f"Removing notification for independent task {instance.id}")
            Notification.remove_task_reminder(instance.id)
    else:
        print(f"Independent Task {instance.id} does not have reminder attributes, skipping notification handling")

@receiver(post_delete, sender=GoalTask)
def delete_goal_task_notification(sender, instance, **kwargs):
    """
    Delete notifications when a goal task is deleted.
    """
    print(f"Deleting notifications for goal task {instance.id}")
    Notification.remove_task_reminder(instance.id)

@receiver(post_delete, sender=IndependentTask)
def delete_independent_task_notification(sender, instance, **kwargs):
    """
    Delete notifications when an independent task is deleted.
    """
    print(f"Deleting notifications for independent task {instance.id}")
    Notification.remove_task_reminder(instance.id)
