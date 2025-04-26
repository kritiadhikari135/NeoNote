from django.db import migrations

class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0002_emailotp'),
    ]

    operations = [
        # This is a dummy migration that acknowledges the fields already exist
        # in both the model and the database
    ]
