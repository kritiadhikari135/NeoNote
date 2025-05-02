from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('goals', '0001_initial'),
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
