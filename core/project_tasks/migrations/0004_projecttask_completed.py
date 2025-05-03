# Generated manually

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('project_tasks', '0003_tasksubmission'),
    ]

    operations = [
        migrations.AddField(
            model_name='projecttask',
            name='completed',
            field=models.BooleanField(default=False),
        ),
    ]
