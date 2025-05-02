from django.db import models
from django.conf import settings
from work.models import Project # Import Project from the work app
from accounts.models import CustomUser # Import CustomUser

class ProjectTask(models.Model):
    """
    Represents a task specifically associated with a Project.
    """
    

    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ]

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='tasks')
    title = models.CharField(max_length=255)
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    due_date = models.DateField(null=True, blank=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='created_project_tasks', on_delete=models.SET_NULL, null=True)
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name='assigned_project_tasks',
        on_delete=models.SET_NULL,
        null=True,
        blank=True # Allow tasks to be unassigned initially
    )
    date_created = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} (Project: {self.project.name})"

    class Meta:
        ordering = ['-date_created']