from django.db import migrations

class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0002_emailotp'),
    ]

    operations = [
        # This migration acknowledges that is_active and is_staff fields
        # already exist in both the model and database
    ]
