from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('task', '0003_alter_task_user'),
    ]

    operations = [
        migrations.AddField(
            model_name='task',
            name='has_reminder',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='task',
            name='reminder_date_time',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
