import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMIS Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Base URL for the API
  final String baseUrl = 'https://bjornmoggy.pythonanywhere.com/api';
  
  List<dynamic> records = [];
  bool isLoading = false;
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  
  int? editingId;

  @override
  void initState() {
    super.initState();
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.get(
        Uri.https('bjornmoggy.pythonanywhere.com', '/api/records/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        setState(() {
          records = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load records');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
       print('Fetch error: $e');
      _showSnackBar('Error fetching records: $e');
    }
  }

  Future<void> saveRecord() async {
    if (nameController.text.isEmpty) {
      _showSnackBar('Please enter a name');
      return;
    }

    final data = {
      'name': nameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
    };

    try {
      http.Response response;
      
      if (editingId == null) {
        // Create new record
        response = await http.post(
          Uri.parse('$baseUrl/records/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );
      } else {
        // Update existing record
        response = await http.put(
          Uri.parse('$baseUrl/records/$editingId/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearForm();
        fetchRecords();
        _showSnackBar(editingId == null ? 'Record created successfully' : 'Record updated successfully');
      } else {
        throw Exception('Failed to save record');
      }
    } catch (e) {
      print('Fetch error: $e');
      _showSnackBar('Error saving record: $e');
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/records/$id/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        fetchRecords();
        _showSnackBar('Record deleted successfully');
      } else {
        throw Exception('Failed to delete record');
      }
    } catch (e) {
      _showSnackBar('Error deleting record: $e');
    }
  }

  void _editRecord(Map<String, dynamic> record) {
    setState(() {
      editingId = record['id'];
      nameController.text = record['name'] ?? '';
      emailController.text = record['email'] ?? '';
      phoneController.text = record['phone'] ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      editingId = null;
      nameController.clear();
      emailController.clear();
      phoneController.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EMIS Records'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      editingId == null ? 'Add New Record' : 'Edit Record',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saveRecord,
                            child: Text(editingId == null ? 'Add Record' : 'Update Record'),
                          ),
                        ),
                        if (editingId != null) ...[
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _clearForm,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            child: Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Records List Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Records',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: fetchRecords,
                  child: Text('Refresh'),
                ),
              ],
            ),
            
            SizedBox(height: 10),
            
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : records.isEmpty
                      ? Center(
                          child: Text(
                            'No records found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(record['name'] ?? 'No Name'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (record['email'] != null && record['email'].isNotEmpty)
                                      Text('Email: ${record['email']}'),
                                    if (record['phone'] != null && record['phone'].isNotEmpty)
                                      Text('Phone: ${record['phone']}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editRecord(record),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Confirm Delete'),
                                              content: Text('Are you sure you want to delete this record?'),
                                              actions: [
                                                TextButton(
                                                  child: Text('Cancel'),
                                                  onPressed: () => Navigator.of(context).pop(),
                                                ),
                                                TextButton(
                                                  child: Text('Delete'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    deleteRecord(record['id']);
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}