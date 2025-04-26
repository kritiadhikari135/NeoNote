from django.db import migrations

class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0002_emailotp'),
    ]

    operations = [
        # This migration acknowledges the updated model structure
        # No actual database changes needed as the fields already exist
    ]
