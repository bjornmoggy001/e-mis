from django.contrib import admin
from django.urls import path, include
from django.http import HttpResponse

def my_home(request):
    return HttpResponse("Welcome to the API homepage")

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('myproject.urls')),  # Replace 'your_app_name' with actual app name
    path('', my_home),  # This shows "Welcome to the API homepage"
]