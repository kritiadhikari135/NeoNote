# Generated manually

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('goals', '0005_remove_goal_has_reminder_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='goal',
            name='has_reminder',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='goal',
            name='reminder_date_time',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
