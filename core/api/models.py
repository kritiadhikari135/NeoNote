

# from django.db import models
# from accounts.models import CustomUser  # Import the custom user model

# class doc(models.Model):
#     title = models.CharField(max_length=200)
#     content = models.TextField(blank=True)
#     owner = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=True, blank=True)  # Link to CustomUser
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)

#     def __str__(self):
#         return self.title

from django.db import models
from accounts.models import CustomUser  # Import the custom user model

class Doc(models.Model):
    title = models.CharField(max_length=200)
    # Use JSONField to store the Delta JSON data from Flutter Quill.
    content = models.JSONField(blank=True, null=True)
    owner = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=True, blank=True)  # Link to CustomUser
    parent = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='subpages')  # Self-reference for parent-child relationship
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title


