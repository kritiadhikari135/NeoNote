

# from django.db import models
# from accounts.models import CustomUser
# from django.utils import timezone

# class Goal(models.Model):
#     title = models.CharField(max_length=255)
#     start_date = models.DateField()
#     completion_date = models.DateField()
#     is_completed = models.BooleanField(default=False)
#     completion_time = models.DateTimeField(null=True, blank=True)
#     user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='goals')  # Goal owner
#     created_by = models.CharField(max_length=100, default='system')
#     created_at = models.DateTimeField(default=timezone.now)  # Default value added here
#     last_modified_by = models.CharField(max_length=100, null=True, blank=True)
#     last_modified_at = models.DateTimeField(auto_now=True)

#     def __str__(self):
#         return self.title

#     def completion_percentage(self):
#         tasks = self.tasks.all()
#         if not tasks:
#             return 0
#         completed_tasks = tasks.filter(status='completed').count()
#         total_tasks = tasks.count()
#         return (completed_tasks / total_tasks) * 100

# class Task(models.Model):
#     STATUS_CHOICES = [
#         ('pending', 'Pending'),
#         ('in_progress', 'In Progress'),
#         ('on_hold', 'On Hold'),
#         ('cancelled', 'Cancelled'),
#         ('completed', 'Completed'),
#     ]

#     PRIORITY_CHOICES = [
#         ('low', 'Low'),
#         ('medium', 'Medium'),
#         ('high', 'High'),
#     ]

#     user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='goal_tasks')  # Task owner
#     title = models.CharField(max_length=255)  # Task name
#     status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='pending')  # Task status
#     priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')  # Task priority
#     due_date = models.DateField(null=True, blank=True)  # Optional due date
#     date_created = models.DateTimeField(auto_now_add=True)  # Auto-created timestamp
#     goal = models.ForeignKey(Goal, related_name='tasks', on_delete=models.CASCADE, null=True, blank=True)  # Related goal
#     created_by = models.CharField(max_length=100, default='system')
#     created_at = models.DateTimeField(default=timezone.now)  # Default value added here
#     last_modified_by = models.CharField(max_length=100, null=True, blank=True)
#     last_modified_at = models.DateTimeField(auto_now=True)

#     def __str__(self):
#         return self.title


from django.db import models
from accounts.models import CustomUser
from django.utils import timezone

class Goal(models.Model):
    title = models.CharField(max_length=255)
    start_date = models.DateField()
    completion_date = models.DateField()
    is_completed = models.BooleanField(default=False)
    completion_time = models.DateTimeField(null=True, blank=True)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='goals')  # Goal owner
    created_by = models.CharField(max_length=100, default='system')
    created_at = models.DateTimeField(default=timezone.now)  # Default value added here
    last_modified_by = models.CharField(max_length=100, null=True, blank=True)
    last_modified_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title

    def completion_percentage(self):
        tasks = self.tasks.all()
        if not tasks:
            return 0
        completed_tasks = tasks.filter(status='completed').count()
        total_tasks = tasks.count()
        return (completed_tasks / total_tasks) * 100

    def update_completion_status(self):
        self.is_completed = self.completion_percentage() == 100
        if self.is_completed:
            self.completion_time = timezone.now()
        self.save(update_fields=['is_completed', 'completion_time'])

class Task(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('on_hold', 'On Hold'),
        ('cancelled', 'Cancelled'),
        ('completed', 'Completed'),
    ]

    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ]

    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='goal_tasks')
    title = models.CharField(max_length=255)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='pending')
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    due_date = models.DateField(null=True, blank=True)
    date_created = models.DateTimeField(auto_now_add=True)
    goal = models.ForeignKey(Goal, related_name='tasks', on_delete=models.CASCADE, null=True, blank=True)
    created_by = models.CharField(max_length=100, default='system')
  


    def __str__(self):
        return self.title