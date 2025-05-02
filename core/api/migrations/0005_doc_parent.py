# Generated manually

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0004_alter_doc_content'),
    ]

    operations = [
        migrations.AddField(
            model_name='doc',
            name='parent',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='subpages', to='api.doc'),
        ),
    ]
