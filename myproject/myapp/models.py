from django.db import models
#  models here.
class Item(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()