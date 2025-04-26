from django.db import models
from django.conf import settings
from accounts.models import CustomUser


class Diary(models.Model):
    MOOD_CHOICES = [
        ('Happy', 'Happy'),
        ('Sad', 'Sad'),
        ('Excited', 'Excited'),
        ('Tired', 'Tired'),
        ('Anxious', 'Anxious'),
    ]

    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='diaries')  # Goal owner
    title = models.CharField(max_length=255)
    content = models.TextField()
    date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    mood = models.CharField(max_length=50, choices=MOOD_CHOICES, blank=True, null=True)
    # background_color = models.BigIntegerField(default=0xFFFFFF)
    # text_color = models.BigIntegerField(default=0x000000)
    background_color = models.BigIntegerField(default=0xFFFFFF, null=False, blank=False)  # Ensure non-null
    text_color = models.BigIntegerField(default=0x000000, null=False, blank=False)  # Ensure non-null
    template = models.CharField(max_length=50, default='Default')

    class Meta:
        ordering = ['-date']

    def __str__(self):
        return f"{self.title} - {self.date}"


class DiaryImage(models.Model):
    diary = models.ForeignKey(Diary, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='diary_images/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Image for {self.diary.title} uploaded on {self.uploaded_at}"