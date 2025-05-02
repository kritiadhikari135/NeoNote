from django.core.management.base import BaseCommand
from notifications.models import Notification
from work.models import Project, TeamInvitation
from django.db.models import Q

class Command(BaseCommand):
    help = 'Debug notifications related to projects and invitations'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Debugging notifications...'))
        
        # Count all notifications
        total_notifications = Notification.objects.count()
        self.stdout.write(f"Total notifications in database: {total_notifications}")
        
        # Count invitation notifications
        invitation_notifications = Notification.objects.filter(
            Q(notification_type='invitation_accepted') | 
            Q(notification_type='invitation_rejected')
        ).count()
        self.stdout.write(f"Invitation notifications: {invitation_notifications}")
        
        # Get all projects
        projects = Project.objects.all()
        self.stdout.write(f"Total projects: {projects.count()}")
        
        # For each project, check related notifications
        for project in projects:
            project_notifications = Notification.objects.filter(
                source_id=project.id
            )
            self.stdout.write(f"Project {project.id} ({project.name}) has {project_notifications.count()} notifications")
            
            # Check if there are any notifications with project name in message
            project_name_notifications = Notification.objects.filter(
                message__contains=f"project '{project.name}'"
            )
            self.stdout.write(f"  - Notifications mentioning project name: {project_name_notifications.count()}")
            
            # List all these notifications
            for notification in project_name_notifications:
                self.stdout.write(f"    - {notification.notification_type}: {notification.message} (source_id: {notification.source_id})")
        
        # Get all invitations
        invitations = TeamInvitation.objects.all()
        self.stdout.write(f"Total invitations: {invitations.count()}")
        
        # For each invitation, check related notifications
        for invitation in invitations:
            invitation_notifications = Notification.objects.filter(
                source_id=invitation.id,
                Q(notification_type='invitation_accepted') | 
                Q(notification_type='invitation_rejected')
            )
            self.stdout.write(f"Invitation {invitation.id} has {invitation_notifications.count()} notifications")
            
        self.stdout.write(self.style.SUCCESS('Debugging complete!'))
