# Generated by Django 2.0.6 on 2018-06-19 09:21

from django.db import migrations

import safe_relay_service.safe.models


class Migration(migrations.Migration):

    dependencies = [
        ('safe', '0004_auto_20180614_1548'),
    ]

    operations = [
        migrations.AddField(
            model_name='safecontract',
            name='master_copy',
            field=safe_relay_service.safe.models.EthereumAddressField(default='0x2aaB3573eCFD2950a30B75B6f3651b84F4e130da'),
            preserve_default=False,
        ),
    ]
